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
	await a.enter(world, "forest", "Native A")
	if not await until(func(): return a.connected):
		check(false, "first native SSE connection")
		quit(1)
		return
	b = Client.new()
	root.add_child(b)
	b.identities = {}
	b.profile_path = "user://smoke_b_%d.json" % Time.get_ticks_msec()
	await b.enter(world, "forest", "Native B")
	check(await until(func(): return b.connected and a.latest.get("connectedCount", 0) == 2), "two native clients share a world")
	check(a.latest.zombies.size() == 3, "three authoritative infected")
	check(game.actors.size() >= 4, "main scene creates players and infected meshes")
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
	check(a.latest.buildingCatalog.size()==8,"eight structure definitions received")
	a.act("build",{"kind":"gate","x":39.8,"y":60,"rot":0})
	check(await until(func(): return b.latest.walls.size()==2),"snapped gate synchronized")
	a.act("build",{"kind":"well","x":43,"y":57.8,"rot":0})
	check(await until(func(): return b.latest.walls.size()==3),"water production structure synchronized")
	b.act("build_row",{"kind":"wall","x":43,"y":54.6,"endX":39.8,"endY":54.6})
	check(await until(func(): return a.latest.walls.size()==5),"connected row synchronized through native client")
	var wall_id: String = a.latest.walls[0].id
	b.act("upgrade_structure",{"id":wall_id})
	check(await until(func(): return int(a.latest.walls[0].get("level",0))==1),"structure upgrade synchronized")
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
	var old_id: String = a.player_id
	var old_materials := int(player(a, old_id).wood)
	a.disconnect_world()
	check(await until(func(): return b.latest.get("connectedCount", 2) == 1), "disconnect removes presence")
	await a.enter(world, "city", "Ignored rename")
	check(await until(func(): return a.connected), "reconnect receives snapshots")
	check(a.player_id == old_id and player(a, old_id).communityId == "forest", "reconnect preserves identity and faction")
	check(int(player(a, old_id).wood) == old_materials, "reconnect preserves materials")
	check(a.latest.walls.size() == 5, "reconnect preserves construction")
	check(await until(func(): return float(player(a, old_id).get("hp", 100)) < 100, 12), "infected pursues and damages native player")
	# Optional real-render screenshot when run without --headless.
	if "--capture" in OS.get_cmdline_user_args():
		game.set_build_mode(true)
		game.selected_structure=wall_id
		game.hud.inspect_structure(a.latest,player(a,a.player_id),a.latest.walls[0])
		game.hud.build_hint.text="8 estructuras · Encaje automático\nWASD: cámara · 1–8: elegir · G: girar\nClic: construir · B/Esc: supervivencia"
		game.camera.focus = Vector3(player(a, old_id).x, 0, player(a, old_id).y)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://../docs/godot-preview.png")
		check(error == OK, "rendered screenshot saved")
	a.disconnect_world()
	b.disconnect_world()
	game.queue_free()
	b.queue_free()
	await process_frame
	print("NATIVE_SMOKE failures=%d" % failures)
	quit(1 if failures else 0)
