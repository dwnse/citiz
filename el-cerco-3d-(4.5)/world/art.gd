extends RefCounted
const S = preload("res://world/shapes.gd")
const Ground = preload("res://world/ground.gdshader")

static func stone(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 7
	sphere.rings = 3
	sphere.radius = 0.5
	sphere.height = 1
	mesh.mesh = sphere
	mesh.scale = dimensions
	mesh.position = at
	mesh.material_override = S.material(color)
	parent.add_child(mesh)
	return mesh

static func tree(parent: Node3D, at: Vector3, rng: RandomNumberGenerator) -> void:
	S.cylinder(parent, 0.22, 3.5, at+Vector3(0,1.75,0), Color("675039"))
	for i in range(5):
		var offset := Vector3(rng.randf_range(-1,1),rng.randf_range(2.8,4.4),rng.randf_range(-1,1))
		stone(parent,at+offset,Vector3(2.5,2,2.4),Color("416443").lightened(rng.randf_range(-0.1,0.12)))

static func landscape(parent: Node3D, world: Dictionary) -> void:
	var size := float(world.size)
	var floor_mesh := S.box(parent,Vector3(size,0.4,size),Vector3(size/2,-0.2,size/2),Color.WHITE,true)
	var mat := ShaderMaterial.new()
	mat.shader = Ground
	floor_mesh.material_override = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = 8734
	# Batched low grass: density without thousands of independent draw calls.
	var grass := MultiMesh.new()
	grass.transform_format = MultiMesh.TRANSFORM_3D
	grass.use_colors = true
	var blade := PrismMesh.new()
	blade.size = Vector3(0.12,0.32,0.10)
	grass.mesh = blade
	grass.instance_count = world.communities.size()*1600
	var index := 0
	for c in world.communities:
		var center := Vector3(c.x,0,c.y)
		for i in range(1600):
			var at := center+Vector3(rng.randf_range(-42,42),0.16,rng.randf_range(-42,42))
			var on_road := absf(at.x-c.x)<4 or absf(at.z-105)<4 or at.distance_to(center)<5
			var scale := Vector3.ZERO if on_road else Vector3.ONE*rng.randf_range(0.7,1.6)
			grass.set_instance_transform(index,Transform3D(Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(scale),at))
			grass.set_instance_color(index,Color("89983f").darkened(rng.randf()*0.3))
			index += 1
		for i in range(55):
			var at := center+Vector3(rng.randf_range(-38,38),0,rng.randf_range(-38,38))
			if absf(at.x-c.x)<5 or absf(at.z-105)<5 or at.distance_to(center)<19:
				continue
			if i%3==0:
				tree(parent,at,rng)
			else:
				for cluster in range(4):
					var offset := Vector3(rng.randf_range(-0.7,0.7),0.45,rng.randf_range(-0.7,0.7))
					stone(parent,at+offset,Vector3(1.4,1,1.3),Color("597334").lightened(rng.randf()*0.1))
		for sign_x in [-1,1]:
			var post := center+Vector3(sign_x*3.5,0,5)
			S.box(parent,Vector3(0.65,3.7,0.65),post+Vector3(0,1.85,0),Color("73766c"))
			S.box(parent,Vector3(0.9,0.3,0.9),post+Vector3(0,3.7,0),Color("93978b"))
			var lantern := S.box(parent,Vector3(0.32,0.55,0.32),post+Vector3(0,4.15,0),Color("ffd085"))
			lantern.material_override = S.material(Color("ffd085"),true)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = grass
	var grass_mat := S.material(Color.WHITE)
	grass_mat.vertex_color_use_as_albedo = true
	instance.material_override = grass_mat
	parent.add_child(instance)

static func wall(parent: Node3D, dimensions: Vector3, at: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	if dimensions.z>dimensions.x:
		root.rotation.y=PI/2
	# Exact original gameplay collision underneath a dressed timber wall.
	var collider := S.box(root,Vector3(3.2,2.4,1.2),Vector3.ZERO,Color("69533c"),true)
	collider.visible=false
	for i in range(8):
		S.box(root,Vector3(0.37,2.3+(i%3)*0.08,0.22),Vector3(-1.4+i*0.4,0,0),Color("9b7850").darkened((i%3)*0.065))
	for side in [-1,1]:
		S.box(root,Vector3(0.35,2.65,0.6),Vector3(side*1.4,0,0),Color("737769"))
		S.box(root,Vector3(3.1,0.15,0.18),Vector3(0,side*0.76,-0.21),Color("4b4d45"))
	var brace := S.box(root,Vector3(2.9,0.17,0.2),Vector3(0,0,-0.32),Color("58462f"))
	brace.rotation.z=0.53
	return root

static func vault(parent: Node3D) -> void:
	S.cylinder(parent,2.2,0.65,Vector3(0,0.325,0),Color("71786e"),true)
	for i in range(8):
		var angle := i*TAU/8
		var at := Vector3(cos(angle)*1.75,0.7,sin(angle)*1.75)
		S.box(parent,Vector3(0.6,0.7,0.6),at,Color("919489"))
	S.cylinder(parent,1.2,0.5,Vector3(0,0.85,0),Color("3e5960"))
	var crystal := stone(parent,Vector3(0,2,0),Vector3(1.3,2.4,1.3),Color("47d8eb"))
	crystal.material_override=S.material(Color("35bcd9"),true)
	for i in range(4):
		var angle := i*TAU/4+PI/4
		S.cylinder(parent,0.10,2.7,Vector3(cos(angle)*1.25,1.6,sin(angle)*1.25),Color("536c72"))

static func obstacle(parent: Node3D, data: Dictionary) -> void:
	var center := Vector3(data.x,0,data.y)
	var collision := S.box(parent,Vector3(data.sx*2,3.5,data.sy*2),center+Vector3(0,1.75,0),Color.WHITE,true)
	collision.visible=false
	# Broken masonry keeps the obstacle's footprint legible.
	for row in range(4):
		for i in range(5):
			var across := -0.8+float(i)*0.4
			var at := center+Vector3(across*data.sx,0.42+row*0.8,0)
			var block := S.box(parent,Vector3(data.sx*0.39,0.76,data.sy*2),at,Color("8a8d77").darkened(float((i+row)%3)*0.06))
			if row==3:
				block.rotation.z=float(i%3-1)*0.09

static func crate(parent: Node3D, at: Vector3) -> void:
	S.box(parent,Vector3(0.8,0.6,0.8),at+Vector3(0,0.3,0),Color("927448"))
	for side in [-1,1]:
		S.box(parent,Vector3(0.08,0.65,0.83),at+Vector3(side*0.25,0.32,0),Color("4a5143"))

static func wreck(parent: Node3D, at: Vector3) -> void:
	S.box(parent,Vector3(2.5,0.7,1.6),at+Vector3(0,0.65,0),Color("646652"))
	S.box(parent,Vector3(1.1,0.65,1.4),at+Vector3(-0.35,1.22,0),Color("4a5957"))
	S.box(parent,Vector3(0.85,0.38,1.43),at+Vector3(-0.35,1.34,0),Color("293e40"))
	for x in [-0.85,0.85]:
		for z in [-0.75,0.75]:
			var wheel := S.cylinder(parent,0.35,0.18,at+Vector3(x,0.4,z),Color("292c29"))
			wheel.rotation.x=PI/2
