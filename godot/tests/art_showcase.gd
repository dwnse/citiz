extends SceneTree
## Deterministic animation reel. Combat/network acceptance lives in art_smoke.gd.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://world/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.hud.visible=false
	game.camera.set_process(false)
	var focus := Vector3(50,0,58)
	game.camera.position=focus+game.camera.offset
	game.camera.look_at(focus)
	game.camera.size=14
	game.Shapes.box(game,Vector3(45,0.1,45),focus-Vector3(0,0.12,0),Color("464d3a"))
	var agent=game.PlayerScene.instantiate()
	var zombie=game.ZombieScene.instantiate()
	game.add_child(agent)
	game.add_child(zombie)
	var label := Label.new()
	label.position=Vector2(32,24)
	label.add_theme_font_size_override("font_size",24)
	var canvas := CanvasLayer.new()
	game.add_child(canvas)
	canvas.add_child(label)
	for frame in range(390):
		var t := frame/30.0
		var p := {"x":48.0,"y":58.0,"angle":0.7,"hp":100,"ammo":12,"alive":true,"reload":0.0,"name":"AGENTE"}
		var z := {"x":52.0,"y":58.0,"hp":68,"alive":true,"attack":0.0}
		var title := "Quieto y apuntado · modelos con esqueleto"
		if t>=1.5 and t<5:
			var direction := Vector2.from_angle(floorf((t-1.5)/0.43)*PI/4)
			p.x=48.0+direction.x*1.3
			p.y=58.0+direction.y*1.3
			p.angle=t*1.7
			z.x=52.0-sin(t)*0.8
			title="Ocho direcciones · piernas y apuntado independientes"
		if t>=4.2:
			p.ammo=11
		if t>=5 and t<7:
			p.reload=maxf(0,7-t)
			title="Recarga · gesto de brazos sobre el rig"
		if t>=7:
			p.ammo=12
			p.hp=91
			z.hp=40
			title="Reacción al daño"
		if t>=8 and t<10:
			z.x=50.1
			z.attack=1-fmod(t-8,1)
			p.hp=82 if t<9 else 73
			title="Ataque · contacto y recuperación"
		if t>=10:
			p.hp=0
			p.alive=false
			z.hp=0
			z.alive=false
			title="Muerte · pose final conservada"
		if t>=12:
			p.hp=100
			p.alive=true
			title="Reaparición · restauración del esqueleto"
		agent.update_state(p)
		zombie.update_state(z)
		agent.caption.visible=false
		zombie.caption.visible=false
		label.text="EL CERCO / ARTE · FASE 1\n"+title+"\nDemostración con estados de prueba"
		await process_frame
		if frame in [175,247,326]:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../docs/art-021-frame-%d.png" % frame)
	quit()
