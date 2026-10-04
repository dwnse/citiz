extends Node3D
const Art = preload("res://world/art.gd")
const Shapes = preload("res://world/shapes.gd")
const BuildingView = preload("res://building/view.gd")
const Placement = preload("res://building/placement.gd")
const PlayerScene = preload("res://player/player.tscn")
const ZombieScene = preload("res://zombies/zombie.tscn")
const Settings = preload("res://combat/presentation.tres")
const ShotAudio = preload("res://combat/audio.gd")
@onready var network = $Network
@onready var camera = $Camera
@onready var hud = $HUD
var state: Dictionary = {}
var me: Dictionary = {}
var actors: Dictionary = {}
var structures: Dictionary = {}
var terrain := Node3D.new()
var props := Node3D.new()
var trails := Node3D.new()
var preview: MeshInstance3D
var world_key := ""
var building := false
var selected_kind := "wall"
var build_offset := Vector3.ZERO
var grid_view: MeshInstance3D
var grid_radius := 0.0
var structure_versions: Dictionary = {}
var rotated := false
var input_timer := 0.0
var shot_timer := 0.0
var selected_world := ""
var selected_community := "forest"
var selected_name := "Agente Godot"
var shot_audio: AudioStreamPlayer
var previous_ammo := -1
var selected_structure := ""
var row_dragging := false
var row_start := Vector2.ZERO
var row_ghosts := Node3D.new()

func _ready() -> void:
	add_child(terrain)
	add_child(props)
	add_child(trails)
	add_child(row_ghosts)
	shot_audio = ShotAudio.new()
	add_child(shot_audio)
	preview = Shapes.box(self, Settings.wall_size, Vector3.ZERO, Color(0.4, 1, 0.6, 0.45))
	preview.visible = false
	# Preview floor is replaced by the real world's geometry on first snapshot.
	Shapes.box(terrain, Vector3(220, 0.4, 220), Vector3(110, -0.2, 110), Color("263e38"), true)
	for binding in [["left", KEY_A], ["right", KEY_D], ["forward", KEY_W], ["back", KEY_S]]:
		InputMap.add_action(binding[0])
		var event := InputEventKey.new()
		event.physical_keycode = binding[1]
		InputMap.action_add_event(binding[0], event)
	network.snapshot_received.connect(receive_state)
	network.status_changed.connect(func(message): hud.status.text = message)
	network.directory_received.connect(hud.set_worlds)
	hud.refresh_requested.connect(network.refresh_worlds)
	hud.create_requested.connect(network.create_world)
	hud.enter_requested.connect(enter)
	hud.structure_chosen.connect(func(kind): selected_kind=kind; set_build_mode(true))
	hud.management_action.connect(func(action):
		if playable() and not selected_structure.is_empty(): network.act(action,{"id":selected_structure})
	)
	hud.leave_requested.connect(leave)
	hud.reconnect_requested.connect(func():
		if not selected_world.is_empty():
			enter(selected_world, selected_community, selected_name)
	)
	network.refresh_worlds()

func enter(world: String, community: String, agent_name: String) -> void:
	selected_world = world
	selected_community = community
	selected_name = agent_name
	set_build_mode(false)
	previous_ammo = -1
	await network.enter(world, community, agent_name)

func leave() -> void:
	network.disconnect_world()
	me = {}
	set_build_mode(false)
	hud.journal.hide()
	hud.lobby.show()
	hud.status.text = "Desconectado. La plaza y el inventario se conservan."
	network.refresh_worlds()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func receive_state(value: Dictionary) -> void:
	state = value
	me = {}
	for player in state.players:
		if player.id == network.player_id:
			me = player
	if me.is_empty():
		return
	if previous_ammo >= 0 and int(me.ammo) < previous_ammo:
		shot_audio.play()
	previous_ammo = int(me.ammo)
	if world_key != state.id:
		world_key = state.id
		for actor in actors.values():
			actor.queue_free()
		actors.clear()
		for structure in structures.values():
			structure.queue_free()
		structures.clear()
		structure_versions.clear()
		grid_radius=0
		make_terrain()
		camera.focus = Vector3(me.x, 0, me.y)
		camera.position = camera.focus + camera.offset
	var radius := 18.0+float(state.vault.get("upgrades",0))*6
	if radius!=grid_radius:
		if is_instance_valid(grid_view): grid_view.queue_free()
		grid_radius=radius
		grid_view=BuildingView.grid(self,Vector3(state.vault.x,0,state.vault.y),radius)
		grid_view.visible=building
	sync_actors()
	sync_structures()
	sync_props()
	hud.show_state(state, me, building)
	var inspected: Dictionary = {}
	for b in state.walls:
		if b.id==selected_structure: inspected=b
	hud.inspect_structure(state,me,inspected)

func make_terrain() -> void:
	clear_children(terrain)
	var size := float(state.size)
	Art.landscape(terrain, state)
	for obstacle in state.get("obstacles", []):
		Art.obstacle(terrain, obstacle)
	for edge in [Vector3(0.8, 2, size/2), Vector3(size-0.8, 2, size/2)]:
		Shapes.box(terrain, Vector3(2.4, 4, size), edge, Color("3e4b50"), true)
	for edge in [Vector3(size/2, 2, 0.8), Vector3(size/2, 2, size-0.8)]:
		Shapes.box(terrain, Vector3(size, 4, 2.4), edge, Color("3e4b50"), true)

func sync_actors() -> void:
	var keep := {}
	for kind in ["players", "zombies"]:
		for entity in state[kind]:
			var key: String = kind + str(entity.id)
			keep[key] = true
			if not actors.has(key):
				var actor = PlayerScene.instantiate() if kind == "players" else ZombieScene.instantiate()
				add_child(actor)
				actors[key] = actor
			actors[key].update_state(entity)
	for key in actors.keys():
		if not keep.has(key):
			actors[key].queue_free()
			actors.erase(key)

func sync_structures() -> void:
	var keep := {}
	for wall in state.walls:
		var key: String = wall.id
		keep[key] = true
		var signature := str(wall.get("kind","wall"))+str(wall.get("open",false))
		if structures.has(key) and structure_versions.get(key,"")!=signature:
			structures[key].queue_free()
			structures.erase(key)
		if not structures.has(key):
			structures[key]=BuildingView.create(self,state,wall)
			structure_versions[key]=signature
	for c in state.communities:
		var key: String = "vault-" + str(c.id)
		keep[key] = true
		if not structures.has(key):
			var base := Node3D.new()
			base.position = Vector3(c.x, 0, c.y)
			add_child(base)
			Art.vault(base)
			structures[key] = base
		structures[key].scale.y = 1 if c.vault.hp > 0 else 0.2
	for key in structures.keys():
		if not keep.has(key):
			structures[key].queue_free()
			structures.erase(key)

func sync_props() -> void:
	clear_children(props)
	clear_children(trails)
	for drop in state.drops:
		Art.crate(props, Vector3(drop.x, 0, drop.y))
	var story: Dictionary = state.get("story", {})
	if story.has("radio"):
		Art.wreck(props, Vector3(story.radio.x, 0, story.radio.y))
	for mage in story.get("mages", []):
		var actor := Node3D.new()
		props.add_child(actor)
		actor.position = Vector3(mage.x, 0, mage.y)
		Shapes.cylinder(actor, 0.65, 1.6, Vector3(0, 0.8, 0), Color("8b72ba"))
		Shapes.box(actor, Vector3(0.6, 0.6, 0.6), Vector3(0, 1.9, 0), Color("ddc8af"))
		Shapes.label(actor, mage.name + " · E", 2.8)
	if me.get("intro", false) and story.has("seal"):
		Shapes.cylinder(props, 2.8, 0.3, Vector3(story.seal.x, 0.15, story.seal.y), Color("8f75bc"))
	for shot in state.shots:
		var length := float(shot.length)
		var trail := Shapes.box(trails, Vector3(length, Settings.trail_width, Settings.trail_width), Vector3(shot.x+cos(shot.angle)*length/2, 1.35, shot.y+sin(shot.angle)*length/2), Settings.muzzle_color)
		trail.rotation.y = -shot.angle
	for z in state.zombies:
		if z.get("warning", 0) > 0:
			Shapes.cylinder(props, 6, 0.05, Vector3(z.x, 0.07, z.y), Color(1, 0.2, 0.08, 0.28))
		if z.get("charmUntil", 0) > Time.get_unix_time_from_system() * 1000:
			Shapes.cylinder(props, 1, 0.07, Vector3(z.x, 0.09, z.y), Color(0.6, 0.3, 1, 0.6))
	for p in state.players:
		var effects: Dictionary = p.get("magic", {}).get("effects", {})
		if p.alive and effects.get("shield", 0) > Time.get_unix_time_from_system() * 1000:
			Shapes.cylinder(props, 1.05, 2.7, Vector3(p.x, 1.35, p.y), Color(0.3, 0.8, 1, 0.18))
	for effect in state.get("effects", []):
		var tint := Color(0.7, 0.45, 1, 0.35)
		if effect.power == "heal":
			tint = Color(0.4, 1, 0.5, 0.35)
		var radius := 0.5 + (0.7-float(effect.life)) * 4
		Shapes.cylinder(props, radius, 0.1, Vector3(effect.x, 0.12, effect.y), tint)

func playable() -> bool:
	return network.connected and not me.is_empty() and not hud.lobby.visible and not hud.journal.visible and me.get("alive", false) and state.get("phase", "") == "active"

func _process(delta: float) -> void:
	input_timer -= delta
	shot_timer -= delta
	if not me.is_empty():
		camera.focus = Vector3(me.x, 0, me.y)+build_offset
	preview.visible = building and playable()
	row_ghosts.visible = building and playable()
	if not playable(): row_dragging=false
	if not network.connected or me.is_empty():
		return
	var aim: Vector3 = camera.ground_point()
	var angle := atan2(aim.z-float(me.y), aim.x-float(me.x))
	if building and playable():
		var pan := Input.get_vector("left","right","forward","back")
		build_offset += Vector3(pan.x,0,pan.y).rotated(Vector3.UP,atan2(camera.offset.x,camera.offset.z))*delta*18
		build_offset=build_offset.limit_length(grid_radius+8)
	if input_timer <= 0:
		input_timer = Settings.input_interval
		var direction := Input.get_vector("left", "right", "forward", "back") if playable() and not building else Vector2.ZERO
		var world_direction := Vector3(direction.x, 0, direction.y).rotated(Vector3.UP, atan2(camera.offset.x, camera.offset.z))
		network.send_input(Vector2(world_direction.x, world_direction.z), angle)
	if not playable():
		return
	var grid := Placement.snap(state,Vector2(aim.x,aim.z),selected_kind,rotated)
	if building:
		var d := Placement.definition(state,selected_kind)
		preview.mesh.size=Vector3(d.width,d.height,d.depth)
		preview.position = Vector3(grid.x, d.height/2, grid.y)
		preview.rotation.y = PI/2 if rotated else 0
		var reason := Placement.reason(state,me,grid,selected_kind,rotated)
		preview.material_override.albedo_color = Color(0.3,1,0.5,0.5) if reason.is_empty() else Color(1,0.2,0.2,0.5)
		hud.build_hint.text="%s · %d materiales\n%s\n%s" % [d.name,d.cost,d.get("description",""),"Clic: colocar · Encaje automático · G: girar" if reason.is_empty() else reason]
		clear_children(row_ghosts)
		if row_dragging:
			preview.visible=false
			var end := Vector2(aim.x,aim.z)
			var difference := end-row_start
			var vertical := absf(difference.y)>absf(difference.x)
			var length_axis := difference.y if vertical else difference.x
			var count := mini(20,1+int(floor(absf(length_axis)/3.2+0.5)))
			var shadow: Dictionary = state.duplicate(true)
			var payer: Dictionary = me.duplicate(true)
			var points: Array[Vector2] = []
			var row_reason := ""
			for i in range(count):
				var point := row_start+(Vector2.DOWN if vertical else Vector2.RIGHT)*i*3.2*(1 if length_axis>=0 else -1)
				points.append(point)
				var problem := Placement.reason(shadow,payer,point,selected_kind,vertical)
				if not problem.is_empty() and row_reason.is_empty(): row_reason=problem
				shadow.walls.append({"x":point.x,"y":point.y,"kind":selected_kind,"rot":1 if vertical else 0,"communityId":me.communityId})
				payer.wood-=d.cost
			if absf(length_axis)/3.2>=19.5: row_reason="Máximo 20 piezas por fila"
			for point in points:
				var ghost := Shapes.box(row_ghosts,Vector3(d.width,d.height,d.depth),Vector3(point.x,d.height/2,point.y),Color(0.3,1,0.5,0.4) if row_reason.is_empty() else Color(1,0.2,0.2,0.4))
				ghost.rotation.y=PI/2 if vertical else 0
			hud.build_hint.text="Fila: %d piezas · %d materiales\nSoltar: construir · Clic derecho: cancelar\n%s" % [count,count*d.cost,row_reason]
		else:
			hud.build_hint.text+="\nMayús + arrastrar: fila de defensas"
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shot_timer <= 0 and me.ammo>0 and me.reload<=0 and get_viewport().gui_get_hovered_control() == null:
		shot_timer = Settings.shot_interval
		network.act("shoot", {"angle": angle})

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_J:
			hud.toggle_journal()
		if event.physical_keycode == KEY_ESCAPE:
			set_build_mode(false)
			hud.journal.hide()
	if not playable():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		if row_dragging:
			row_dragging=false
		else:
			var inspected := hovered_structure()
			selected_structure=str(inspected.get("id",""))
			hud.inspect_structure(state,me,inspected)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and building:
		var point: Vector3 = camera.ground_point()
		var target := Placement.snap(state,Vector2(point.x,point.z),selected_kind,rotated)
		if event.shift_pressed and selected_kind in ["wall","gate","spikes"]:
			row_start=target
			row_dragging=true
		else:
			network.act("build", {"kind":selected_kind,"x":target.x,"y":target.y,"rot":1 if rotated else 0})
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if building and event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_8:
		row_dragging=false
		var index: int = event.physical_keycode-KEY_1
		if index<hud.catalog_ids.size(): selected_kind=hud.catalog_ids[index]
		return
	match event.physical_keycode:
		KEY_B: set_build_mode(not building)
		KEY_G: rotated = not rotated
		KEY_R: network.act("reload")
		KEY_C: network.act("craft")
		KEY_V: network.act("scavenge")
		KEY_E:
			var hovered := hovered_structure()
			if not hovered.is_empty() and hovered.get("kind","wall")!="wall":
				network.act("use",{"id":hovered.id})
			else: network.act("interact")
		KEY_U: network.act("upgrade")
		KEY_T: network.act("deposit")
		KEY_F, KEY_X:
			var nearest: Dictionary = {}
			var distance := 5.0
			for wall in state.walls:
				var d := Vector2(wall.x-me.x, wall.y-me.y).length()
				if wall.get("communityId", "forest") == me.communityId and d < distance:
					nearest = wall
					distance = d
			if not nearest.is_empty():
				network.act("repair" if event.physical_keycode == KEY_F else "dismantle", {"id": nearest.id})
		KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			var powers := ["heal", "haste", "fury", "resist", "control", "shield"]
			network.act("cast", {"power": powers[event.physical_keycode-KEY_2]})

func set_build_mode(enabled: bool) -> void:
	row_dragging=false
	clear_children(row_ghosts)
	building=enabled
	if not enabled: build_offset=Vector3.ZERO
	if is_instance_valid(grid_view): grid_view.visible=enabled
	if is_instance_valid(hud) and is_instance_valid(hud.build_panel): hud.build_panel.visible=enabled
	if not enabled:
		selected_structure=""
		if is_instance_valid(hud): hud.inspector.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and row_dragging:
		row_dragging=false
		if playable() and building and get_viewport().gui_get_hovered_control()==null:
			var end: Vector3 = camera.ground_point()
			network.act("build_row",{"kind":selected_kind,"x":row_start.x,"y":row_start.y,"endX":end.x,"endY":end.z})
		get_viewport().set_input_as_handled()

func hovered_structure() -> Dictionary:
	var point: Vector3 = camera.ground_point()
	for b in state.get("walls",[]):
		var h := Placement.half(state,b)
		if absf(b.x-point.x)<h.x+0.3 and absf(b.y-point.z)<h.y+0.3 and b.communityId==me.get("communityId",""):
			return b
	return {}
