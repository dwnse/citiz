extends RefCounted
## Forest art only. All solid footprints and harvestable objects remain authoritative.
const S = preload("res://world/shapes.gd")
const D = preload("res://world/forest_details.gd")
const Water = preload("res://world/forest_water.gdshader")
const Falls = preload("res://world/forest_falls.gdshader")

static func blob(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 10
	sphere.rings = 5
	node.mesh = sphere
	node.position = at
	node.scale = size
	node.material_override = S.material(color)
	parent.add_child(node)
	return node

static func tree(parent: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	D.tree(parent,at,rng)

static func rock(parent: Node3D, at: Vector3, size: Vector3) -> void:
	D.polygon_block(parent,size,at,Color("9998b2").lightened(fposmod(at.x,.12)),minf(size.x,size.z)*.23)

static func lantern(parent: Node3D, at: Vector3) -> void:
	S.box(parent,Vector3(0.32,0.8,0.32),at,Color("80512d"))
	S.box(parent,Vector3(0.46,0.12,0.46),at+Vector3(0,0.45,0),Color("ffd46c"))
	S.box(parent,Vector3(0.20,0.36,0.20),at+Vector3(0,0.7,0),Color("ffb535")).material_override = S.material(Color("ffb535"),true)
	S.box(parent,Vector3(0.38,0.1,0.38),at+Vector3(0,0.93,0),Color("825333"))

static func vault(parent: Node3D, art_scale := 1.0) -> void:
	var model := Node3D.new()
	parent.add_child(model)
	model.scale=Vector3.ONE*art_scale
	D.core(model)
	var collision := S.cylinder(parent,2.2*art_scale,2.5*art_scale,Vector3(0,1.25*art_scale,0),Color.WHITE,true)
	collision.visible=false
static func wall(parent: Node3D, dimensions: Vector3, at: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position=at
	if dimensions.z>dimensions.x: root.rotation.y=PI/2
	var collider := S.box(root,Vector3(3.2,2.4,1.2),Vector3.ZERO,Color.WHITE,true)
	collider.visible=false
	for i in range(8):
		var x := -1.4+i*0.4
		S.cylinder(root,0.19,2.20,Vector3(x,-0.04,0),Color("b47b3b").lightened((i%3)*0.04))
		var tip := S.cylinder(root,0.19,0.28,Vector3(x,1.20,0),Color("d59c53"))
		tip.mesh.top_radius=0.05
	for y in [-0.65,0.65]: S.box(root,Vector3(3.1,0.19,0.15),Vector3(0,y,0.23),Color("85522d"))
	return root

static func bridge(parent: Node3D, at: Vector3, rotate := false) -> void:
	# Decks follow the authoritative dry crossing; actors stay on the existing walk plane.
	var root := Node3D.new()
	parent.add_child(root)
	root.position=at
	if rotate: root.rotation.y=PI/2
	for i in range(20):
		D.polygon_block(root,Vector3(5.1,0.14,0.36),Vector3(0,0.06,-3.8+i*0.4),Color("bf8b48").lightened((i%3)*0.035),.04)
		for side in [-1,1]:
			S.cylinder(root,.035,.02,Vector3(side*2.1,.14,-3.8+i*.4),Color("72573f"))
	for side in [-1,1]:
		for i in range(5):
			S.cylinder(root,0.11,0.8,Vector3(side*2.42,0.45,-3.6+i*1.8),Color("926134"))
		for j in range(4):
			for k in range(5):
				var a := -3.6+j*1.8+k*.36
				var b := a+.36
				D.beam(root,Vector3(side*2.42,.76-sin(k*PI/5)*.15,a),Vector3(side*2.42,.76-sin((k+1)*PI/5)*.15,b),.035,Color("d6b477"))
		D.beam(root,Vector3(side*2.30,-2.45,-3.0),Vector3(side*2.30,.05,-3.0),.14,Color("967043"))
		D.beam(root,Vector3(side*2.30,-2.45,3.0),Vector3(side*2.30,.05,3.0),.14,Color("967043"))

static func landscape(parent: Node3D, world: Dictionary, mask: Texture2D = null) -> void:
	if mask==null: mask=water_mask(world)
	river(parent,world,mask)
	# Waterfall sits inside existing blocked river cells; no new collision footprint.
	if mask.get_image().get_pixel(65,35).r>.5:
		var falls := MeshInstance3D.new()
		var curtain := QuadMesh.new()
		curtain.size=Vector2(2.7,4.7)
		falls.mesh=curtain
		falls.position=Vector3(13,.10,7)
		var falling_material := ShaderMaterial.new()
		falling_material.shader=Falls
		falls.material_override=falling_material
		parent.add_child(falls)
		for side in [-1,1]:
			D.polygon_block(parent,Vector3(1.5,4.9,2.0),Vector3(13+side*2.0,.1,7),Color("a29bb7"),.3)
		for i in range(9):
			D.leaf(parent,Vector3(11.6+i*.35,-2.03,7.20+sin(i)*.3),Vector3(.68,.18,.62),Color("d3f7f5"))
	var rng := RandomNumberGenerator.new()
	rng.seed=14673
	bridge(parent,Vector3(50,0,84+sin(50*0.07)*4))
	bridge(parent,Vector3(10.5+cos(50*0.095)*2.5,0,50),true)
	# Edge foliage frames the scene without adding non-authoritative blocking trees.
	for i in range(460):
		var at := Vector3(rng.randf_range(5,98),0,rng.randf_range(5,98))
		if at.distance_to(Vector3(50,0,50))<6 or absf(at.x-50)<2.2 or absf(at.z-50)<2.2: continue
		if blocked_or_stream(world,at): continue
		for j in range(3):
			D.leaf(parent,at+Vector3(j*0.22,0.15,0),Vector3(0.5,0.35,0.5),Color("73bf32"))
		if i%8==0:
			D.timber_log(parent,at+Vector3(0,-.06,0),1.4,.15)
		elif i%7==0:
			S.cylinder(parent,.21,.25,at+Vector3(0,.125,0),Color("b37a3d"))
			S.cylinder(parent,.18,.025,at+Vector3(0,.263,0),Color("e8c084"))
		if i%3==0:
			for j in range(3):
				S.cylinder(parent,0.035,0.38,at+Vector3(j*0.16,0.19,0.3),Color("49a746"))
				blob(parent,at+Vector3(j*0.16,0.42,0.3),Vector3(0.18,0.15,0.18),Color("e3b0eb") if i%2==0 else Color("ffdb58"))
		for j in range(3):
			var grass := S.cylinder(parent,.095,.38,at+Vector3(.40+j*.10,.19,.28),Color("6aaf30"))
			grass.mesh.top_radius=0
			grass.rotation.z=(j-1)*.38
	# Small sunk bank stones, no impassable-looking boulders on clear walking ground.
	for i in range(35):
		var z := 8.0+i*2.5
		var x := 10.5+cos(z*0.095)*2.5
		for side in [-1,1]:
			var at := Vector3(x+side*3.4,-0.5,z)
			if blocked_or_stream(world,at,false): continue
			if absf(z-50)<4: continue
			rock(parent,at,Vector3(1.7,1.7+(i%3)*0.15,1.9))

static func blocked_or_stream(world: Dictionary, at: Vector3, check_water := true) -> bool:
	if check_water and (absf(at.x-(10.5+cos(at.z*0.095)*2.5))<4 or absf(at.z-(84+sin(at.x*0.07)*4))<4): return true
	for o in world.get("obstacles",[]):
		if absf(at.x-o.x)<o.sx+2 and absf(at.z-o.y)<o.sy+2: return true
	for r in world.get("resources",[]):
		if Vector2(at.x-r.x,at.z-r.y).length()<2: return true
	for b in world.get("walls",[]):
		if Vector2(at.x-b.x,at.z-b.y).length()<5: return true
	return false

static func water_mask(world: Dictionary) -> Texture2D:
	var image := Image.create(500,500,false,Image.FORMAT_R8)
	image.fill(Color.BLACK)
	for obstacle in world.get("obstacles",[]):
		if obstacle.get("scenery", "")!="forest-water": continue
		var left := clampi(roundi((obstacle.x-obstacle.sx)*5),0,499)
		var right := clampi(roundi((obstacle.x+obstacle.sx)*5),0,500)
		var top := clampi(roundi((obstacle.y-obstacle.sy)*5),0,499)
		var bottom := clampi(roundi((obstacle.y+obstacle.sy)*5),0,500)
		for y in range(top,bottom):
			for x in range(left,right): image.set_pixel(x,y,Color.WHITE)
	return ImageTexture.create_from_image(image)

static func river(parent: Node3D, world: Dictionary, mask: Texture2D) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(100,100)
	water.mesh=plane
	water.position=Vector3(50,-2.20,50)
	var material := ShaderMaterial.new()
	material.shader=Water
	material.set_shader_parameter("river_mask",mask)
	water.material_override=material
	parent.add_child(water)
	var cells := {}
	for obstacle in world.get("obstacles",[]):
		if obstacle.get("scenery", "")!="forest-water": continue
		var row := roundi((obstacle.y-5)/2)
		for col in range(roundi((obstacle.x-obstacle.sx-4)/2),roundi((obstacle.x+obstacle.sx-4)/2)):
			cells[Vector2i(col,row)]=true
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for cell in cells:
		var center := Vector3(5+cell.x*2,0,5+cell.y*2)
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(cell+step): continue
			var outward := Vector3(-step.x,0,-step.y)
			var tangent := Vector3(step.y,0,-step.x)
			var mid := center+Vector3(step.x,0,step.y)
			var a := mid-tangent
			var b := mid+tangent
			var jitter := .12+absf(sin(center.x*.7+center.z))*0.18
			var p0 := a+Vector3(0,.04,0)
			var p1 := b+Vector3(0,.04,0)
			var p2 := a+outward*jitter+Vector3(0,-.8,0)
			var p3 := b+outward*jitter+Vector3(0,-.8,0)
			var p4 := a+Vector3(0,-2.8,0)
			var p5 := b+Vector3(0,-2.8,0)
			var stone_size := Vector3(.65,2.85,1.96) if step.x!=0 else Vector3(1.96,2.85,.65)
			D.polygon_block(parent,stone_size,mid+outward*.25+Vector3(0,-1.28+sin(center.z+center.x)*.11,0),Color("a6a0b7").lightened((cell.x%3)*.025),.18)
			for p in [p0,p2,p1,p1,p2,p3,p2,p4,p3,p3,p4,p5]:
				vertices.append(p)
				normals.append(outward)
				colors.append(Color("b6b1c2").darkened(clampf(-p.y/6,0,.5)).lightened((cell.x%3)*.015))
	if vertices.size()>0:
		var cliff := D.mesh(parent,vertices,normals,colors)
		cliff.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	# Faceted boundary cliffs replace the rectangular grey wall along the forest edge.
	for i in range(34):
		for side in range(2):
			var at := Vector3(.4,-.35,2+i*3) if side==0 else Vector3(2+i*3,-.35,.4)
			D.polygon_block(parent,Vector3(3.7,3.9,3.7),at,Color("a2a3b8").lightened((i%3)*.055),.45)

static func obstacle(parent: Node3D, data: Dictionary) -> void:
	var center := Vector3(data.x,0,data.y)
	if data.get("scenery", "")=="forest-water": return
	if data.get("scenery", "") in ["forest-workshop","forest-garden","forest-tank","forest-tent","forest-cave","forest-mine","forest-watermill"]:
		var set_root := Node3D.new()
		parent.add_child(set_root)
		set_root.position=center
		var collider := S.box(set_root,Vector3(data.sx*2,3.5,data.sy*2),Vector3(0,1.75,0),Color.WHITE,true)
		collider.visible=false
		match data.scenery:
			"forest-workshop": D.hut(set_root,float(data.sx)*2,float(data.sy)*2)
			"forest-watermill": D.hut(set_root,float(data.sx)*2,float(data.sy)*2,true)
			"forest-garden": D.crops(set_root,float(data.sx)*2,float(data.sy)*2)
			"forest-tank": D.tank(set_root)
			"forest-tent": D.tent(set_root,float(data.sx)*2,float(data.sy)*2)
			"forest-cave": D.cave(set_root)
			"forest-mine": D.cave(set_root,true)
		return
	if data.get("scenery", "")=="forest-fence":
		# This scenery segment uses its server rectangle, unlike player-owned modular walls.
		var fence := Node3D.new()
		parent.add_child(fence)
		fence.position=center
		if data.sy>data.sx: fence.rotation.y=PI/2
		for i in range(8):
			var x := -1.4+i*0.4
			S.cylinder(fence,0.18,1.8,Vector3(x,0.9,0),Color("bd853e").lightened((i%3)*0.035))
			for side in [-1,1]:
				S.box(fence,Vector3(.025,1.25,.018),Vector3(x+side*.07,.90,.176),Color("aa7237"))
			var tip := S.cylinder(fence,0.18,0.27,Vector3(x,1.94,0),Color("d9a657"))
			tip.mesh.top_radius=0.0
		S.box(fence,Vector3(3.2,0.18,0.16),Vector3(0,0.65,0.2),Color("82542d"))
		S.box(fence,Vector3(3.2,0.12,0.16),Vector3(0,1.35,0.2),Color("9a622e"))
		lantern(fence,Vector3(0,1.38,0))
		var hit := S.box(parent,Vector3(data.sx*2,2.4,data.sy*2),center+Vector3(0,1.2,0),Color.WHITE,true)
		hit.visible=false
		return
	var collider := S.box(parent,Vector3(data.sx*2,3.5,data.sy*2),center+Vector3(0,1.75,0),Color.WHITE,true)
	collider.visible=false
	if data.get("scenery", "")=="forest-tower":
		for dx in [-0.7,0.7]:
			for dz in [-0.7,0.7]: S.box(parent,Vector3(0.24,3.2,0.24),center+Vector3(dx,1.6,dz),Color("b27a3b"))
		for side in [-1,1]:
			var brace := S.box(parent,Vector3(1.95,0.17,0.17),center+Vector3(0,1.3,side*0.7),Color("d19b51"))
			brace.rotation.z=side*0.75
		S.box(parent,Vector3(2,0.25,2),center+Vector3(0,2.85,0),Color("d2a45c"))
		for side in [-1,1]:
			S.box(parent,Vector3(2,0.44,0.16),center+Vector3(0,3.1,side*0.86),Color("a9773b"))
			S.box(parent,Vector3(0.16,0.44,2),center+Vector3(side*0.86,3.1,0),Color("a9773b"))
		S.cylinder(parent,0.58,0.65,center+Vector3(0,3.4,0),Color("6b8497"))
		S.cylinder(parent,0.75,0.15,center+Vector3(0,3.81,0),Color("eee2b8"))
		lantern(parent,center+Vector3(0,3.7,0))
		for i in range(9): D.beam(parent,center+Vector3(-.26,.30+i*.29,.84),center+Vector3(.26,.30+i*.29,.84),.045,Color("e3b86c"))
		for side in [-1,1]: D.beam(parent,center+Vector3(side*.27,.05,.84),center+Vector3(side*.27,2.96,.84),.055,Color("cfa254"))
		return
	if data.get("scenery", "")=="forest-tree":
		var rng := RandomNumberGenerator.new()
		rng.seed=hash(str(data.id))
		tree(parent,center,rng)
		return
	if not str(data.id).ends_with("-ruin"):
		for i in range(5):
			var size := Vector3(data.sx*(1.7+(i%2)*.2),2.6+(i%3)*.6,data.sy*.43)
			rock(parent,center+Vector3((i%2-.5)*.25,size.y*.5,-data.sy*.78+i*data.sy*.39),size)
		return
	var detailed := Node3D.new()
	parent.add_child(detailed)
	detailed.position=center
	D.hut(detailed,float(data.sx)*2,float(data.sy)*2)
	lantern(detailed,Vector3(1.25,0.45,data.sy+0.05))
	var title := Node3D.new()
	parent.add_child(title)
	title.position=center
	S.label(title,"SUMINISTROS · V",3.2,Color("ffefba")).font_size=23

static func dress_building(root: Node3D, kind: String, width: float, depth: float) -> void:
	# Existing buildings only: the catalogue, prices and interaction footprints are unchanged.
	if kind in ["shelter","workshop","infirmary","storage","kitchen"]:
		var body_width := width*0.86
		var body_depth := depth*0.86
		S.box(root,Vector3(body_width,1.5,body_depth),Vector3(0,0.75,0),Color("e7cf99"))
		var roof := MeshInstance3D.new()
		var shape := PrismMesh.new()
		shape.size=Vector3(width*0.96,0.80,depth*0.96)
		roof.mesh=shape
		roof.position.y=1.88
		roof.material_override=S.material(Color("428fcb") if kind!="infirmary" else Color("e8c967"))
		root.add_child(roof)
		for side in [-1,1]:
			S.box(root,Vector3(0.22,1.7,0.22),Vector3(side*body_width*0.46,0.85,body_depth*0.46),Color("b47a3d"))
		S.box(root,Vector3(body_width*0.3,1.28,0.08),Vector3(0,0.65,body_depth*0.5+0.03),Color("745130"))
		S.box(root,Vector3(body_width*0.3,0.55,0.09),Vector3(body_width*0.3,1.05,body_depth*0.5+0.03),Color("ffbb4d"))
		S.box(root,Vector3(0.80,0.48,0.12),Vector3(0,1.89,body_depth*0.5+0.06),Color("fff0c2"))
		if kind=="infirmary":
			S.box(root,Vector3(0.40,0.12,0.06),Vector3(0,1.90,body_depth*0.5+0.14),Color("e65d4e"))
			S.box(root,Vector3(0.12,0.35,0.06),Vector3(0,1.90,body_depth*0.5+0.14),Color("e65d4e"))
		else:
			var badge := S.cylinder(root,0.15,0.05,Vector3(0,1.89,body_depth*0.5+0.14),Color("617c8b"))
			badge.rotation.x=PI/2
	elif kind=="garden":
		for side in [-1,1]:
			S.box(root,Vector3(width,0.13,0.12),Vector3(0,0.30,side*depth*0.48),Color("c3904a"))
			S.box(root,Vector3(0.12,0.13,depth),Vector3(side*width*0.48,0.30,0),Color("c3904a"))
		for i in range(9):
			var at := Vector3((i%3-1)*width*0.28,0.50,(i/3-1)*depth*0.28)
			blob(root,at,Vector3(0.5,0.5,0.5),Color("60bd38"))
			blob(root,at+Vector3(0.12,0.12,0.12),Vector3(0.25,0.26,0.25),Color("ff962f"))
	elif kind=="raincollector":
		S.cylinder(root,0.78,1.35,Vector3(0,0.75,0),Color("208fd2"))
		for y in [0.3,1.0,1.43]: S.cylinder(root,0.81,0.10,Vector3(0,y,0),Color("72cae7"))
	elif kind=="gate":
		for side in [-1,1]:
			S.box(root,Vector3(0.30,2.5,0.38),Vector3(side*1.45,1.25,0),Color("bc873f"))

static func landmark(parent: Node3D, data: Dictionary) -> void:
	var root := Node3D.new()
	root.position=Vector3(data.x,0,data.y)
	parent.add_child(root)
	var width := float(data.sx)*2
	var depth := float(data.sy)*2
	var collider := S.box(root,Vector3(width,2.2,depth),Vector3(0,1.1,0),Color.WHITE,true)
	collider.visible=false
	var vertical := depth>width
	var length := depth if vertical else width
	var count := maxi(1,ceili(length/1.0))
	for row in range(4):
		for col in range(count):
			var along := -length*.5+(col+.5)*length/count
			var size := Vector3(width,.52,depth/count-.035) if vertical else Vector3(width/count-.035,.52,depth)
			var at := Vector3(0,.29+row*.54,along) if vertical else Vector3(along,.29+row*.54,0)
			D.polygon_block(root,size,at,Color("b0abb9").lightened(((row+col)%3)*.035),.055)
	D.polygon_block(root,Vector3(width+.08,.18,depth+.08),Vector3(0,2.23,0),Color("dfc998"),.055)
	for side in [-1,1]:
		var at := Vector3(0,0,side*(depth*.5-.16)) if vertical else Vector3(side*(width*.5-.16),0,0)
		D.polygon_block(root,Vector3(.27,2.54,.27),at+Vector3(0,1.27,0),Color("a77940"),.04)
		lantern(root,at+Vector3(0,2.35,0))
