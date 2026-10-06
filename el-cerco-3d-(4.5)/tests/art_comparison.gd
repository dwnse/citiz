extends SceneTree
## Deterministic real-main-scene comparison: same coordinates, light and camera.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://world/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.hud.visible=false
	game.camera.set_process(false)
	var focus := Vector3(50,0,58)
	game.camera.position=focus+game.camera.offset
	game.camera.look_at(focus)
	game.camera.size=32
	game.Shapes.box(game,Vector3(45,0.1,45),focus-Vector3(0,0.12,0),Color("464d3a"))
	for i in range(6):
		var actor = game.PlayerScene.instantiate() if i<2 else game.ZombieScene.instantiate()
		actor.legacy_model="--before" in OS.get_cmdline_user_args()
		game.add_child(actor)
		actor.update_state({"x":47.0+(i%3)*3.0,"y":56.0+(i/3)*4.0,"hp":100,"maxHp":100,"angle":0.8,"name":"AGENTE","alive":true})
		actor.caption.visible=false
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var suffix := "before" if "--before" in OS.get_cmdline_user_args() else "after"
	root.get_texture().get_image().save_png("res://../docs/art-021-"+suffix+".png")
	# Extra close view only for inspecting the rig; the main comparison stays at size 32.
	game.camera.size=14
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/art-021-"+suffix+"-detail.png")
	quit()
