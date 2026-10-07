extends RefCounted
## Snow-covered Cumbre models share the forest's bevels, palette workflow and live water.
const S = preload("res://world/shapes.gd")
const D = preload("res://world/forest_details.gd")
const F = preload("res://world/forest.gd")
const Flag = preload("res://world/mountain_flag.gdshader")
const SNOW = Color("eef8ff")
const STONE = Color("969eb5")
const BLUE = Color("357fb5")

static func block(parent: Node3D, size: Vector3, at: Vector3, snow := true) -> void:
	D.polygon_block(parent,size,at,STONE.lightened(fposmod(at.x*.11,.10)),minf(size.x,size.z)*.18)
	if snow: D.polygon_block(parent,Vector3(size.x*1.025,.17,size.z*1.025),at+Vector3(0,size.y*.5+.03,0),SNOW,.18)

static func rock(parent: Node3D, size: Vector3, at: Vector3) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var snow_vertices := PackedVector3Array()
	var snow_normals := PackedVector3Array()
	var snow_colors := PackedColorArray()
	var outline := PackedVector3Array()
	for i in range(7):
		var angle := i*TAU/7+.13
		var radius := .86+.13*sin(i*2.4+at.x)
		outline.append(Vector3(cos(angle)*size.x*.5*radius,size.y*.5+sin(i*2.0+at.z)*.14,sin(angle)*size.z*.5*radius))
	for i in range(7):
		var a: Vector3=outline[i]
		var b: Vector3=outline[(i+1)%7]
		var low_a := Vector3(a.x*1.05,-size.y*.5,a.z*1.05)
		var low_b := Vector3(b.x*1.05,-size.y*.5,b.z*1.05)
		var normal := Vector3(a.x+b.x,0,a.z+b.z).normalized()
		for p in [low_a,a,low_b,low_b,a,b]:
			vertices.append(at+p)
			normals.append(normal)
			colors.append(STONE.darkened((i%3)*.035))
		for p in [Vector3(0,size.y*.5+.10,0),b+Vector3(0,.08,0),a+Vector3(0,.08,0),a,a+Vector3(0,.08,0),b,b,a+Vector3(0,.08,0),b+Vector3(0,.08,0)]:
			snow_vertices.append(at+p)
			snow_normals.append(Vector3.UP)
			snow_colors.append(SNOW)
	D.mesh(parent,vertices,normals,colors).material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	D.mesh(parent,snow_vertices,snow_normals,snow_colors).material_override.cull_mode=BaseMaterial3D.CULL_DISABLED

static func flag(parent: Node3D, at: Vector3) -> void:
	D.beam(parent,at,at+Vector3(0,1.75,0),.045,Color("6b7687"))
	var banner := MeshInstance3D.new()
	var cloth := PlaneMesh.new()
	cloth.size=Vector2(1.08,.70)
	cloth.orientation=PlaneMesh.FACE_Z
	cloth.subdivide_width=12
	cloth.subdivide_depth=3
	banner.mesh=cloth
	banner.position=at+Vector3(.54,1.33,0)
	var material := ShaderMaterial.new()
	material.shader=Flag
	banner.material_override=material
	parent.add_child(banner)

static func pine(parent: Node3D, at: Vector3, rng: RandomNumberGenerator, cover := 1.0) -> void:
	var height := rng.randf_range(4.1,5.6)
	S.cylinder(parent,.23,height*.50,at+Vector3(0,height*.25,0),Color("87613d"))
	for tier in range(4):
		var radius := 1.60-tier*.29
		var y := height-2.9+tier*.83
		var branch := S.cylinder(parent,radius,1.95,at+Vector3(0,y,0),Color("246f55").lightened(tier*.025))
		branch.mesh.top_radius=.02
		branch.mesh.radial_segments=10
		var cap_height := 1.54*(.55+cover*.45)
		var cap := S.cylinder(parent,radius*.79*(.55+cover*.45),cap_height,at+Vector3(0,y+.99-cap_height*.5,0),SNOW)
		cap.mesh.top_radius=.015
		cap.mesh.radial_segments=10
		for i in range(3 if cover>.6 else 1):
			var angle := i*TAU/3+tier*.62
			D.leaf(parent,at+Vector3(cos(angle)*radius*.57,y-.40,sin(angle)*radius*.57),Vector3(radius*.7,.25,radius*.7)*(.5+cover*.5),SNOW)

static func roof(parent: Node3D, at: Vector3, width: float, depth: float) -> void:
	var shape := PrismMesh.new()
	shape.size=Vector3(width,.65,depth)
	var node := MeshInstance3D.new()
	node.mesh=shape
	node.position=at
	node.material_override=S.material(BLUE)
	parent.add_child(node)
	D.polygon_block(parent,Vector3(width*.88,.12,.42),at+Vector3(0,.37,0),SNOW,.07)
	for x in [-width*.38,0,width*.38]:
		D.polygon_block(parent,Vector3(.13,.13,depth*.86),at+Vector3(x,.03,0),Color("73a8c5"),.03)

static func window(parent: Node3D, at: Vector3, width := .50, height := .80) -> void:
	D.polygon_block(parent,Vector3(width+.20,height+.17,.16),at,Color("59728b"),.05)
	S.box(parent,Vector3(width,height,.06),at+Vector3(0,0,.11),Color("ffc660")).material_override=S.material(Color("ffb743"),true)
	S.box(parent,Vector3(.055,height,.08),at+Vector3(0,0,.16),Color("9a7642"))

static func tower(parent: Node3D, at: Vector3, small := false) -> void:
	var h := 3.8 if small else 5.7
	block(parent,Vector3(2.2,.35,2.2),at+Vector3(0,.175,0),false)
	block(parent,Vector3(1.85,h,1.85),at+Vector3(0,h*.5,0),false)
	for row in range(5):
		for side in [-1,1]:
			D.polygon_block(parent,Vector3(.35,.38,.23),at+Vector3(side*.76,.52+row*.67,.92),Color("b8becb"),.04)
	for side in [-1,1]:
		D.polygon_block(parent,Vector3(.21,h-.25,.16),at+Vector3(side*.57,h*.5,.99),BLUE,.04)
	window(parent,at+Vector3(0,h-.68,1.00),.64,.83)
	block(parent,Vector3(2.22,.21,2.22),at+Vector3(0,h+.03,0))
	roof(parent,at+Vector3(0,h+.43,0),2.55,2.55)
	S.cylinder(parent,.075,.53,at+Vector3(0,h+1.00,0),Color("687e8b"))
	S.cylinder(parent,.15,.12,at+Vector3(0,h+1.26,0),Color("e3d5a6"))

static func wall(parent: Node3D, width: float, depth: float, at := Vector3.ZERO) -> void:
	var vertical := depth>width
	var count := maxi(1,ceili(maxf(width,depth)/.82))
	for row in range(4):
		for i in range(count):
			var along := (i+.5)/count-.5
			var size := Vector3(width,.50,depth/count-.025) if vertical else Vector3(width/count-.025,.50,depth)
			block(parent,size,at+Vector3(0,.28+row*.51,along*depth) if vertical else at+Vector3(along*width,.28+row*.51,0),false)
	block(parent,Vector3(width+.08,.17,depth+.08),at+Vector3(0,2.15,0))
	for i in range(maxi(2,ceili(maxf(width,depth)/.8))):
		var count_top := maxi(2,ceili(maxf(width,depth)/.8))
		var along := (i+.5)/count_top-.5
		block(parent,Vector3(.44,.45,.44),at+Vector3(0,2.46,along*depth) if vertical else at+Vector3(along*width,2.46,0))

static func vault(parent: Node3D, art_scale := 1.0) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.scale=Vector3.ONE*art_scale
	block(root,Vector3(4.05,.28,3.8),Vector3(0,.14,0),false)
	block(root,Vector3(3.7,2.8,3.5),Vector3(0,1.63,0),false)
	for side in [-1,1]:
		D.polygon_block(root,Vector3(.34,2.8,.30),Vector3(side*1.7,1.65,1.79),BLUE,.06)
		window(root,Vector3(side*1.34,1.8,1.81),.33,.70)
	# Rounded blue vault roof and glowing golden seal from the reference.
	var roof_shell := S.cylinder(root,1.78,3.65,Vector3(0,3.03,0),BLUE)
	roof_shell.rotation.x=PI/2
	roof_shell.scale.y=1.0
	roof_shell.scale.z=.52
	D.polygon_block(root,Vector3(3.35,1.7,.25),Vector3(0,3.03,1.78),Color("c1cfdb"),.30)
	D.polygon_block(root,Vector3(2.2,2.44,.25),Vector3(0,1.69,1.93),Color("ebd28c"),.15)
	D.polygon_block(root,Vector3(1.80,2.07,.12),Vector3(0,1.65,2.09),Color("ffce68"),.11)
	for r in [.55,.38,.19]:
		var seal := S.cylinder(root,r,.045,Vector3(0,1.84,2.18+(.56-r)*.1),Color("c78b2c") if r!=.38 else Color("ffe29a"))
		seal.rotation.x=PI/2
	for i in range(3): block(root,Vector3(2.25,.12,.25),Vector3(0,.08+i*.12,2.22-i*.18),false)
	D.polygon_block(root,Vector3(1.35,.14,2.7),Vector3(-.50,3.97,-.1),SNOW,.12)
	flag(root,Vector3(-1.15,3.90,-.80))
	for side in [-1,1]:
		var turret := Node3D.new()
		root.add_child(turret)
		turret.position=Vector3(side*1.28,0,-1.17)
		turret.scale=Vector3(.5,.85,.5)
		tower(turret,Vector3.ZERO)
	for side in [-1,1]: F.lantern(root,Vector3(side*1.72,.35,1.8))
	var glow := OmniLight3D.new()
	glow.position=Vector3(0,1.9,2.5)
	glow.light_color=Color("ffb54d")
	glow.light_energy=1.8
	glow.omni_range=4.0
	root.add_child(glow)
	var hit := S.cylinder(parent,2.2*art_scale,4.5*art_scale,Vector3(0,2.25*art_scale,0),Color.WHITE,true)
	hit.visible=false

static func watch(parent: Node3D) -> void:
	for x in [-.85,.85]:
		for z in [-.85,.85]: D.beam(parent,Vector3(x,0,z),Vector3(x,4.1,z),.12,Color("926936"))
	for side in [-1,1]:
		D.beam(parent,Vector3(-.85,.5,side*.85),Vector3(.85,3.4,side*.85),.09,Color("bd965e"))
		D.beam(parent,Vector3(.85,.5,side*.85),Vector3(-.85,3.4,side*.85),.09,Color("bd965e"))
	D.polygon_block(parent,Vector3(2.5,.22,2.5),Vector3(0,3.75,0),Color("b99256"),.08)
	block(parent,Vector3(1.35,1.1,1.35),Vector3(0,4.35,0),false)
	window(parent,Vector3(0,4.40,.73),.88,.56)
	roof(parent,Vector3(0,5.13,0),2.5,2.5)
	flag(parent,Vector3(.7,5.4,0))
	for i in range(11): D.beam(parent,Vector3(-.27,.2+i*.32,1.0),Vector3(.27,.2+i*.32,1.0),.045,Color("d4ac71"))

static func radar(parent: Node3D) -> void:
	block(parent,Vector3(3.4,.32,3.4),Vector3(0,.16,0),false)
	for side in [-1,1]:
		D.beam(parent,Vector3(side*1.05,.2,0),Vector3(side*.12,6.9,0),.085,Color("a05647"))
	for i in range(7):
		var wide := 1.05-i*.125
		D.beam(parent,Vector3(-wide,.4+i*.85,0),Vector3(wide,.4+i*.85,0),.065,Color("a8b1c1"))
		D.beam(parent,Vector3(-wide,.4+i*.85,0),Vector3(wide-.12,1.25+i*.85,0),.055,Color("7f8ca3"))
	var dish := S.cylinder(parent,.83,.18,Vector3(.91,3.0,.1),SNOW)
	dish.rotation.x=PI/2
	dish.rotation.z=-.3
	D.beam(parent,Vector3(.91,3,.15),Vector3(.91,3.1,.95),.055,Color("6d7f95"))
	D.crate(parent,Vector3(-1.0,.2,1),.75)
	D.polygon_block(parent,Vector3(1.2,1.15,.8),Vector3(0,.75,1.05),BLUE,.12)
	window(parent,Vector3(0,.83,1.52),.6,.48)

static func mine(parent: Node3D, width: float, depth: float) -> void:
	D.cave(parent,true)
	for side in [-1,1]:
		rock(parent,Vector3(1.45,5.0,depth),Vector3(side*(width*.5-.65),2.5,-.3))
	rock(parent,Vector3(width,1.8,depth),Vector3(0,4.8,-.3))
	D.polygon_block(parent,Vector3(2.58,2.80,.10),Vector3(0,1.48,1.70),Color("5e361d"),.15)
	D.polygon_block(parent,Vector3(1.2,1.8,.06),Vector3(0,1.21,1.78),Color("c77520"),.1)
	for side in [-1,1]: D.beam(parent,Vector3(side*1.33,.2,1.8),Vector3(side*1.33,3.3,1.8),.15,Color("99713e"))
	D.beam(parent,Vector3(-1.48,3.3,1.8),Vector3(1.48,3.3,1.8),.18,Color("bc8b4d"))
	D.crate(parent,Vector3(-2.3,0,2.0),.9)
	D.crate(parent,Vector3(-2.3,.75,2.0),.75)
	flag(parent,Vector3(2.2,5.7,-1.0))
	D.polygon_block(parent,Vector3(1.45,.6,1.05),Vector3(0,.65,2.4),Color("6e7f95"),.10)
	for side in [-1,1]:
		for z in [2.05,2.75]:
			var wheel := S.cylinder(parent,.19,.12,Vector3(side*.70,.23,z),Color("3f4654"))
			wheel.rotation.z=PI/2
	for i in range(3): rock(parent,Vector3(.5,.38,.5),Vector3(-.4+i*.4,.94,2.4))

static func obstacle(parent: Node3D, data: Dictionary) -> void:
	if data.get("scenery","")=="mountain-water": return
	var root := Node3D.new()
	parent.add_child(root)
	root.position=Vector3(data.x,0,data.y)
	var collider := S.box(root,Vector3(data.sx*2,3.5,data.sy*2),Vector3(0,1.75,0),Color.WHITE,true)
	collider.visible=false
	var kind: String=data.get("scenery","")
	match kind:
		"mountain-pine":
			var rng := RandomNumberGenerator.new()
			rng.seed=hash(str(data.id))
			pine(root,Vector3.ZERO,rng,.30 if data.y>185 else 1.0)
		"mountain-wall": wall(root,float(data.sx)*2,float(data.sy)*2)
		"mountain-gatepost":
			block(root,Vector3(.56,3.7,.80),Vector3(0,1.85,0))
			D.polygon_block(root,Vector3(.39,2.4,.10),Vector3(0,1.65,.44),BLUE,.03)
			F.lantern(root,Vector3(0,2.3,.47))
		"mountain-tower": tower(root,Vector3.ZERO)
		"mountain-watch": watch(root)
		"mountain-radar": radar(root)
		"mountain-mine": mine(root,float(data.sx)*2,float(data.sy)*2)
		"mountain-hut","mountain-bunker":
			D.hut(root,float(data.sx)*2,float(data.sy)*2)
			D.polygon_block(root,Vector3(data.sx*1.5,.14,.65),Vector3(0,3.7,-data.sy*.26),SNOW,.1)
		"mountain-cliff":
			var h := 2.6+fposmod(float(data.x)*.87+float(data.y),1.7)
			rock(root,Vector3(data.sx*2,h,data.sy*2),Vector3(0,h*.5,0))
			rock(root,Vector3(data.sx*1.2,1.0,data.sy*1.2),Vector3(.1,h+.3,0))
		_:
			if data.has("landmark"):
				wall(root,float(data.sx)*2,float(data.sy)*2)
			elif str(data.id).ends_with("-ruin"):
				D.hut(root,float(data.sx)*2,float(data.sy)*2)
				roof(root,Vector3(0,3.65,-data.sy*.26),float(data.sx)*1.90,float(data.sy)*1.1)
			else:
				for i in range(4): rock(root,Vector3(data.sx*1.85,4.0+(i%2)*.7,data.sy*.55),Vector3(0,2,-data.sy*.73+i*data.sy*.49))

static func water_mask(world: Dictionary) -> Texture2D:
	var local := {"obstacles":[]}
	for o in world.get("obstacles",[]):
		if o.get("scenery","")=="mountain-water": local.obstacles.append({"x":o.x,"y":o.y-110,"sx":o.sx,"sy":o.sy,"scenery":"forest-water"})
	return F.water_mask(local)

static func landscape(parent: Node3D, world: Dictionary, mask: Texture2D) -> void:
	for side in [-1,1]:
		var ends := 0
		for o in world.get("obstacles",[]):
			if o.get("scenery","")=="mountain-gatepost" and absf(o.y-(160+side*12))<.1: ends+=1
		if ends==2:
			block(parent,Vector3(7.6,.62,.91),Vector3(50,3.85,160+side*12))
			D.polygon_block(parent,Vector3(2.2,.75,.99),Vector3(50,4.48,160+side*12),BLUE,.09)
			flag(parent,Vector3(50,4.90,160+side*12))
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size=Vector2(100,100)
	plane.mesh=mesh
	plane.position=Vector3(50,-6.3,160)
	var material := ShaderMaterial.new()
	material.shader=F.Water
	material.set_shader_parameter("river_mask",mask)
	material.set_shader_parameter("map_offset",Vector2(0,110))
	plane.material_override=material
	parent.add_child(plane)
	var cells := {}
	for o in world.get("obstacles",[]):
		if o.get("scenery","")!="mountain-water": continue
		for col in range(roundi((o.x-o.sx-4)/2),roundi((o.x+o.sx-4)/2)): cells[Vector2i(col,roundi((o.y-115)/2))]=true
	for cell in cells:
		var center := Vector3(5+cell.x*2,0,115+cell.y*2)
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(cell+step): continue
			var at := center+Vector3(step.x*.70,-3.35,step.y*.70)
			var size := Vector3(.66,6.7,2.04) if step.x!=0 else Vector3(2.04,6.7,.66)
			rock(parent,size*Vector3(1.5,1,1.5),at)
	for y in [160.0,188.0]:
		var x := 23+sin((y-110)*.08)*5
		F.bridge(parent,Vector3(x,0,y),true)
		for side in [-1,1]:
			block(parent,Vector3(1.2,6.3,1.2),Vector3(x+side*3,-3.15,y),false)
	# Water curtains stay inside blocked cells, between the plateau and the river.
	for z in [133.0,179.0,199.0]:
		var x := 23+sin((z-110)*.08)*5
		var area := mask.get_image()
		if area.get_pixel(clampi(int(x*5),0,499),clampi(int((z-110)*5),0,499)).r<.5: continue
		var falls := MeshInstance3D.new()
		var curtain := QuadMesh.new()
		curtain.size=Vector2(3.3,6.1)
		falls.mesh=curtain
		falls.position=Vector3(x,-3.05,z)
		var foam := ShaderMaterial.new()
		foam.shader=F.Falls
		falls.material_override=foam
		parent.add_child(falls)
		for i in range(8): D.leaf(parent,Vector3(x-1.5+i*.43,-6.12,z+.4),Vector3(.75,.18,.6),SNOW)
	# Snow-covered cliff rim on the existing impassable world boundary.
	for i in range(35):
		rock(parent,Vector3(4.4,6.0+sin(i)*.6,4.4),Vector3(.25,1.5,111+i*3))
		rock(parent,Vector3(4.4,7.0+cos(i)*.6,4.4),Vector3(1+i*3,2,219.4))

static func dress_building(root: Node3D, kind: String, width: float, depth: float) -> void:
	if kind in ["shelter","workshop","storage","kitchen","infirmary"]:
		for child in root.get_children():
			if child is MeshInstance3D and child.visible: child.hide()
		D.hut(root,width*.96,depth*.96)
		D.polygon_block(root,Vector3(width*.70,.15,.6),Vector3(0,3.70,-depth*.13),SNOW,.1)
		if kind=="infirmary":
			S.box(root,Vector3(.56,.15,.06),Vector3(0,2.74,depth*.20+.38),Color("d94639"))
			S.box(root,Vector3(.15,.56,.06),Vector3(0,2.74,depth*.20+.38),Color("d94639"))
	elif kind=="gate":
		for side in [-1,1]: block(root,Vector3(.28,2.5,.42),Vector3(side*1.45,1.25,0))
