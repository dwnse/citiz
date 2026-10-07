extends SceneTree
## Real scene + real world snapshot, no fabricated buildings or scenery in the capture.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var snapshot_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--snapshot="): snapshot_path=argument.trim_prefix("--snapshot=")
	if snapshot_path.is_empty():
		push_error("Use node tools/capture-forest.mjs GODOT_EXECUTABLE")
		quit(1)
		return
	var file := FileAccess.open(snapshot_path,FileAccess.READ)
	var snapshot: Dictionary=JSON.parse_string(file.get_as_text())
	var game=load("res://world/main.tscn").instantiate()
	game.rendering_preview=true
	root.add_child(game)
	game.set_process(false)
	game.camera.set_process(false)
	game.hud.visible=false
	game.state=snapshot
	game.me={"x":50.0,"y":55.0}
	game.configure_forest_lighting()
	game.make_terrain()
	game.sync_structures()
	game.sync_props()
	game.sync_actors()
	var focus := Vector3(50,0,50)
	game.camera.position=focus+game.camera.offset
	game.camera.look_at(focus)
	game.camera.size=75
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/forest-in-game.png")
	game.camera.size=32
	game.camera.position=Vector3(50,0,52)+game.camera.offset
	game.camera.look_at(Vector3(50,0,52))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/forest-in-game-close.png")
	print("FOREST_RENDER draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," triangles=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var started := Time.get_ticks_usec()
	for i in range(40): await process_frame
	print("FOREST_RENDER average_fps=",40000000.0/(Time.get_ticks_usec()-started))
	print("FOREST_PREVIEW_OK")
	quit()
