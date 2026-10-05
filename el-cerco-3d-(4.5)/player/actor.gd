extends Node3D
const Art = preload("res://world/art.gd")
const Shapes = preload("res://world/shapes.gd")
@export var zombie := false
var worker := false
var cargo_model: Node3D
var insignia: MeshInstance3D
var last_style := ""
var work_clock := 0.0
var target := Vector3.ZERO
var data: Dictionary = {}
var body: Node3D
var gun: MeshInstance3D
var tool_model: Node3D
var last_swing := 0
var caption: Label3D
var rally_ring: MeshInstance3D
var animator: AnimationPlayer
var last_hp := 100.0
var last_ammo := 12
var last_weapon := "pistol"
var last_attack := 0.0
var hit_time := 0.0
var initialized := false

func _ready() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var coat := Color("c18b43") if worker else (Color("52604a") if not zombie else Color("79606a"))
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
	tool_model=Node3D.new()
	body.add_child(tool_model)
	tool_model.position=Vector3(0.42,1.25,-0.6)
	Shapes.box(tool_model,Vector3(0.09,0.85,0.09),Vector3(0,0.2,0),Color("94734e"))
	Shapes.box(tool_model,Vector3(0.58,0.22,0.12),Vector3(0,0.57,0),Color("9caeaf"))
	tool_model.visible=false
	# Batch rigid parts while keeping animated limbs and equipment independent.
	body.remove_child(gun)
	Art.merge_rigid(body)
	body.add_child(gun)
	for limb in [body.get_node("Left"),body.get_node("Right"),tool_model]: Art.merge_rigid(limb)
	insignia=Shapes.box(body,Vector3(0.7,0.2,0.12),Vector3(0,1.58,-0.38),Color("81917b"))
	insignia.visible=not zombie and not worker
	cargo_model=Node3D.new()
	body.add_child(cargo_model)
	Art.crate(cargo_model,Vector3(0,0.7,-0.8))
	Art.merge_rigid(cargo_model)
	cargo_model.scale=Vector3.ONE*0.5
	cargo_model.visible=false
	caption = Shapes.label(self, "INFECTADO" if zombie else "AGENTE")
	if zombie:
		rally_ring=Shapes.cylinder(self,0.85,0.05,Vector3(0,0.1,0),Color(1,0.6,0.2,0.5))
		rally_ring.visible=false
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
	var style_id: String = str(value.get("appearance","standard"))
	if style_id!=last_style:
		last_style=style_id
		insignia.material_override=Shapes.material({"standard":Color("81917b"),"ember":Color("df8e43"),"mist":Color("7bc1bd"),"seal":Color("b297de")}.get(style_id,Color("81917b")))
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
	if ammo < last_ammo and value.get("weapon","pistol")==last_weapon:
		animator.play("shoot")
		hit_time = 0.25
	last_ammo = ammo
	last_weapon=str(value.get("weapon","pistol"))
	var has_tool: bool = not zombie and value.get("equipped","weapon")=="tool"
	gun.visible=not zombie and not has_tool and not worker
	tool_model.visible=has_tool or (worker and value.get("status","")=="Extrayendo")
	cargo_model.visible=worker and value.get("cargo") is Dictionary
	var swing := int(value.get("toolSwing",0))
	if swing>last_swing:
		animator.play("attack")
		hit_time=0.5
	last_swing=swing
	var attack := float(value.get("attack", 0))
	if zombie and attack > last_attack:
		animator.play("attack")
		hit_time = 0.25
	last_attack = attack
	if is_instance_valid(rally_ring): rally_ring.visible=float(value.get("rallyUntil",0))>Time.get_unix_time_from_system()*1000
	visible = value.get("alive", true)
	scale = Vector3.ONE * (1.6 if value.get("boss", false) else 1.0)
	caption.text = "%d PV" % int(hp) if zombie else "%s · %d" % [value.get("name", "AGENTE"), int(hp)]
	if zombie:
		var identity: String = "PACIENTE 0" if value.get("finalBoss",false) else {"runner":"CORREDOR","brute":"QUEBRANTADOR"}.get(value.get("variant","walker"),"INFECTADO")
		if value.get("boss",false) and not value.get("finalBoss",false): identity=str(value.get("bossName","EL PORTADOR")).to_upper()
		caption.text=identity+" · %d" % hp
		if value.get("warning",0)>0 and not value.get("finalBoss",false): caption.text+="\n%s %.1f s · 80 daño interrumpe" % [value.get("abilityName","Descarga"),value.warning]
		if float(value.get("interruptedUntil",0))>Time.get_unix_time_from_system()*1000: caption.text+="\nINTERRUMPIDO"
		if value.get("variant","")=="brute": scale=Vector3(1.35,1.2,1.35)
		if value.get("variant","")=="runner": scale=Vector3(0.85,1.1,0.85)
	if not zombie: gun.scale.z=1.0 if value.get("weapon","pistol")=="pistol" else 1.8
	caption.visible = not zombie or value.get("boss",false) or hp < float(value.get("maxHp", 100))
	caption.modulate = Color("fbbd83") if zombie else Color("c6e78a")
	if worker:
		caption.text=str(value.get("name","Rescatado"))+" · "+str(value.get("status","Refugio"))
		caption.font_size=22
		caption.modulate=Color("edc07c")

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
	work_clock+=delta
	if tool_model.visible: tool_model.rotation.x=sin(work_clock*7)*0.8 if worker else sin(maxf(0,hit_time)*PI*2)*1.2
	if hit_time <= 0:
		var next := "run" if distance > 0.12 else ("idle" if zombie else "aim")
		if animator.current_animation != next:
			animator.play(next, 0.1)
