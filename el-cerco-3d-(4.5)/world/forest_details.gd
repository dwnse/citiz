extends RefCounted
## Hand-modelled cartoon set: bevels, layered roofs, articulated foliage and small props.
const S = preload("res://world/shapes.gd")

static func mesh(parent: Node3D, vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, reverse := true) -> MeshInstance3D:
	if reverse:
		var ordered := PackedVector3Array()
		var ordered_normals := PackedVector3Array()
		var ordered_colors := PackedColorArray()
		for i in range(0,vertices.size(),3):
			for index in [i,i+2,i+1]:
				ordered.append(vertices[index])
				ordered_normals.append(normals[index])
				ordered_colors.append(colors[index])
		vertices=ordered
		normals=ordered_normals
		colors=ordered_colors
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	for i in range(colors.size()): colors[i]=colors[i].srgb_to_linear()
	arrays[Mesh.ARRAY_COLOR]=colors
	var shape := ArrayMesh.new()
	shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new()
	instance.mesh=shape
	var material := S.material(Color.WHITE)
	material.vertex_color_use_as_albedo=true
	material.vertex_color_is_srgb=false
	instance.material_override=material
	parent.add_child(instance)
	return instance

static func polygon_block(parent: Node3D, size: Vector3, at: Vector3, color: Color, bevel := 0.12) -> MeshInstance3D:
	var hx := size.x/2
	var hz := size.z/2
	var cut := minf(bevel,minf(hx,hz)*0.4)
	var outline := [Vector2(-hx+cut,-hz),Vector2(hx-cut,-hz),Vector2(hx,-hz+cut),Vector2(hx,hz-cut),Vector2(hx-cut,hz),Vector2(-hx+cut,hz),Vector2(-hx,hz-cut),Vector2(-hx,-hz+cut)]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var top := size.y/2
	var bottom := -size.y/2
	for i in range(8):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+1)%8]
		var normal := Vector3(b.y-a.y,0,a.x-b.x).normalized()
		var low_a := Vector3(a.x,bottom,a.y)
		var low_b := Vector3(b.x,bottom,b.y)
		var high_a := Vector3(a.x,top-cut,a.y)
		var high_b := Vector3(b.x,top-cut,b.y)
		var cap_a := Vector3(a.x*0.94,top,a.y*0.94)
		var cap_b := Vector3(b.x*0.94,top,b.y*0.94)
		for p in [low_a,high_a,low_b,low_b,high_a,high_b]:
			vertices.append(at+p)
			normals.append(normal)
			colors.append(color.darkened((i%3)*0.025))
		for p in [high_a,cap_a,high_b,high_b,cap_a,cap_b]:
			vertices.append(at+p)
			normals.append((normal+Vector3.UP).normalized())
			colors.append(color.lightened(0.045))
		for p in [Vector3(0,top,0),cap_b,cap_a]:
			vertices.append(at+p)
			normals.append(Vector3.UP)
			colors.append(color.lightened(0.05))
	var result := mesh(parent,vertices,normals,colors)
	result.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	return result

static func leaf(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=12
	shape.rings=7
	node.mesh=shape
	node.scale=size
	node.position=at
	node.material_override=S.material(color)
	parent.add_child(node)

static func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := S.cylinder(parent,radius,a.distance_to(b),(a+b)/2,color)
	var up := (b-a).normalized()
	var tangent := Vector3.FORWARD.cross(up).normalized()
	if tangent.length()<.1: tangent=Vector3.RIGHT
	node.basis=Basis(tangent,up,tangent.cross(up))
	return node

static func tree(parent: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	var h := rng.randf_range(4.2,5.4)
	var pine := rng.randf()<.48
	S.cylinder(parent,.27,h*.52,at+Vector3(0,h*.26,0),Color("9e652f"))
	for i in range(4):
		var angle := i*TAU/4+.3
		beam(parent,at+Vector3(cos(angle)*.68,.09,sin(angle)*.68),at+Vector3(0,.64,0),.13,Color("9c6936"))
	if pine:
		for tier in range(4):
			var radius := 1.9-tier*.36
			var cone := S.cylinder(parent,radius,2.2,at+Vector3(0,h-3.0+tier*.92,0),Color("299a4a").lightened(tier*.025))
			cone.mesh.top_radius=.035
			cone.mesh.radial_segments=12
			for i in range(5 if tier<2 else 0):
				var angle := i*TAU/5+tier*.47
				leaf(parent,at+Vector3(cos(angle)*radius*.55,h-3.60+tier*.92,sin(angle)*radius*.55),Vector3(radius*.55,.50,radius*.55),Color("2e9e45").lightened(tier*.026))
	else:
		var green := Color("57b630").lightened(rng.randf_range(-.04,.07))
		for tier in range(2):
			for i in range(6):
				var angle := i*TAU/6+tier*.52
				var distance := 1.0 if tier==0 else .62
				leaf(parent,at+Vector3(cos(angle)*distance,h-2.0+tier*.85,sin(angle)*distance),Vector3(2.10,1.85,2.10),green.lightened(tier*.035).darkened((i%3)*.025))
		leaf(parent,at+Vector3(0,h-.15,0),Vector3(1.9,1.65,1.9),green.lightened(.075))
		for i in range(16):
			var a := i*TAU/8+.25
			var tier := i/8
			leaf(parent,at+Vector3(cos(a)*(1.68-tier*.35),h-2.15+tier*1.1+sin(i*2.7)*.28,sin(a)*(1.68-tier*.35)),Vector3(.90,.85,.90),green.lightened((i%4)*.022))
		for i in range(3):
			var angle := i*TAU/3
			beam(parent,at+Vector3(0,h*.40,0),at+Vector3(cos(angle)*.9,h*.61,sin(angle)*.9),.13,Color("a57537"))

static func crate(parent: Node3D, at: Vector3, scale := 1.0) -> void:
	polygon_block(parent,Vector3(.80,.70,.70)*scale,at+Vector3(0,.35*scale,0),Color("b67d3e"))
	for side in [-1,1]:
		S.box(parent,Vector3(.08,.73,.77)*scale,at+Vector3(side*.31*scale,.35*scale,0),Color("e0ae62"))
	S.box(parent,Vector3(.82,.09,.75)*scale,at+Vector3(0,.59*scale,0),Color("ddb076"))
	for side in [-1,1]: S.box(parent,Vector3(.065,.10,.02)*scale,at+Vector3(side*.31*scale,.59*scale,.39*scale),Color("6c6c65"))

static func timber_log(parent: Node3D, at: Vector3, length := 2.0, radius := .25) -> void:
	var node := S.cylinder(parent,radius,length,at+Vector3(0,radius,0),Color("97602d"))
	node.rotation.z=PI/2
	for side in [-1,1]:
		var cut := S.cylinder(parent,radius*.88,.035,at+Vector3(side*length*.505,radius,0),Color("ecc783"))
		cut.rotation.z=PI/2
		var ring := S.cylinder(parent,radius*.56,.040,at+Vector3(side*length*.51,radius,0),Color("c58d43"))
		ring.rotation.z=PI/2
		var heart := S.cylinder(parent,radius*.36,.045,at+Vector3(side*length*.515,radius,0),Color("edc98a"))
		heart.rotation.z=PI/2

static func dome(parent: Node3D) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for ring in range(8):
		for segment in range(32):
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var theta: float=(segment+corner.x)*TAU/32
				var latitude: float=(ring+corner.y)*PI/16
				vertices.append(Vector3(cos(theta)*cos(latitude)*2.03,2.35+sin(latitude)*1.20,sin(theta)*cos(latitude)*2.03))
				normals.append(Vector3(cos(theta)*cos(latitude)/2.03,sin(latitude)/1.2,sin(theta)*cos(latitude)/2.03).normalized())
				colors.append(Color("59b849").darkened(.035*(segment/4%2)).lightened(ring*.005))
	var roof := mesh(parent,vertices,normals,colors,false)
	roof.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	for sector in range(8):
		var angle := sector*TAU/8
		for i in range(7):
			var a := i*PI/14
			var b := (i+1)*PI/14
			beam(parent,Vector3(cos(angle)*cos(a)*2.05,2.36+sin(a)*1.22,sin(angle)*cos(a)*2.05),Vector3(cos(angle)*cos(b)*2.05,2.36+sin(b)*1.22,sin(angle)*cos(b)*2.05),.022,Color("398b39"))

static func core(parent: Node3D) -> void:
	polygon_block(parent,Vector3(4.1,.4,3.7),Vector3(0,.2,0),Color("989ca9"),.3)
	S.cylinder(parent,1.92,2.0,Vector3(0,1.32,0),Color("e4d8b5"))
	for ring in range(3):
		for i in range(12):
			var angle := (i+(ring%2)*.5)*TAU/12
			var block := polygon_block(parent,Vector3(.91,.56,.19),Vector3.ZERO,Color("d6ceb6"),.05)
			block.position=Vector3(sin(angle)*1.93,.64+ring*.59,cos(angle)*1.93)
			block.rotation.y=angle
	dome(parent)
	for side in [-1,1]:
		for i in range(4): polygon_block(parent,Vector3(.50,.54,.53),Vector3(side*1.45,.65+i*.53,1.35),Color("adb0bd").lightened((i%2)*.06),.07)
	polygon_block(parent,Vector3(2.66,.44,.56),Vector3(0,2.42,1.47),Color("e7e2cc"),.10)
	polygon_block(parent,Vector3(1.78,2.08,.32),Vector3(0,1.26,1.83),Color("7a6551"),.12)
	polygon_block(parent,Vector3(1.35,1.75,.10),Vector3(0,1.24,2.01),Color("eeb44e"),.08)
	for x in [-.43,0,.43]: S.box(parent,Vector3(.027,1.57,.05),Vector3(x,1.25,2.08),Color("cc8430"))
	S.box(parent,Vector3(.22,.09,.08),Vector3(.41,1.22,2.13),Color("6a6755"))
	for i in range(3): polygon_block(parent,Vector3(1.75-i*.14,.12,.20),Vector3(0,.16+i*.12,2.11-i*.17),Color("b7b5ad"),.04)
	for side in [-1,1]:
		polygon_block(parent,Vector3(.29,.53,.27),Vector3(side*1.48,1.94,1.70),Color("fff0a1"),.055)
		S.box(parent,Vector3(.19,.32,.10),Vector3(side*1.48,1.94,1.86),Color("ffb532")).material_override=S.material(Color("ffb532"),true)
	S.cylinder(parent,.15,.32,Vector3(0,3.64,0),Color("717685"))
	beam(parent,Vector3(0,3.7,0),Vector3(0,5.02,0),.065,Color("756141"))
	polygon_block(parent,Vector3(1.05,.68,.055),Vector3(.53,4.69,0),Color("209a4d"),.035)
	for i in range(3):
		var icon := S.cylinder(parent,.20-i*.04,.24,Vector3(.55,4.59+i*.14,.06),Color("f0f6d6"))
		icon.rotation.x=PI/2
		icon.mesh.top_radius=0
	crate(parent,Vector3(-1.72,0,1.17),.7)
	S.cylinder(parent,.24,.65,Vector3(1.73,.40,.87),Color("6486a4"))

static func hut(parent: Node3D, width: float, depth: float, watermill := false) -> void:
	var back_depth := depth*.66
	polygon_block(parent,Vector3(width,.24,depth),Vector3(0,.12,0),Color("b5ad91"),.14)
	polygon_block(parent,Vector3(width*.92,2.2,back_depth),Vector3(0,1.30,-depth*.13),Color("e2cda1"),.14)
	var ridge := 3.50
	var roof_shape := PrismMesh.new()
	roof_shape.size=Vector3(width,1.12,back_depth+.22)
	var roof := MeshInstance3D.new()
	roof.mesh=roof_shape
	roof.position=Vector3(0,2.95,-depth*.13)
	roof.material_override=S.material(Color("357cad"))
	parent.add_child(roof)
	for side in [-1,1]:
		for row in range(4):
			var z: float = side*(.16+row*back_depth/8)-depth*.13
			var y := ridge-row*.22
			for col in range(8):
				var x := (col-3.5)*width/8
				var tile := polygon_block(parent,Vector3(width/8+.03,.13,back_depth/7),Vector3.ZERO,Color("3d96ce").lightened(((col+row)%3)*.035),.045)
				tile.position=Vector3(x,y,z)
				tile.rotation.x=side*.45
		for x in [-width*.46,width*.46]: polygon_block(parent,Vector3(.24,2.30,.25),Vector3(x,1.36,side*back_depth*.44-depth*.13),Color("a66c32"),.05)
	polygon_block(parent,Vector3(width+.10,.19,.26),Vector3(0,3.63,-depth*.13),Color("77b9da"),.045)
	var front := depth*.20
	polygon_block(parent,Vector3(width*.30,1.72,.12),Vector3(0,1.14,front+.055),Color("66452d"),.05)
	for side in [-1,1]:
		polygon_block(parent,Vector3(width*.21,.94,.12),Vector3(side*width*.32,1.46,front+.07),Color("8c673c"),.06)
		S.box(parent,Vector3(width*.15,.70,.08),Vector3(side*width*.32,1.46,front+.15),Color("ffcc62"))
		S.box(parent,Vector3(.06,.74,.06),Vector3(side*width*.32,1.46,front+.21),Color("8e683d"))
	polygon_block(parent,Vector3(1.15,.94,.18),Vector3(0,2.72,front+.13),Color("fff0c5"),.08)
	var gear := S.cylinder(parent,.32,.07,Vector3(0,2.74,front+.29),Color("637a87"))
	gear.rotation.x=PI/2
	for i in range(8):
		var angle := i*TAU/8
		var tooth := S.box(parent,Vector3(.13,.16,.08),Vector3(sin(angle)*.34,2.74+cos(angle)*.34,front+.31),Color("637a87"))
		tooth.rotation.z=-angle
	for col in range(6):
		var awning := S.box(parent,Vector3(width/6+.01,.08,depth*.24),Vector3((col-2.5)*width/6,2.12,depth*.37),Color("c8d8d2") if col%2==0 else Color("6b92a4"))
		awning.rotation.x=.12
	for side in [-1,1]: beam(parent,Vector3(side*width*.44,.15,depth*.46),Vector3(side*width*.44,2.10,depth*.46),.075,Color("a36d35"))
	crate(parent,Vector3(-width*.30,.20,depth*.34),.72)
	for i in range(3): timber_log(parent,Vector3(width*.22,.24+i*.15,depth*.37),width*.35,.13)
	polygon_block(parent,Vector3(.55,1.12,.58),Vector3(-width*.25,3.63,-depth*.24),Color("ab8669"),.06)
	polygon_block(parent,Vector3(.69,.14,.72),Vector3(-width*.25,4.20,-depth*.24),Color("d4ae84"),.04)
	for side in [-1,1]:
		polygon_block(parent,Vector3(.17,.44,.22),Vector3(side*width*.43,1.7,front+.21),Color("765532"),.03)
		S.box(parent,Vector3(.13,.27,.13),Vector3(side*width*.43,1.74,front+.35),Color("ffb632")).material_override=S.material(Color("ffb632"),true)
	if watermill:
		var wheel := S.cylinder(parent,.83,.18,Vector3(-width*.45,1.1,0),Color("b1813f"))
		wheel.rotation.z=PI/2
		for i in range(10):
			var a := i*TAU/10
			var paddle := S.box(parent,Vector3(.30,.37,.50),Vector3(-width*.46,1.1+cos(a)*.85,sin(a)*.85),Color("cd9c54"))
			paddle.rotation.x=-a

static func crops(parent: Node3D, width: float, depth: float) -> void:
	polygon_block(parent,Vector3(width,.15,depth),Vector3(0,.08,0),Color("79542c"),.10)
	for side in [-1,1]:
		polygon_block(parent,Vector3(width,.15,.13),Vector3(0,.28,side*depth*.47),Color("c9944f"),.025)
		polygon_block(parent,Vector3(.13,.15,depth),Vector3(side*width*.47,.28,0),Color("c9944f"),.025)
	for row in range(3):
		S.box(parent,Vector3(width*.9,.08,.08),Vector3(0,.18,(row-1)*depth*.28),Color("503e28"))
		for col in range(6):
			var at := Vector3((col-2.5)*width*.14,.47,(row-1)*depth*.28)
			for i in range(3):
				var angle := i*TAU/3
				leaf(parent,at+Vector3(cos(angle)*.16,0,sin(angle)*.16),Vector3(.48,.38,.48),Color("51ac34").lightened(i*.03))
			leaf(parent,at+Vector3(.15,.06,.15),Vector3(.28,.34,.28),Color("ff9c28") if row%2==0 else Color("efc438"))
	for side in [-1,1]:
		for x in [-width*.47,width*.47]: polygon_block(parent,Vector3(.15,.78,.15),Vector3(x,.39,side*depth*.47),Color("b47f3a"),.03)

static func tank(parent: Node3D) -> void:
	for x in [-.66,.66]:
		for z in [-.66,.66]: polygon_block(parent,Vector3(.17,3.30,.17),Vector3(x,1.65,z),Color("b07d3b"),.025)
	for side in [-1,1]:
		beam(parent,Vector3(-.66,.50,side*.66),Vector3(.66,2.77,side*.66),.065,Color("d0a459"))
	polygon_block(parent,Vector3(1.85,.17,1.85),Vector3(0,3.10,0),Color("d9ad64"),.055)
	S.cylinder(parent,.77,1.34,Vector3(0,3.88,0),Color("238dc9"))
	for y in [3.27,3.75,4.48]: S.cylinder(parent,.80,.08,Vector3(0,y,0),Color("78cae5"))
	S.cylinder(parent,.69,.08,Vector3(0,4.56,0),Color("5bbce4"))
	for side in [-1,1]: beam(parent,Vector3(side*.24,.1,.85),Vector3(side*.24,3.13,.85),.04,Color("d9b267"))
	for i in range(10): beam(parent,Vector3(-.24,.25+i*.29,.85),Vector3(.24,.25+i*.29,.85),.035,Color("e6bf76"))
	beam(parent,Vector3(.62,.1,-.25),Vector3(.62,3.8,-.25),.045,Color("708aa0"))

static func cave(parent: Node3D, orange := false) -> void:
	polygon_block(parent,Vector3(4.6,3.9,.20),Vector3(0,1.95,-1.5),Color("292c38"),.4)
	for i in range(7):
		var a := i*PI/6
		polygon_block(parent,Vector3(1.85,1.80,3.7),Vector3(cos(a)*2.18,1.18+sin(a)*2.47,-.2),Color("9093b2").lightened((i%3)*.08),.33)
	var warm := Color("ffa52a") if orange else Color("b779ff")
	for side in [-1,1]:
		beam(parent,Vector3(side*1.18,.18,1.5),Vector3(side*1.18,2.15,1.5),.075,Color("8b643a"))
		leaf(parent,Vector3(side*1.18,2.29,1.5),Vector3(.29,.56,.29),warm)
		for i in range(3):
			var gem := S.cylinder(parent,.24,.75+i*.17,Vector3(side*(.82+i*.23),.50+i*.12,.0),warm)
			gem.mesh.top_radius=.03
			gem.mesh.radial_segments=5
			gem.material_override=S.material(warm,true)
	for side in [-1,1]: beam(parent,Vector3(side*.46,.08,-1.3),Vector3(side*.46,.08,2.4),.035,Color("777e87"))
	for i in range(7): polygon_block(parent,Vector3(1.5,.09,.17),Vector3(0,.04,-1.2+i*.55),Color("986c39"),.025)

static func tent(parent: Node3D, width: float, depth: float) -> void:
	var shape := PrismMesh.new()
	shape.size=Vector3(width,2.5,depth)
	var node := MeshInstance3D.new()
	node.mesh=shape
	node.position.y=1.25
	node.material_override=S.material(Color("ebc557"))
	parent.add_child(node)
	polygon_block(parent,Vector3(width*.35,1.55,.08),Vector3(0,.8,depth*.5+.02),Color("775938"),.05)
	for side in [-1,1]:
		beam(parent,Vector3(side*width*.5,.04,depth*.5),Vector3(0,2.60,depth*.5),.045,Color("b7863d"))
		beam(parent,Vector3(side*width*.5,.04,-depth*.5),Vector3(0,2.60,-depth*.5),.045,Color("b7863d"))
	crate(parent,Vector3(width*.32,.02,depth*.26),.75)
