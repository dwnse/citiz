extends SceneTree
const Client = preload("res://network/client.gd")
var failures := 0
var game: Node
var observer: Node
var a: Node
var b: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func until(predicate: Callable, seconds := 5.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline:
		if predicate.call(): return true
		await create_timer(0.02).timeout
	return false
func player(client: Node, id: String) -> Dictionary:
	for p in client.latest.get("players",[]):
		if p.id==id: return p
	return {}
func run() -> void:
	game=load("res://world/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	a=game.network
	var directory: Dictionary = await a.request_json("/api/worlds")
	if not directory.has("worlds"):
		check(false,"server available")
		quit(1)
		return
	var world: String = directory.worlds[0].id
	await a.enter(world,"forest","Art A")
	check(await until(func(): return a.connected),"first graphic client connected")
	var viewport := SubViewport.new()
	viewport.size=Vector2i(640,360)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	observer=load("res://world/main.tscn").instantiate()
	viewport.add_child(observer)
	observer.set_process(false)
	b=observer.network
	b.identities={}
	b.profile_path="user://art_b_%d.json" % Time.get_ticks_msec()
	await b.enter(world,"forest","Art B")
	check(await until(func(): return b.connected and game.actors.has("zombiesart-common")),"two main scenes share authoritative common zombie")
	var actor: Node3D = game.actors["players"+a.player_id]
	var second: Node3D = observer.actors["players"+a.player_id]
	check(actor.visual.skeleton.get_bone_count()>30 and actor.visual.skin_meshes[0].mesh is ArrayMesh,"agent uses imported skinned mesh")
	var infected: Node3D = game.actors["zombiesart-common"]
	var corpse_ref: WeakRef = weakref(infected)
	check(infected.visual.skeleton.get_bone_count()>30,"common zombie uses imported skeleton")
	# Real authoritative input in every direction, with aim changing separately.
	for i in range(8):
		var direction := Vector2.from_angle(i*PI/4)
		var p := player(a,a.player_id)
		var start := Vector2(p.x,p.y)
		var angle := float(i)*PI/4
		await a.send_input(direction,angle)
		await create_timer(0.21).timeout
		await a.send_input(Vector2.ZERO,angle)
		await create_timer(0.13).timeout
		p=player(b,a.player_id)
		check((Vector2(p.x,p.y)-start).dot(direction)>0.4,"direction %d replicated" % i)
		var alignment: float = actor.gun.global_basis.x.normalized().dot(Vector3(cos(angle),0,sin(angle)))
		check(alignment>0.97,"pistol follows aim %d (%.3f)" % [i,alignment])
		check(actor.visual.skeleton.get_bone_pose_scale(actor.visual.skeleton.find_bone("UpperLeg.L")).distance_to(Vector3.ONE)<0.01,"leg scale preserved %d" % i)
	var p := player(a,a.player_id)
	await a.send_input(Vector2(0,-1),0)
	await create_timer(0.18).timeout
	a.act("shoot",{"angle":0})
	check(await until(func(): return actor.visual.shot_count==1 and second.visual.shot_count==1),"one shot animates on both clients")
	check(actor.visual.legs.is_playing() and actor.visual.locomotion!="idle","shooting keeps locomotion running")
	await a.send_input(Vector2.ZERO,0)
	a.act("reload")
	check(await until(func(): return actor.visual.reload_count==1 and second.visual.reload_count==1),"reload animation starts on both clients")
	check(await until(func(): return player(a,a.player_id).get("reload",1)==0),"reload ends with server")
	check(actor.visual.reload_count==1,"repeated snapshots do not restart reload")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/art-021-live.png")
	check(infected.position.x<66,"zombie pursues in live scene")
	for i in range(5):
		if not game.actors.has("zombiesart-common"): break
		p=player(a,a.player_id)
		var z: Dictionary={}
		for candidate in a.latest.zombies:
			if candidate.id=="art-common": z=candidate
		if z.is_empty(): break
		a.act("shoot",{"angle":atan2(z.y-p.y,z.x-p.x)})
		await create_timer(0.38).timeout
	check(await until(func(): return not game.actors.has("zombiesart-common")),"authoritative common zombie killed")
	check(is_instance_valid(infected) and infected.retiring and infected.visual.dead and infected.visual.death_count==1,"removed zombie plays one death before freeing")
	check(infected.visual.hurt_count>0,"zombie damage reaction ran before death")
	check(await until(func(): return game.actors.has("zombiesart-contact")),"contact fixture spawned")
	var contact: Node3D = game.actors["zombiesart-contact"]
	check(await until(func(): return contact.visual.attack_count>0),"server contact starts zombie attack")
	check(await until(func(): return actor.visual.dead and second.visual.dead),"player death synchronized on both rigs")
	check(actor.visual.death_count==1 and second.visual.death_count==1,"death is not restarted by repeated snapshots")
	check(actor.visual.hurt_count>0 and second.visual.hurt_count>0,"damage reaction reaches both clients")
	check(contact.visual.attack_count==2 and float(player(a,a.player_id).hp)==0,"two server contacts cause two attacks and exactly 18 damage")
	check(await until(func(): return corpse_ref.get_ref()==null,3),"corpse mesh freed after death clip")
	await create_timer(0.8).timeout
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/art-021-death.png")
	check(await until(func(): return player(a,a.player_id).get("alive",false),8),"server respawn occurs")
	check(not actor.visual.dead and actor.visible and actor.visual.legs.is_playing(),"respawn resets skeletal pose and movement")
	a.disconnect_world()
	b.disconnect_world()
	print("ART_SMOKE failures=",failures)
	quit(0 if failures==0 else 1)
