extends RefCounted
const S = preload("res://world/shapes.gd")
const Ground = preload("res://world/ground.gdshader")
const Forest = preload("res://world/forest.gd")
const Mountain = preload("res://world/mountain.gd")

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
	var forest_mask := Forest.water_mask(world)
	mat.set_shader_parameter("forest_water_mask",forest_mask)
	var mountain_mask := Mountain.water_mask(world)
	mat.set_shader_parameter("mountain_water_mask",mountain_mask)
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
			if c.id in ["forest","mountain"]: on_road = true # Clean cartoon grass is shaded directly on the floor.
			var scale := Vector3.ZERO if on_road else Vector3.ONE*rng.randf_range(0.7,1.6)
			grass.set_instance_transform(index,Transform3D(Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(scale),at))
			grass.set_instance_color(index,Color("89983f").darkened(rng.randf()*0.3))
			index += 1
		for i in range(55):
			if c.id in ["forest","mountain"]: continue
			var at := center+Vector3(rng.randf_range(-38,38),0,rng.randf_range(-38,38))
			if absf(at.x-c.x)<5 or absf(at.z-105)<5 or at.distance_to(center)<19:
				continue
			if i%3==0:
				stone(parent,at+Vector3(0,0.3,0),Vector3(1.4,0.6,1.3),Color("597334"))
			else:
				for cluster in range(4):
					var offset := Vector3(rng.randf_range(-0.7,0.7),0.45,rng.randf_range(-0.7,0.7))
					stone(parent,at+offset,Vector3(1.4,1,1.3),Color("597334").lightened(rng.randf()*0.1))
		for sign_x in [-1,1]:
			if c.id in ["forest","mountain"]: continue
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
	# Road markings and scattered low debris keep travel routes readable.
	for c in world.communities:
		for i in range(-8,9):
			if c.id in ["forest","mountain"]: continue
			var z := float(c.y)+i*5.0
			if z<3 or z>size-3: continue
			S.box(parent,Vector3(0.15,0.025,1.8),Vector3(c.x,0.025,z),Color("c3b882"))
		for i in range(32):
			if c.id in ["forest","mountain"]: continue
			var at := Vector3(c.x+rng.randf_range(-30,30),0.08,c.y+rng.randf_range(-30,30))
			if at.distance_to(Vector3(c.x,0,c.y))<19: continue
			var slab := S.box(parent,Vector3(rng.randf_range(0.4,1.5),0.1,rng.randf_range(0.3,0.7)),at,Color("74766a"))
			slab.rotation.y=rng.randf()*TAU
		if c.id in ["forest","mountain"]: continue
		var sign_at := Vector3(c.x+4.5,0,c.y+21)
		S.cylinder(parent,0.1,3,sign_at+Vector3(0,1.5,0),Color("687b79"))
		S.box(parent,Vector3(3,0.9,0.15),sign_at+Vector3(0,2.6,0),Color("284c47"))
		var sign_root := Node3D.new()
		parent.add_child(sign_root)
		sign_root.position=sign_at
		var label := S.label(sign_root,str(c.get("name","REFUGIO")),3.2)
		label.font_size=24
	Forest.landscape(parent,world,forest_mask)
	Mountain.landscape(parent,world,mountain_mask)

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
	batch_static(root,true)
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
	if data.has("landmark"):
		S.box(parent,Vector3(data.sx*2,2.2,data.sy*2),Vector3(data.x,1.1,data.y),Color("77877e"),true)
		S.box(parent,Vector3(data.sx*2+0.1,0.18,data.sy*2+0.1),Vector3(data.x,2.25,data.y),Color("b7ac83"))
		return
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
	if str(data.id).ends_with("-ruin"):
		# A roof, boarded windows and supplies fit inside the authoritative footprint.
		S.box(parent,Vector3(data.sx*2,0.2,data.sy*2),center+Vector3(0,3.6,0),Color("53606a"))
		for i in range(3):
			var at := center+Vector3((i-1)*data.sx*0.6,2.2,data.sy+0.02)
			S.box(parent,Vector3(1.2,0.95,0.08),at,Color("25353e"))
			var plank := S.box(parent,Vector3(1.35,0.17,0.12),at,Color("9b7955"))
			plank.rotation.z=0.3
		var root := Node3D.new()
		parent.add_child(root)
		root.position=center
		var label := S.label(root,"SUMINISTROS · V",4.5,Color("e7c887"))
		label.font_size=26
		S.cylinder(parent,0.65,1.2,center+Vector3(0,4.3,0),Color("6a7c7b"))

static func batch_static(parent: Node3D, local_group := false) -> void:
	for child in parent.get_children():
		if child is Node3D and not child is MeshInstance3D and not child is StaticBody3D:
			merge_rigid(child)
	var groups := {}
	for child in parent.get_children():
		if not child is MeshInstance3D or not child.visible or not child.material_override is StandardMaterial3D: continue
		var mat: StandardMaterial3D = child.material_override
		if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or mat.emission_enabled: continue
		var original: Mesh = child.mesh
		var scale := Vector3.ONE
		var kind := ""
		var geometry := ""
		var segments := 7
		var rings := 3
		var top_ratio := 1.0
		if original is BoxMesh:
			kind="box"
			scale=original.size
		elif original is SphereMesh:
			kind="sphere"
			scale=Vector3(original.radius*2,original.height,original.radius*2)
			segments=original.radial_segments
			rings=original.rings
			geometry="/%d/%d" % [segments,rings]
		elif original is CylinderMesh:
			if original.bottom_radius<=0: continue
			kind="cylinder"
			top_ratio=original.top_radius/original.bottom_radius
			segments=original.radial_segments
			geometry="/%0.4f/%d" % [top_ratio,segments]
			scale=Vector3(original.bottom_radius*2,original.height,original.bottom_radius*2)
		else: continue
		var key := kind+geometry if local_group else "%s%s/%d/%d" % [kind,geometry,floor(child.position.x/24),floor(child.position.z/24)]
		if not groups.has(key): groups[key]={"kind":kind,"items":[],"segments":segments,"rings":rings,"top_ratio":top_ratio}
		groups[key].items.append({"transform":Transform3D(child.transform.basis * Basis.from_scale(scale),child.position),"color":mat.albedo_color})
		child.visible=false
		if child.get_child_count()==0: child.queue_free()
	for group in groups.values():
		var mesh: Mesh
		if group.kind=="box":
			mesh=BoxMesh.new()
			mesh.size=Vector3.ONE
		elif group.kind=="sphere":
			mesh=SphereMesh.new()
			mesh.radius=0.5
			mesh.height=1
			mesh.radial_segments=group.segments
			mesh.rings=group.rings
		else:
			mesh=CylinderMesh.new()
			mesh.top_radius=0.5*group.top_ratio
			mesh.bottom_radius=0.5
			mesh.height=1
			mesh.radial_segments=group.segments
		var multi := MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.use_colors=true
		multi.mesh=mesh
		multi.instance_count=group.items.size()
		for i in range(group.items.size()):
			multi.set_instance_transform(i,group.items[i].transform)
			multi.set_instance_color(i,group.items[i].color)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh=multi
		var material := S.material(Color.WHITE)
		material.vertex_color_use_as_albedo=true
		material.vertex_color_is_srgb=false
		instance.material_override=material
		parent.add_child(instance)

static func merge_rigid(parent: Node3D) -> void:
	# One draw per animated body part, preserving each vertex's geometry and color.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for child in parent.get_children():
		if not child is MeshInstance3D or not child.visible or not child.material_override is StandardMaterial3D: continue
		var mat: StandardMaterial3D = child.material_override
		if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or mat.emission_enabled: continue
		if child.mesh.get_surface_count()!=1: continue
		var source: Array = child.mesh.surface_get_arrays(0)
		var points: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
		var source_normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
		var source_indices: PackedInt32Array = source[Mesh.ARRAY_INDEX] if source[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var source_colors: PackedColorArray = source[Mesh.ARRAY_COLOR] if source[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
		var base := vertices.size()
		var normal_basis: Basis = child.transform.basis.inverse().transposed()
		for i in range(points.size()):
			vertices.append(child.transform*points[i])
			normals.append((normal_basis*source_normals[i]).normalized())
			colors.append(source_colors[i]*mat.albedo_color if source_colors.size()==points.size() else mat.albedo_color)
		if source_indices.is_empty():
			for index in range(points.size()): indices.append(base+index)
		else:
			for index in source_indices: indices.append(base+index)
		child.visible=false
		if child.get_child_count()==0: child.queue_free()
	if vertices.is_empty(): return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new()
	instance.mesh=mesh
	var mat := S.material(Color.WHITE)
	mat.vertex_color_use_as_albedo=true
	mat.vertex_color_is_srgb=false
	instance.material_override=mat
	parent.add_child(instance)

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
