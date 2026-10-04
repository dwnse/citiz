extends Node3D
const Art = preload("res://world/art.gd")
const Shapes = preload("res://world/shapes.gd")
@export var zombie := false
var target := Vector3.ZERO
var data: Dictionary = {}
var body: Node3D
var gun: MeshInstance3D
var caption: Label3D
var animator: AnimationPlayer
var last_hp := 100.0
var last_ammo := 12
var last_attack := 0.0
var hit_time := 0.0
var initialized := false

func _ready() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var coat := Color("52604a") if not zombie else Color("79606a")
	Art.stone(body,Vector3(0,1.3,0),Vector3(0.76,0.95,0.48),coat)
	Shapes.box(body,Vector3(0.61,0.57,0.18),Vector3(0,1.35,-0.23),Color("41483b"))
	Art.stone(body,Vector3(0,1.98,0),Vector3(0.44,0.55,0.43),Color("c5a684") if not zombie else Color("a9af8c"))
	if not zombie:
		Art.stone(body,Vector3(0,2.15,0.015),Vector3(0.51,0.31,0.49),Color("38463a"))
		Shapes.box(body,Vector3(0.36,0.11,0.07),Vector3(0,2.0,-0.22),Color("283536"))
		Shapes.box(body,Vector3(0.51,0.62,0.3),Vector3(0,1.32,0.35),Color("6b6348"))
		for side in [-1,1]:
			Shapes.box(body,Vector3(0.18,0.24,0.14),Vector3(side*0.18,1.15,-0.34),Color("948268"))
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.name = "Left" if side == -1 else "Right"
		leg.position=Vector3(side*0.22,0.85,0)
		body.add_child(leg)
		Art.stone(leg,Vector3(0,-0.34,0),Vector3(0.28,0.8,0.31),Color("39423c"))
		Shapes.box(leg,Vector3(0.29,0.2,0.42),Vector3(0,-0.73,-0.08),Color("292e2a"))
		Art.stone(body,Vector3(side*0.42,1.39,-0.21),Vector3(0.26,0.29,0.72),coat)
		Art.stone(body,Vector3(side*0.42,1.32,-0.53),Vector3(0.19,0.2,0.23),Color("aa997e"))
	gun = Shapes.box(body, Vector3(0.15,0.16,0.53), Vector3(0.42,1.37,-0.83), Color("30383a"))
	gun.visible = not zombie
	caption = Shapes.label(self, "INFECTADO" if zombie else "AGENTE")
	if zombie:
		caption.font_size = 32
		caption.pixel_size = 0.016
	animator = AnimationPlayer.new()
	add_child(animator)
	var library := AnimationLibrary.new()
	for state_name in ["idle", "run", "aim", "shoot", "hurt", "attack"]:
		var animation := Animation.new()
		animation.length = 0.6 if state_name in ["idle", "run", "aim"] else 0.22
		if state_name in ["idle", "run", "aim"]:
			animation.loop_mode = Animation.LOOP_LINEAR
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Body:position:y"))
		var amplitude := 0.12 if state_name == "run" else 0.025
		if state_name in ["hurt", "attack", "shoot"]:
			amplitude = -0.12
		animation.track_insert_key(track, 0, 0.0)
		animation.track_insert_key(track, animation.length / 2, amplitude)
		animation.track_insert_key(track, animation.length, 0.0)
		track = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Body:rotation:x"))
		var lean := -0.16 if state_name == "shoot" else (0.3 if state_name == "attack" else 0.0)
		animation.track_insert_key(track, 0, 0.0)
		animation.track_insert_key(track, animation.length / 2, lean)
		animation.track_insert_key(track, animation.length, 0.0)
		for leg_name in ["Left", "Right"]:
			track = animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track, NodePath("Body/" + leg_name + ":rotation:x"))
			var stride := 0.55 if state_name == "run" else 0.0
			if leg_name == "Right":
				stride *= -1
			animation.track_insert_key(track, 0, stride)
			animation.track_insert_key(track, animation.length / 2, -stride)
			animation.track_insert_key(track, animation.length, stride)
		library.add_animation(state_name, animation)
	animator.add_animation_library("", library)

func update_state(value: Dictionary) -> void:
	data = value
	target = Vector3(value.x, 0, value.y)
	if not initialized:
		position = target
		initialized = true
	var hp := float(value.get("hp", 100))
	if hp < last_hp:
		animator.play("hurt")
		hit_time = 0.25
	last_hp = hp
	var ammo := int(value.get("ammo", 12))
	if ammo < last_ammo:
		animator.play("shoot")
		hit_time = 0.25
	last_ammo = ammo
	var attack := float(value.get("attack", 0))
	if zombie and attack > last_attack:
		animator.play("attack")
		hit_time = 0.25
	last_attack = attack
	visible = value.get("alive", true)
	scale = Vector3.ONE * (1.6 if value.get("boss", false) else 1.0)
	caption.text = "%d PV" % int(hp) if zombie else "%s · %d" % [value.get("name", "AGENTE"), int(hp)]
	caption.visible = not zombie or hp < float(value.get("maxHp", 100))
	caption.modulate = Color("fbbd83") if zombie else Color("c6e78a")

func _process(delta: float) -> void:
	if not initialized:
		return
	var distance := position.distance_to(target)
	if distance > 10:
		position = target
	else:
		position = position.lerp(target, 1 - exp(-18 * delta))
	if zombie:
		if distance > 0.05:
			rotation.y = lerp_angle(rotation.y, atan2(-(target.x-position.x), -(target.z-position.z)), minf(1, delta * 12))
	else:
		rotation.y = -float(data.get("angle", 0)) - PI / 2
	hit_time -= delta
	if hit_time <= 0:
		var next := "run" if distance > 0.12 else ("idle" if zombie else "aim")
		if animator.current_animation != next:
			animator.play(next, 0.1)
