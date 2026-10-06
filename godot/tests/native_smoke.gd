extends SceneTree
## Real HTTP/SSE clients and the real main scene, against a disposable server.
const Client = preload("res://network/client.gd")
var failures := 0
var game: Node
var a: Node
var b: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1

func until(predicate: Callable, seconds := 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await create_timer(0.025).timeout
	return false

func player(client: Node, id: String) -> Dictionary:
	for p in client.latest.get("players", []):
		if p.id == id:
			return p
	return {}

func run() -> void:
	var baseline_state := {"version":6,"players":[{"id":"a","hp":100,"private":1}]}
	var patch := {"wire":1,"seq":2,"base":1,"set":{},"remove":[],"entities":{"players":{"upsert":[{"id":"a","set":{"hp":50},"remove":["private"]}],"remove":[]}}}
	var decoded: Dictionary = Client.Replication.apply(baseline_state,1,patch)
	check(decoded.state.players[0].hp==50 and not decoded.state.players[0].has("private") and baseline_state.players[0].hp==100,"native patches remove fields without mutating previous state")
	check(Client.Replication.apply(baseline_state,2,patch).has("error"),"native decoder rejects missing or repeated sequence")
	game = load("res://world/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false) # Test supplies intention, instead of reading a keyboard.
	a = game.get_node("Network")
	a.status_changed.connect(func(message): print("CLIENT "+message))
	var directory: Dictionary = await a.request_json("/api/worlds")
	if not directory.has("worlds"):
		check(false, "directory")
		quit(1)
		return
	var world: String = directory.worlds[0].id
	game.hud.set_worlds(directory.worlds)
	game.hud.open_menu_selection()
	game.hud.agent_name.text = "Native A"
	game.hud.enter_button.pressed.emit()
	if not await until(func(): return a.connected):
		check(false, "first native SSE connection")
		quit(1)
		return
	check(not game.hud.lobby.visible and not game.hud.start_menu.selection.visible and not game.hud.modal_layer.visible, "Enter button connects and closes selector and blocker")
	check(game.playable(), "successful entry restores playable controls")
	b = Client.new()
	root.add_child(b)
	b.identities = {}
	b.profile_path = "user://smoke_b_%d.json" % Time.get_ticks_msec()
	await b.enter(world, "forest", "Native B")
	check(await until(func(): return b.connected and a.latest.get("connectedCount", 0) == 2), "two native clients share a world")
	check(a.latest.zombies.size() == 3, "three authoritative infected")
	check(game.actors.size() >= 4, "main scene creates players and infected meshes")
	for resource_id in ["native-tree","native-rock"]:
		check(game.prop_nodes.has("resource-"+resource_id),"resource model created: "+resource_id)
		if game.prop_nodes.has("resource-"+resource_id):
			var resource_node: Node3D = game.prop_nodes["resource-"+resource_id]
			check(resource_node.is_visible_in_tree() and resource_node.get_node("Shape").get_child_count()>0,"resource geometry visible: "+resource_id)
	check(game.actors["players"+a.player_id].visible,"local living character is visible after entry")
	check(game.camera.focus.distance_to(Vector3(player(a,a.player_id).x,0,player(a,a.player_id).y))<0.1,"camera centers on local character on entry")
	game.set_build_mode(true)
	game.find_plot()
	var found := Vector2(game.camera.focus.x,game.camera.focus.z)
	check(game.Placement.reason(a.latest,player(a,a.player_id),found,"wall",false).is_empty(),"guided construction finds a valid plot")
	game.set_build_mode(false)
	var ended_directory: Array = directory.worlds.duplicate(true)
	ended_directory[0].phase="defeat"
	game.hud.set_worlds(ended_directory)
	check(game.hud.worlds.selected==-1 and game.hud.enter_button.disabled,"finished worlds cannot enter as invisible dead characters")
	game.hud.set_worlds(directory.worlds)
	check(game.hud.worlds.selected==0 and not game.hud.enter_button.disabled,"active world enables entry")
	var world_aim := Vector3(46, 0, 67)
	var screen_aim: Vector2 = game.camera.unproject_position(world_aim)
	check(game.camera.point_from_screen(screen_aim).distance_to(world_aim) < 0.01, "mouse projection returns the ground aim point")
	check(InputMap.action_get_events("forward")[0].physical_keycode == KEY_W, "physical WASD mapping installed")
	var before: Dictionary = player(a, a.player_id)
	var start_x := float(before.x)
	for i in range(4):
		await a.send_input(Vector2(1, 0), 0)
		await create_timer(0.07).timeout
	await a.send_input(Vector2.ZERO, 0)
	check(await until(func(): return float(player(b, a.player_id).get("x", 0)) > start_x + 0.5), "movement visible to second client")
	# A wall within the original build radius, outside the protected public road.
	var materials := int(player(a, a.player_id).wood)
	a.act("build", {"x": 43, "y": 60, "rot": 0})
	check(await until(func(): return a.latest.walls.size() == 1 and b.latest.walls.size() == 1), "construction synchronized")
	check(int(player(a, a.player_id).wood) == materials - 20, "server charges one wall")
	var replay: Dictionary = await a.request_json("/api/action", {"type": "build", "x": 43, "y": 60, "seq": a.seq, "worldId": world}, true)
	check(not replay.get("ok", true), "duplicate sequence rejected")
	var target: Dictionary = a.latest.zombies[0]
	var p: Dictionary = player(a, a.player_id)
	var hp := float(target.hp)
	var ammo := int(p.ammo)
	a.act("shoot", {"angle": atan2(float(target.y)-float(p.y), float(target.x)-float(p.x))})
	check(await until(func(): return int(player(a, a.player_id).get("ammo", 12)) == ammo - 1), "pistol spends authoritative ammunition")
	check(await until(func():
		for z in b.latest.zombies:
			if z.id == target.id and float(z.hp) < hp:
				return true
		return false
	), "damage visible to second client")
	a.act("reload")
	check(await until(func(): return int(player(a, a.player_id).get("ammo", 0)) == 12), "reload completes on authority")
	for cycle in range(3):
		a.act("shoot",{"angle":0})
		check(await until(func(): return int(player(a,a.player_id).get("ammo",12))==11),"repeat shot %d" % cycle)
		a.act("reload")
		check(await until(func(): return int(player(a,a.player_id).get("ammo",0))==12),"repeat reload %d" % cycle)
	check(a.latest.buildingCatalog.size()==18,"eighteen structure definitions received")
	a.act("build",{"kind":"gate","x":39.8,"y":60,"rot":0})
	check(await until(func(): return b.latest.walls.size()==2),"snapped gate synchronized")
	a.act("build",{"kind":"well","x":43,"y":57.8,"rot":0})
	check(await until(func(): return b.latest.walls.size()==3),"water production structure synchronized")
	b.act("build_row",{"kind":"wall","x":43,"y":54.6,"endX":39.8,"endY":54.6})
	check(await until(func(): return a.latest.walls.size()==5),"connected row synchronized through native client")
	var wall_id: String = a.latest.walls[0].id
	b.act("upgrade_structure",{"id":wall_id})
	check(await until(func(): return int(a.latest.walls[0].get("level",0))==1),"structure upgrade synchronized")
	b.act("equip",{"item":"tool"})
	check(await until(func(): return player(a,b.player_id).get("equipped","")=="tool"),"tool equipment shared between clients")
	check(game.actors["players"+b.player_id].tool_model.visible and not game.actors["players"+b.player_id].gun.visible,"hatchet replaces pistol in character hands")
	var gathered_before := int(player(b,b.player_id).wood)
	b.act("harvest",{"id":"native-tree"})
	check(await until(func(): return int(player(a,b.player_id).wood)==gathered_before+6 and int(a.latest.resources[0].hits)==4),"native harvest grants materials and synchronizes tree depletion")
	b.act("equip",{"item":"weapon"})
	check(await until(func(): return player(a,b.player_id).get("equipped","")=="weapon"),"switch back to pistol")
	game.selected_structure=wall_id
	game.hud.inspect_structure(a.latest,player(a,a.player_id),a.latest.walls[0])
	check(game.hud.inspector.visible and "Nivel 2/3" in game.hud.inspection.text,"management inspector reflects authoritative upgrade")
	game.set_build_mode(true)
	game.row_start=Vector2(36.6,58)
	game.row_dragging=true
	game._process(0.016)
	check(game.row_ghosts.get_child_count()>0,"row placement renders ghost pieces")
	game.set_build_mode(false)
	check(not game.row_dragging and game.row_ghosts.get_child_count()==0,"leaving build mode cancels row preview")
	check(a.latest.adventure.sites.size()==12,"expedition sites synchronized")
	var interior_site: Dictionary = a.latest.adventure.sites[0]
	check(interior_site.has("interior") and interior_site.has("hint"),"explorable hospital and objective hint synchronized")
	var interior_view := Node3D.new()
	game.add_child(interior_view)
	game.Expedition.create(interior_view,interior_site)
	game.Expedition.update(interior_view,interior_site)
	check(interior_view.get_node("EntryMarker").visible and not interior_view.get_node("ObjectiveMarker").visible,"interior marks its entry interaction")
	var active_site: Dictionary = interior_site.duplicate(true)
	active_site.encounter={"status":"active"}
	game.Expedition.update(interior_view,active_site)
	check(interior_view.get_node("ObjectiveMarker").visible and not interior_view.get_node("EntryMarker").visible,"active encounter reveals the inner objective")
	interior_view.queue_free()
	check(player(a,b.player_id).materials.timber==6,"typed wood reaches native client")
	game.hud.category.select(1)
	game.hud.show_state(a.latest,player(a,a.player_id),true)
	check(not game.hud.build_buttons.get_child(3).visible and game.hud.build_buttons.get_child(0).visible,"construction categories filter without changing hotkeys")
	game.hud.category.select(0)
	for kind in ["shelter","sawmill","quarry","laboratory"]:
		var view: Node3D = game.BuildingView.create(game,a.latest,{"id":"test-"+kind,"kind":kind,"x":20,"y":20,"communityId":"forest"})
		check(view.get_child_count()>2,"new building has visible geometry: "+kind)
		view.queue_free()
	var boss_view: Node3D = game.ZombieScene.instantiate()
	game.add_child(boss_view)
	boss_view.update_state({"id":"boss-view","x":20,"y":20,"hp":420,"maxHp":420,"boss":true,"bossName":"El Cantor","abilityName":"Curación","warning":2.0,"rallyUntil":Time.get_unix_time_from_system()*1000+8000})
	check("CANTOR" in boss_view.caption.text and "80 daño" in boss_view.caption.text,"boss label explains interruptible ability")
	check(boss_view.rally_ring.visible,"horde buff has a visible marker")
	boss_view.queue_free()
	var resident: Node3D = game.PlayerScene.instantiate()
	resident.worker=true
	game.add_child(resident)
	resident.update_state({"x":20,"y":22,"name":"Inés","status":"Transportando","cargo":{"amount":6}})
	check(not resident.gun.visible and resident.cargo_model.visible and "Inés" in resident.caption.text,"resident renders cargo and status without gun")
	resident.queue_free()
	var courtyard := Node3D.new()
	game.add_child(courtyard)
	game.Expedition.create(courtyard,{"kind":"hospital","name":"Hospital"})
	check(courtyard.has_node("SiteLabel"),"expedition courtyard has recognizable marker")
	courtyard.queue_free()
	a.act("cosmetic",{"style":"standard"})
	check(await until(func(): return a.latest.get("cosmetics",{}).get("equipped","")=="standard"),"account cosmetic equips through authenticated server")
	check(game.hud.cosmetic_buttons.ember.disabled and "Activo" in game.hud.cosmetic_buttons.standard.text,"shop explains equipped style and disables unaffordable purchases")
	check(a.delta_frames>5 and a.state_sequence>5,"native client reconstructs incremental snapshots")
	check(a.latest.adventure.get("collectors",[]).size()==2 and a.latest.adventure.passages.size()==8,"two galleries and their inner exits synchronized")
	var collector := Node3D.new()
	game.add_child(collector)
	var room: Dictionary = a.latest.adventure.collectors[0].duplicate(true)
	game.Collector.create(collector,room)
	game.Collector.update(collector,room)
	check(collector.get_node("Gas").visible and "VENTILAR" in collector.get_node("Valve/Label").text,"gas and ventilation prompt visible")
	room.purgedUntil=Time.get_unix_time_from_system()*1000+120000
	game.Collector.update(collector,room)
	check(not collector.get_node("Gas").visible and "SUMINISTROS" in collector.get_node("Cache/Label").text,"ventilated gallery reveals supply prompt")
	collector.queue_free()
	var example: Dictionary = a.latest.duplicate(true)
	example.population={"residents":2,"capacity":2,"working":1,"food":2,"water":2,"fedSeconds":40,"rationCost":1,"jobs":[{"id":"example-mill","kind":"sawmill","x":43,"y":57,"stock":6,"working":true,"reason":""}]}
	game.hud.population_panel.update_state(example,player(a,a.player_id))
	check(game.hud.population_panel.job_rows.size()==1 and "Rescatados 2" in game.hud.population_panel.summary.text,"community screen displays workers and rations")
	game.hud.toggle_population()
	check(not game.playable(),"community screen blocks movement intentions")
	game.hud.toggle_population()
	game.hud.population_panel.update_state(a.latest,player(a,a.player_id))
	check(game.hud.population_panel.job_rows.is_empty(),"community rows update without leaving stale jobs")
	check(game.hud.settings.volume.max_value==100,"audio and video settings loaded")
	check(game.hud.population_panel.resident_ids.size()==1,"community panel lists individual residents")
	check("Saldo teórico/min" in game.hud.population_panel.summary.text,"community panel explains food and water balance")
	check("Oleada prevista" in game.hud.stats.text,"HUD displays authoritative wave forecast")
	var resident_id: String = game.hud.population_panel.resident_ids[0]
	game.hud.population_panel.resident_order.emit("hold",resident_id)
	check(await until(func(): return a.latest.population.people[0].order=="hold"),"individual hold order reaches authoritative server")
	if "--capture" in OS.get_cmdline_user_args():
		game.hud.population_panel.show()
		await process_frame
		await process_frame
		get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/population-020.png"))
		game.hud.population_panel.hide()
	game.hud.population_panel.resident_order.emit("move",resident_id)
	check(game.target_worker==resident_id and not game.hud.population_panel.visible,"move order opens ground selection")
	var cancel_order := InputEventKey.new()
	cancel_order.physical_keycode=KEY_ESCAPE
	cancel_order.pressed=true
	game._unhandled_input(cancel_order)
	check(game.target_worker.is_empty(),"escape cancels resident destination selection")
	game.hud.population_panel.resident_order.emit("auto",resident_id)
	check(await until(func(): return a.latest.population.people[0].order=="auto"),"resident returns to automatic work")
	game.set_controls_focus(false)
	check(not game.playable(),"losing application focus blocks gameplay")
	game.set_controls_focus(true)
	# A stop sent while another input is in flight must reach the authority.
	a.send_input(Vector2.RIGHT,0)
	a.send_input(Vector2.ZERO,0)
	check(await until(func(): return not a.input_busy and a.pending_input.is_empty()),"latest stop intention drains after in-flight movement")
	await create_timer(0.3).timeout
	var stopped_x := float(player(a,a.player_id).x)
	await create_timer(0.2).timeout
	check(absf(float(player(a,a.player_id).x)-stopped_x)<0.05,"authoritative player remains stopped")
	a.act("dodge")
	check(await until(func(): return player(a,a.player_id).get("dodgeAfter",0)>0),"dodge synchronized")
	var old_id: String = a.player_id
	var old_materials := int(player(a, old_id).wood)
	a.act("sprint",{"enabled":true})
	check(await until(func(): return player(a,old_id).get("sprinting",false)),"sprint enabled before connection loss")
	a.disconnect_world()
	check(await until(func(): return b.latest.get("connectedCount", 2) == 1), "disconnect removes presence")
	await a.enter(world, "city", "Ignored rename")
	check(await until(func(): return a.connected), "reconnect receives snapshots")
	check(a.player_id == old_id and player(a, old_id).communityId == "forest", "reconnect preserves identity and faction")
	check(int(player(a, old_id).wood) == old_materials, "reconnect preserves materials")
	check(a.latest.walls.size() == 5, "reconnect preserves construction")
	check(not player(a,old_id).get("sprinting",true),"reconnection does not retain a held sprint key")
	a.stream.close()
	check(await until(func(): return a.reconnect_at>0),"broken stream schedules automatic recovery")
	check(await until(func(): return a.connected,8),"automatic recovery restores snapshots")
	check(a.player_id==old_id and a.latest.walls.size()==5,"automatic recovery preserves identity and buildings")
	a.fail_stream("Test interruption")
	a.disconnect_world()
	await create_timer(1.2).timeout
	check(not a.connected and a.reconnect_at==0 and a.reconnect_target.is_empty(),"explicit leave cancels scheduled recovery")
	await a.enter(world,"forest","Native A")
	check(await until(func(): return a.connected),"manual entry remains available after cancelling recovery")
	var takeover: Dictionary = await a.request_json("/api/join",{"worldId":world,"key":a.identities[world]},true)
	check(not takeover.has("error"),"same identity can be opened by a replacement connection")
	check(await until(func(): return not a.connected and a.reconnect_target.is_empty()),"replaced session stops instead of fighting the new connection")
	await a.enter(world,"forest","Native A")
	check(await until(func(): return a.connected),"explicit reconnect can reclaim the profile")
	for attempt in range(6): a.fail_stream("Test retry limit")
	check(a.reconnect_attempt==5 and a.reconnect_at==0,"automatic recovery has a five-attempt limit")
	a.disconnect_world()
	await a.enter(world,"forest","Native A")
	check(await until(func(): return a.connected),"manual entry works after retry exhaustion")
	check(await until(func(): return float(player(a, old_id).get("hp", 100)) < 100, 12), "infected pursues and damages native player")
	# Optional real-render screenshot when run without --headless.
	if "--capture" in OS.get_cmdline_user_args():

		game.set_build_mode(true)
		game.selected_structure=wall_id
		game.hud.inspect_structure(a.latest,player(a,a.player_id),a.latest.walls[0])
		game.hud.build_hint.text="18 estructuras · Desplaza el catálogo\nWASD: cámara · 1–8: elegir · G: girar\nClic: construir · B/Esc: supervivencia"
		game.camera.focus = Vector3(player(a, old_id).x, 0, player(a, old_id).y)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://../docs/godot-preview.png")
		check(error == OK, "rendered screenshot saved")
		game.set_process(true)
		var timings: Array[float] = []
		var deadline := Time.get_ticks_usec()+5000000
		var previous := Time.get_ticks_usec()
		while Time.get_ticks_usec()<deadline:
			await process_frame
			var current := Time.get_ticks_usec()
			timings.append(float(current-previous)/1000.0)
			previous=current
		timings.sort()
		var total := 0.0
		for duration in timings: total+=duration
		var report := {"frames":timings.size(),"average_fps":timings.size()*1000.0/total,"p95_frame_ms":timings[int(timings.size()*0.95)],"resolution":"1280x720","renderer":"Compatibility","scenario":"2 clients, 3 infected, 5 structures, building mode, 5 seconds","draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		var file := FileAccess.open("res://../docs/performance-art-021.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		print("PERFORMANCE "+JSON.stringify(report))
		game.set_process(false)
	if "--capture" in OS.get_cmdline_user_args():
		a.snapshot_received.disconnect(game.receive_state)
		var showcase: Dictionary = a.latest.duplicate(true)
		var site: Dictionary = showcase.adventure.sites[0]
		for person in showcase.players:
			if person.id==a.player_id:
				person.alive=true
				person.hp=100
				person.x=site.x
				person.y=site.y+2
		showcase.workers=[{"id":"showcase-worker","name":"Inés","x":site.x+2,"y":site.y+2,"status":"Transportando materiales","cargo":{"amount":6},"communityId":"forest"}]
		game.receive_state(showcase)
		game.set_build_mode(false)
		game.camera.focus=Vector3(site.x,0,site.y)
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://../docs/interior-019.png")==OK,"expedition interior showcase captured")
		game.hud.toggle_journal()
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://../docs/journal-014.png")==OK,"journal and cosmetic shop captured")
		game.hud.toggle_journal()
		var gallery: Dictionary = showcase.adventure.collectors[0]
		for person in showcase.players:
			if person.id==a.player_id:
				person.x=gallery.x-7
				person.y=gallery.y
		game.receive_state(showcase)
		game.camera.focus=Vector3(gallery.x,0,gallery.y)
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://../docs/collectors-015.png")==OK,"walkable gallery captured")
	if "--stress" in OS.get_cmdline_user_args():
		if a.snapshot_received.is_connected(game.receive_state): a.snapshot_received.disconnect(game.receive_state)
		var stress: Dictionary = a.latest.duplicate(true)
		stress.zombies=[]
		stress.walls=[]
		stress.workers=[]
		for i in range(32):
			stress.workers.append({"id":"stress-worker%d" % i,"name":"Rescatado","x":42+(i%8)*1.8,"y":60+int(i/8)*1.8,"status":"Transportando","cargo":{"amount":6},"communityId":"forest"})
		for i in range(96):
			stress.zombies.append({"id":"stress-z%d" % i,"x":40+(i%12)*1.8,"y":48+int(i/12)*1.8,"hp":100,"maxHp":100,"level":2,"boss":false,"attack":0,"communityId":"forest"})
		for i in range(80):
			stress.walls.append({"id":"stress-b%d" % i,"kind":"wall","x":34+(i%10)*3.2,"y":40+int(i/10)*3.2,"hp":180,"maxHp":180,"communityId":"forest"})
		game.receive_state(stress)
		game.set_build_mode(false)
		game.camera.size=48
		game.camera.focus=Vector3(50,0,54)
		await create_timer(0.5).timeout
		var frames: Array[float] = []
		var end := Time.get_ticks_usec()+5000000
		var previous := Time.get_ticks_usec()
		while Time.get_ticks_usec()<end:
			await process_frame
			var now := Time.get_ticks_usec()
			frames.append(float(now-previous)/1000.0)
			previous=now
		frames.sort()
		var total := 0.0
		for duration in frames: total+=duration
		var report := {"average_fps":frames.size()*1000.0/total,"p95_frame_ms":frames[int(frames.size()*0.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"scenario":"Static render stress: 96 infected, 80 walls, 32 residents; no simulated AI for added entities","resolution":"1280x720"}
		var file := FileAccess.open("res://../docs/performance-art-021-stress.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		print("STRESS "+JSON.stringify(report))
	var ended_state: Dictionary = a.latest.duplicate(true)
	ended_state.phase="defeat"
	game.receive_state(ended_state)
	check(game.hud.lobby.visible and not a.connected,"finished reconnect returns to lobby with explanation")
	await create_timer(0.3).timeout
	a.disconnect_world()
	b.disconnect_world()
	game.queue_free()
	b.queue_free()
	await process_frame
	print("NATIVE_SMOKE failures=%d" % failures)
	quit(1 if failures else 0)

