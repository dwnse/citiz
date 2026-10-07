extends Node
const Replication = preload("res://network/replication.gd")
var state_sequence := 0
var delta_frames := 0
## HTTP intentions and incremental SSE snapshots. Node owns all gameplay.
signal snapshot_received(state: Dictionary)
signal status_changed(message: String)
signal directory_received(worlds: Array)
signal world_created(world: String)
signal action_feedback(message: String, success: bool)

var host := "127.0.0.1"
var port := 3002
var profile := "agent1"
var cookie := ""
var player_id := ""
var world_id := ""
var creating_world := false
var seq := 0
var connected := false
var latest: Dictionary = {}
var identities: Dictionary = {}
var stream := HTTPClient.new()
var buffer := PackedByteArray()
var stream_requested := false
var streaming := false
var input_busy := false
var action_busy := false
var action_queue: Array[Dictionary] = []
var generation := 0
var last_frame_ms := 0
var profile_path := ""
var reconnect_target: Dictionary = {}
var reconnect_attempt := 0
var reconnect_at := 0
var pending_input: Dictionary = {}

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			profile = arg.trim_prefix("--profile=").validate_filename()
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
	profile_path = "user://identity_%s_%s.json" % [port, profile]
	if FileAccess.file_exists(profile_path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
		if saved is Dictionary:
			identities = saved

func request_json(path: String, body: Dictionary = {}, post := false) -> Dictionary:
	var request := HTTPRequest.new()
	add_child(request)
	request.timeout = 5.0
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not cookie.is_empty():
		headers.append("Cookie: " + cookie)
	var method := HTTPClient.METHOD_POST if post else HTTPClient.METHOD_GET
	var error := request.request("http://%s:%d%s" % [host, port, path], headers, method, JSON.stringify(body) if post else "")
	if error != OK:
		request.queue_free()
		return {"error": "No se pudo iniciar HTTP: %s" % error}
	var result: Array = await request.request_completed
	request.queue_free()
	var data = JSON.parse_string(result[3].get_string_from_utf8())
	if not data is Dictionary:
		return {"error": "Sin respuesta del servidor. Inicia node tools/start-godot.mjs."}
	data["_headers"] = result[2]
	data["_status"] = result[1]
	return data

func refresh_worlds() -> void:
	var protocol: Dictionary = await request_json("/api/protocol")
	if protocol.get("protocol", 0) != 1:
		status_changed.emit("Servidor no compatible o apagado. Inicia node tools/start-godot.mjs.")
		return
	if not "balanced-survival" in protocol.get("features",[]):
		directory_received.emit([])
		status_changed.emit("Servidor antiguo: cierra su consola con Ctrl+C, ejecuta node tools/start-godot.mjs y pulsa Actualizar partidas.")
		return
	var result: Dictionary = await request_json("/api/worlds")
	if result.has("error"):
		status_changed.emit(str(result.error))
	else:
		directory_received.emit(result.worlds)

func create_world() -> void:
	if creating_world: return
	creating_world=true
	var result: Dictionary = await request_json("/api/worlds", {}, true)
	if result.has("error"):
		status_changed.emit(str(result.error))
		creating_world=false
		return
	await refresh_worlds()
	world_created.emit(str(result.world.id))
	creating_world=false

func enter(selected_world: String, community: String, agent_name: String, retry := false) -> void:
	if not retry:
		disconnect_world()
		reconnect_target = {"world":selected_world,"community":community,"name":agent_name}
	else:
		close_transport()
	var ticket := generation
	var body := {"worldId": selected_world, "communityId": community, "name": agent_name}
	if identities.has(selected_world):
		body["key"] = identities[selected_world]
	elif not identities.is_empty():
		body["accountKey"]=identities.values()[0]
	status_changed.emit("Conectando…")
	var result: Dictionary = await request_json("/api/join", body, true)
	if ticket != generation:
		return
	if result.has("error"):
		if retry and int(result.get("_status",0)) not in [400,401,403,404,409]:
			fail_stream(str(result.error))
		else:
			reconnect_target.clear()
			status_changed.emit(str(result.error))
		return
	for header in result._headers:
		if str(header).to_lower().begins_with("set-cookie:"):
			cookie = str(header).substr(11).strip_edges().split(";")[0]
	player_id = result.id
	world_id = result.worldId
	seq = int(result.seq)
	identities[world_id] = result.key
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(identities))
	else:
		status_changed.emit("No se pudo guardar la identidad local; conserva este perfil abierto.")
	stream_requested = false
	streaming = true
	last_frame_ms = Time.get_ticks_msec()
	var error := stream.connect_to_host(host, port)
	if error != OK:
		fail_stream("No se pudo abrir el canal de estados.")

func disconnect_world() -> void:
	reconnect_target.clear()
	reconnect_attempt = 0
	reconnect_at = 0
	close_transport()

func close_transport() -> void:
	generation += 1
	stream.close()
	streaming = false
	connected = false
	cookie = ""
	buffer.clear()
	action_queue.clear()
	pending_input.clear()
	input_busy = false
	action_busy = false
	latest = {}
	state_sequence=0
	delta_frames=0

func fail_stream(message: String) -> void:
	close_transport()
	if reconnect_target.is_empty() or reconnect_attempt >= 5:
		reconnect_at = 0
		status_changed.emit(message + " No se pudo recuperar la conexión. Pulsa Reconectar o vuelve a la sala.")
		return
	var delay := mini(8, int(pow(2,reconnect_attempt)))
	reconnect_attempt += 1
	reconnect_at = Time.get_ticks_msec() + delay * 1000
	status_changed.emit("Conexión perdida · Reintentando en %d s (%d/5). Tus acciones pendientes se cancelaron." % [delay,reconnect_attempt])

func _process(_delta: float) -> void:
	if reconnect_at > 0 and Time.get_ticks_msec() >= reconnect_at:
		reconnect_at = 0
		enter(reconnect_target.world,reconnect_target.community,reconnect_target.name,true)
	if not streaming:
		return
	stream.poll()
	var state := stream.get_status()
	if state == HTTPClient.STATUS_CONNECTED and not stream_requested:
		var error := stream.request(HTTPClient.METHOD_GET, "/api/events?delta=1&worldId=" + world_id, PackedStringArray(["Cookie: " + cookie]))
		stream_requested = true
		if error != OK:
			fail_stream("Error al solicitar estados.")
	elif state == HTTPClient.STATUS_BODY:
		if stream.get_response_code() != 200:
			fail_stream("La sesión fue rechazada.")
			return
		# Bytes are retained until a full event arrives: UTF-8 can span HTTP chunks.
		for chunk_index in range(8):
			var chunk := stream.read_response_body_chunk()
			if chunk.is_empty():
				break
			buffer.append_array(chunk)
		consume_frames()
	elif state in [HTTPClient.STATUS_DISCONNECTED, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CONNECTION_ERROR]:
		fail_stream("Conexión interrumpida.")
	if streaming and Time.get_ticks_msec() - last_frame_ms > 5000:
		fail_stream("No llegan estados del servidor.")

func consume_frames() -> void:
	if buffer.size() > 2000000:
		fail_stream("Estado demasiado grande.")
		return
	var end := -1
	for i in range(buffer.size() - 1):
		if buffer[i] == 10 and buffer[i + 1] == 10:
			end = i
			break
	while end >= 0:
		var frame := buffer.slice(0, end).get_string_from_utf8()
		buffer = buffer.slice(end + 2)
		if frame.begins_with("event: session-replaced"):
			disconnect_world()
			status_changed.emit("Este perfil se abrió en otra conexión. Usa un perfil distinto para jugar con otra persona.")
			return
		if frame.begins_with("data: "):
			var parsed = JSON.parse_string(frame.substr(6))
			if parsed is Dictionary and parsed.has("wire"):
				var decoded: Dictionary = Replication.apply(latest,state_sequence,parsed)
				if decoded.has("error"):
					fail_stream(str(decoded.error))
					return
				if parsed.has("base"): delta_frames+=1
				state_sequence=decoded.sequence
				parsed=decoded.state
			if parsed is Dictionary and int(parsed.get("version", 0)) in [4, 5, 6]:
				latest = parsed
				if not connected:
					status_changed.emit("Conectado · Partida guardada automáticamente")
				reconnect_attempt = 0
				reconnect_at = 0
				connected = true
				last_frame_ms = Time.get_ticks_msec()
				snapshot_received.emit(latest)
		end = -1
		for i in range(buffer.size() - 1):
			if buffer[i] == 10 and buffer[i + 1] == 10:
				end = i
				break

func send_input(direction: Vector2, angle: float) -> void:
	if not connected:
		return
	pending_input = {"x": direction.x, "y": direction.y, "angle": angle, "worldId": world_id}
	flush_input()

func flush_input() -> void:
	if input_busy or pending_input.is_empty() or not connected:
		return
	input_busy = true
	var ticket := generation
	var body := pending_input
	pending_input = {}
	var result: Dictionary = await request_json("/api/input", body, true)
	if ticket != generation:
		return
	input_busy = false
	if result.get("_status", 0) == 401:
		fail_stream("La sesión terminó.")
		return
	if result.get("_status",0) == 429 and pending_input.is_empty():
		pending_input = body
	# Keep only the newest intention, including stop, while HTTP is in flight.
	if not pending_input.is_empty():
		input_busy = true
		await get_tree().create_timer(0.025).timeout
		if ticket == generation:
			input_busy = false
			flush_input()

func act(kind: String, extra: Dictionary = {}) -> void:
	if not connected or action_queue.size() >= 8:
		return
	var body := extra.duplicate()
	seq += 1
	body.merge({"type": kind, "seq": seq, "worldId": world_id}, true)
	action_queue.append(body)
	flush_actions()

func flush_actions() -> void:
	if action_busy or action_queue.is_empty() or not connected:
		return
	action_busy = true
	var ticket := generation
	var result: Dictionary = await request_json("/api/action", action_queue.pop_front(), true)
	if ticket != generation:
		return
	action_busy = false
	if result.get("_status",0) == 401:
		fail_stream("La sesión terminó.")
		return
	if ticket == generation:
		if result.has("error"):
			status_changed.emit(str(result.error))
		elif not result.get("ok", false):
			action_feedback.emit(str(result.get("message","Acción no disponible. Acércate y comprueba los materiales.")),false)
		elif not str(result.get("message","")).is_empty():
			action_feedback.emit(str(result.message),true)
	flush_actions()
