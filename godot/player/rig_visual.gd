extends Node3D
## Presentation only. No input, damage, inventory, collision or network authority.
@export var infected := false
@export var model_scene: PackedScene
const RIG_PATH := "CharacterArmature/Skeleton3D:"
const CONTACT_TIME := 0.38
static var libraries: Dictionary = {}
static var materials: Dictionary = {}
var skin_meshes: Array[MeshInstance3D] = []
var stride: SkeletonModifier3D
var model: Node3D
var skeleton: Skeleton3D
var legs: AnimationPlayer
var actions: AnimationPlayer
var gun: MeshInstance3D
var hand: BoneAttachment3D
var flash: MeshInstance3D
var dead := false
var action := ""
var action_left := 0.0
var snapshot: Dictionary = {}
var received := false
var speed := 0.0
var locomotion := "idle"
var shot_count := 0
var attack_count := 0
var reload_count := 0
var death_count := 0
var hurt_count := 0

func _ready() -> void:
	model = model_scene.instantiate()
	add_child(model)
	# Source characters face +Z. Gameplay forward remains -Z; feet stay at y=0.
	model.rotation.y=PI
	model.scale=Vector3.ONE*1.5
	skeleton=model.find_child("Skeleton3D",true,false)
	var source: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
	source.stop()
	if not infected:
		source.play("Idle_Gun")
		source.advance(0)
	var key := "zombie" if infected else "agent"
	for node in skeleton.get_children():
		if node is MeshInstance3D:
			if not materials.has(key):
				var palette := ShaderMaterial.new()
				palette.shader=preload("res://assets/characters/cerco_palette.gdshader")
				var original: StandardMaterial3D = node.mesh.surface_get_material(0)
				palette.set_shader_parameter("atlas",original.albedo_texture)
				palette.set_shader_parameter("infected",infected)
				materials[key]=palette
			node.material_override=materials[key]
			skin_meshes.append(node)
	if not libraries.has(key): libraries[key]=make_libraries(source)
	legs=AnimationPlayer.new()
	legs.name="Locomotion"
	model.add_child(legs)
	legs.add_animation_library("",libraries[key][0])
	actions=AnimationPlayer.new()
	actions.name="Actions"
	model.add_child(actions)
	actions.add_animation_library("",libraries[key][1])
	source.queue_free()
	if not infected:
		gun=model.find_child("Pistol",true,false)
		hand=gun.get_parent()
		stride=preload("res://player/stride_modifier.gd").new()
		skeleton.add_child(stride)
		var mesh := SphereMesh.new()
		mesh.radius=0.045
		mesh.height=0.09
		flash=MeshInstance3D.new()
		flash.mesh=mesh
		var material := StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color=Color("ffe2a1")
		flash.material_override=material
		gun.add_child(flash)
		# Embedded Sam pistol has its muzzle along mesh-local +X.
		flash.position=Vector3(0.74,0.12,0.01)
		flash.visible=false
	legs.play("idle")
	actions.play("idle" if infected else "aim")
	legs.advance(0)
	actions.advance(0)
	if not infected:
		# Correct the asset's downward weapon grip once, in the authored aim pose.
		var hand_basis := skeleton.get_bone_global_pose(skeleton.find_bone("Middle1.L")).basis
		var weapon_basis := hand_basis*gun.basis
		var correction := Basis(Quaternion(weapon_basis.x.normalized(),Vector3.BACK))
		gun.basis=hand_basis.inverse()*correction*weapon_basis
		gun.scale*=0.65

func upper_bone(bone: String) -> bool:
	var index := skeleton.find_bone(bone)
	while index>=0:
		if skeleton.get_bone_name(index)=="Hips": return true
		index=skeleton.get_bone_parent(index)
	return false

func split_animation(source: Animation, upper: bool) -> Animation:
	var result: Animation = source.duplicate()
	for track in range(result.get_track_count()-1,-1,-1):
		var path := result.track_get_path(track)
		var bone := str(path.get_subname(0)) if path.get_subname_count()>0 else ""
		if upper_bone(bone)!=upper: result.remove_track(track)
	return result

func make_libraries(source: AnimationPlayer) -> Array:
	var lower := AnimationLibrary.new()
	var upper := AnimationLibrary.new()
	var names := {"idle":"Idle","walk":"Walk","run":"Run_Arms"} if infected else {"idle":"Idle_Gun","walk":"Walk_Gun","run":"Run_Gun"}
	for state_name in names:
		var clip := split_animation(source.get_animation(names[state_name]),false)
		if not infected:
			# Body is the shared parent of pelvis and legs. Keep its rotation
			# neutral; movement bob is retained and leg steering happens later.
			var neutral := source.get_animation("Idle_Gun")
			var path := NodePath(RIG_PATH+"Body")
			var track := clip.find_track(path,Animation.TYPE_ROTATION_3D)
			var origin_track := neutral.find_track(path,Animation.TYPE_ROTATION_3D)
			if track>=0 and origin_track>=0:
				var orientation: Quaternion = neutral.track_get_key_value(origin_track,0)
				while clip.track_get_key_count(track)>0: clip.track_remove_key(track,0)
				clip.track_insert_key(track,0,orientation)
		clip.loop_mode=Animation.LOOP_LINEAR
		lower.add_animation(state_name,clip)
	for pair in [["idle","Idle"],["aim","Idle" if infected else "Idle_Gun"],["hurt","HitReact"],["attack","Punch" if infected else "Slash"]]:
		var clip := split_animation(source.get_animation(pair[1]),true)
		clip.loop_mode=Animation.LOOP_LINEAR if pair[0] in ["idle","aim"] else Animation.LOOP_NONE
		upper.add_animation(pair[0],clip)
	var death: Animation = source.get_animation("Death").duplicate()
	death.loop_mode=Animation.LOOP_NONE
	upper.add_animation("die",death)
	if not infected:
		upper.add_animation("shoot",gesture(source.get_animation("Idle_Gun"),false))
		upper.add_animation("reload",gesture(source.get_animation("Idle_Gun"),true))
	return [lower,upper]

func gesture(base: Animation, reload_gesture: bool) -> Animation:
	# Authored skeletal clips layered over the imported aiming pose.
	var clip := split_animation(base,true)
	clip.length=1.0 if reload_gesture else 0.18
	clip.loop_mode=Animation.LOOP_NONE
	var poses := {"UpperArm.L":Vector3(0.35,0,-0.25),"LowerArm.L":Vector3(0.55,0,0),"UpperArm.R":Vector3(-0.5,0,0.8),"LowerArm.R":Vector3(0.9,0,0),"Head":Vector3(0.12,0,0)} if reload_gesture else {"UpperArm.L":Vector3(-0.16,0,0),"LowerArm.L":Vector3(-0.12,0,0),"Torso":Vector3(-0.035,0,0)}
	var reload_pose := {}
	if reload_gesture:
		# Two-bone solve at authoring time: lower the pistol and bring the free
		# hand to its magazine. Runtime only interpolates ordinary bone keys.
		reload_pose.merge(arm_pose("L",Vector3(0.22,0.65,0.28),Vector3(1,-1,0)))
		reload_pose.merge(arm_pose("R",Vector3(0.17,0.61,0.36),Vector3(-1,-1,0)))
	for track in range(clip.get_track_count()):
		var kind := clip.track_get_type(track)
		var initial: Variant = clip.track_get_key_value(track,0)
		while clip.track_get_key_count(track)>0: clip.track_remove_key(track,0)
		clip.track_insert_key(track,0,initial)
		var bone := str(clip.track_get_path(track).get_subname(0))
		if kind==Animation.TYPE_ROTATION_3D and (poses.has(bone) or reload_pose.has(bone)):
			var changed: Quaternion = reload_pose[bone] if reload_pose.has(bone) else initial * Quaternion.from_euler(poses[bone])
			clip.track_insert_key(track,clip.length*(0.32 if reload_gesture else 0.18),changed)
			if reload_gesture: clip.track_insert_key(track,0.7,changed)
		clip.track_insert_key(track,clip.length,initial)
	return clip

func arm_pose(side: String, target_hand: Vector3, bend_hint: Vector3) -> Dictionary:
	var upper := skeleton.find_bone("UpperArm."+side)
	var lower := skeleton.find_bone("LowerArm."+side)
	var palm := skeleton.find_bone("Middle1."+side)
	var shoulder_pose := skeleton.get_bone_global_pose(upper)
	var elbow_pose := skeleton.get_bone_global_pose(lower)
	var hand_pose := skeleton.get_bone_global_pose(palm)
	var a := shoulder_pose.origin.distance_to(elbow_pose.origin)
	var b := elbow_pose.origin.distance_to(hand_pose.origin)
	var direction := (target_hand-shoulder_pose.origin).normalized()
	var distance := clampf(shoulder_pose.origin.distance_to(target_hand),absf(a-b)+0.001,a+b-0.001)
	var along := (a*a-b*b+distance*distance)/(2*distance)
	var perpendicular := (bend_hint-direction*bend_hint.dot(direction)).normalized()
	var elbow := shoulder_pose.origin+direction*along+perpendicular*sqrt(maxf(0,a*a-along*along))
	var upper_basis := Basis(Quaternion(shoulder_pose.basis.y.normalized(),(elbow-shoulder_pose.origin).normalized()))*shoulder_pose.basis
	var lower_basis := Basis(Quaternion(elbow_pose.basis.y.normalized(),(target_hand-elbow).normalized()))*elbow_pose.basis
	var parent_basis := skeleton.get_bone_global_pose(skeleton.get_bone_parent(upper)).basis
	return {"UpperArm."+side:(parent_basis.inverse()*upper_basis).get_rotation_quaternion(),"LowerArm."+side:(upper_basis.inverse()*lower_basis).get_rotation_quaternion()}

func play_action(state_name: String, duration := -1.0) -> void:
	if dead and state_name!="die": return
	action=state_name
	var clip := actions.get_animation(state_name)
	action_left=clip.length if duration<0 else duration
	actions.play(state_name,0.07,clip.length/maxf(0.05,action_left))
	if state_name=="attack" and infected:
		# Server applies a single hit when attack resets to 1. Start at contact,
		# then play recovery. Never replay the windup after damage has arrived.
		actions.seek(CONTACT_TIME,true)
		action_left=clip.length-CONTACT_TIME
		attack_count+=1
	elif state_name=="shoot": shot_count+=1
	elif state_name=="reload": reload_count+=1
	elif state_name=="die": death_count+=1
	elif state_name=="hurt": hurt_count+=1

func update_snapshot(value: Dictionary) -> void:
	if value.get("appearance","standard")!=snapshot.get("appearance",""):
		var tint: Color = {"standard":Color("81917b"),"ember":Color("df8e43"),"mist":Color("7bc1bd"),"seal":Color("b297de")}.get(value.get("appearance","standard"),Color("81917b"))
		for mesh in skin_meshes: mesh.set_instance_shader_parameter("insignia",tint)
	var alive: bool = value.get("alive",true) and float(value.get("hp",100))>0
	if not alive and not dead:
		dead=true
		position.z=0
		if is_instance_valid(stride): stride.active=false
		legs.stop(true)
		play_action("die")
	elif alive and dead:
		dead=false
		if is_instance_valid(stride): stride.active=true
		action_left=0
		skeleton.reset_bone_poses()
		legs.play("idle",0)
		locomotion="idle"
		actions.play("idle" if infected else "aim",0)
	if received and alive:
		var reload_time := float(value.get("reload",0))
		if reload_time>0 and float(snapshot.get("reload",0))<=0:
			play_action("reload",reload_time)
		elif action=="reload" and reload_time<=0:
			action_left=0
		if infected and float(value.get("attack",0))>float(snapshot.get("attack",0))+0.1: play_action("attack")
		if not infected and value.get("weapon","pistol")==snapshot.get("weapon","pistol") and int(value.get("ammo",12))<int(snapshot.get("ammo",12)): play_action("shoot")
		if int(value.get("toolSwing",0))>int(snapshot.get("toolSwing",0)): play_action("attack")
		if float(value.get("hp",100))<float(snapshot.get("hp",100)) and action!="reload": play_action("hurt")
	elif alive:
		# Late join / first visibility: resume an action already in progress.
		if not infected and float(value.get("reload",0))>0:
			play_action("reload",float(value.reload))
		elif infected and float(value.get("attack",0))>0.65:
			play_action("attack")
			actions.seek(minf(0.76,CONTACT_TIME+1.0-float(value.attack)),true)
	snapshot=value.duplicate()
	received=true

func tick(delta: float, velocity: Vector3) -> void:
	if dead: return
	position.z=lerpf(position.z,-0.45 if infected and action=="attack" and action_left>0.22 else 0.0,1-exp(-30*delta))
	speed=lerpf(speed,velocity.length(),1-exp(-12*delta))
	var running: bool = speed>4.3 or (infected and snapshot.get("variant","")=="runner" and speed>0.3)
	var next := "run" if running else ("walk" if speed>0.25 else "idle")
	if next!=locomotion:
		locomotion=next
		legs.play(next,0.14)
	# Backpedal reverses the gait; a modifier turns the entire leg chain for
	# sideways movement without twisting the torso or changing bone lengths.
	legs.speed_scale=clampf(speed/(6.0 if next=="run" else 3.0),0.6,1.6) if next!="idle" else 1.0
	if not infected:
		var backwards := velocity.z>0.2
		if backwards: legs.speed_scale *= -1
		var direction := -velocity if backwards else velocity
		var heading := atan2(-direction.x,-direction.z) if speed>0.3 else 0.0
		stride.heading=lerp_angle(stride.heading,heading,1-exp(-12*delta))
	action_left-=delta
	if is_instance_valid(flash): flash.visible=action=="shoot" and action_left>0.12
	if action_left<=0:
		action=""
		var resting := "idle" if infected or snapshot.get("equipped","weapon")=="tool" else "aim"
		if actions.current_animation!=resting: actions.play(resting,0.12)

func finish_death() -> void:
	if dead: return
	dead=true
	position.z=0
	if is_instance_valid(stride): stride.active=false
	legs.stop(true)
	play_action("die")
