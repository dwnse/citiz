extends RefCounted
const Shapes = preload("res://world/shapes.gd")
const Art = preload("res://world/art.gd")
const Placement = preload("res://building/placement.gd")

static func create(parent: Node3D, w: Dictionary, b: Dictionary) -> Node3D:
	var d := Placement.definition(w,b.get("kind","wall"))
	if b.get("kind","wall") == "wall":
		var h := Placement.half(w,b)
		return Art.wall(parent,Vector3(h.x*2,d.height,h.y*2),Vector3(b.x,d.height/2,b.y))
	var root := Node3D.new()
	parent.add_child(root)
	root.position=Vector3(b.x,0,b.y)
	root.rotation.y=PI/2 if b.get("rot",0)==1 else 0
	var solid: bool = not (b.kind=="spikes" or b.kind=="gate" and b.get("open",false))
	if solid:
		var collider := Shapes.box(root,Vector3(d.width,d.height,d.depth),Vector3(0,d.height/2,0),Color.WHITE,true)
		collider.visible=false
	match b.kind:
		"shelter":
			Shapes.box(root,Vector3(2.8,1.8,2.8),Vector3(0,0.9,0),Color("768873"))
			Shapes.box(root,Vector3(3.2,0.2,3.2),Vector3(0,1.9,0),Color("405c64"))
			Shapes.box(root,Vector3(0.8,1.4,0.1),Vector3(0,0.7,-1.43),Color("263b40"))
		"sawmill":
			for side in [-1,1]: Shapes.cylinder(root,0.45,1.4,Vector3(side*0.7,0.7,0),Color("8b704f"))
			Shapes.box(root,Vector3(2.8,0.2,1.8),Vector3(0,1.5,0),Color("668789"))
		"quarry":
			for i in range(3): Art.stone(root,Vector3(-0.8+i*0.8,0.6,0),Vector3(0.9,1.2,1.3),Color("8d9c9d"))
			Shapes.box(root,Vector3(0.2,2,0.2),Vector3(0,1,0.6),Color("c9a25e"))
		"laboratory":
			Shapes.cylinder(root,1.1,0.7,Vector3(0,0.35,0),Color("435d65"))
			Shapes.cylinder(root,0.5,1.5,Vector3(0,1.1,0),Color("77c8cb"))
			for side in [-1,1]: Shapes.box(root,Vector3(0.25,2.2,0.25),Vector3(side*1,1.1,0),Color("b4a77d"))
		"turret":
			Shapes.cylinder(root,0.9,0.35,Vector3(0,0.2,0),Color("637079"))
			Shapes.cylinder(root,0.2,1.5,Vector3(0,0.9,0),Color("505e65"))
			var head := Node3D.new()
			head.name="TurretHead"
			root.add_child(head)
			Shapes.box(head,Vector3(1.2,0.5,0.7),Vector3(0,1.8,0),Color("6b8275"))
			Shapes.box(head,Vector3(1.2,0.16,0.16),Vector3(0.9,1.8,0),Color("303b40"))
		"generator":
			Shapes.box(root,Vector3(1.8,1,1.5),Vector3(0,0.5,0),Color("c59f55"))
			for x in [-0.5,0,0.5]: Shapes.box(root,Vector3(0.13,0.75,1.55),Vector3(x,0.55,0),Color("485657"))
			Shapes.cylinder(root,0.1,1.7,Vector3(0.7,0.85,0.5),Color("58646a"))
		"recycler":
			Shapes.box(root,Vector3(2.3,1.4,2),Vector3(0,0.7,0),Color("507e78"))
			Shapes.box(root,Vector3(1.5,0.12,1.2),Vector3(0,1.45,0),Color("263638"))
		"kitchen":
			Shapes.box(root,Vector3(2.6,1,1.6),Vector3(0,0.5,0),Color("b0b6a6"))
			for x in [-0.65,0.65]: Shapes.cylinder(root,0.35,0.45,Vector3(x,1.2,0),Color("414e51"))
		"raincollector":
			Shapes.cylinder(root,0.85,1.2,Vector3(0,0.6,0),Color("466f87"))
			Shapes.cylinder(root,0.74,0.05,Vector3(0,1.23,0),Color("76b8ce"))
		"sandbag":
			for row in range(2):
				for i in range(4): Art.stone(root,Vector3(-1.2+i*0.8,0.25+row*0.42,0),Vector3(0.82,0.52,1.1),Color("a49a73"))
		"gate":
			for side in [-1,1]:
				Shapes.box(root,Vector3(0.24,2.4,0.4),Vector3(side*1.48,1.2,0),Color("697369"))
			var leaf := Shapes.box(root,Vector3(2.7,2.1,0.18),Vector3(0,1.15,0),Color("86794e"))
			leaf.visible=not b.get("open",false)
		"spikes":
			for i in range(7):
				var spike := Shapes.cylinder(root,0.13,0.7,Vector3(-1.3+i*0.43,0.35,0),Color("786b4b"))
				spike.mesh.top_radius=0
		"well":
			Shapes.cylinder(root,1.2,0.8,Vector3(0,0.4,0),Color("70786e"))
			Shapes.cylinder(root,0.9,0.07,Vector3(0,0.84,0),Color("478699"))
		"garden":
			Shapes.box(root,Vector3(3.2,0.2,3.2),Vector3(0,0.1,0),Color("655036"))
			for i in range(9):
				Shapes.box(root,Vector3(0.35,0.4,0.35),Vector3(-1+i%3,0.35,-1+i/3),Color("65833f"))
		"infirmary":
			Shapes.box(root,Vector3(2.6,0.6,1.4),Vector3(0,0.6,0),Color("bbc7b8"))
			Shapes.box(root,Vector3(0.75,0.08,0.23),Vector3(0,0.94,0),Color("b95651"))
			Shapes.box(root,Vector3(0.23,0.08,0.75),Vector3(0,0.94,0),Color("b95651"))
		"workshop":
			Shapes.box(root,Vector3(2.8,0.3,1.8),Vector3(0,1.1,0),Color("92714e"))
			Shapes.box(root,Vector3(0.5,0.4,0.7),Vector3(0,1.45,0),Color("637478"))
			for side in [-1,1]:
				Shapes.box(root,Vector3(0.2,1,1.5),Vector3(side*1.1,0.5,0),Color("595244"))
		"storage":
			for side in [-1,1]:
				Art.crate(root,Vector3(side*0.7,0,0))
			Art.crate(root,Vector3(0,0.6,0))
	var caption := Shapes.label(root,d.name,2.9,Color("d8dfc9"))
	caption.font_size=30
	return root

static func grid(parent: Node3D, center: Vector3, radius: float) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color(0.5,0.8,1,0.25))
	var cells := int(radius/0.8)
	for i in range(-cells,cells+1):
		var offset := i*0.8
		var edge := sqrt(maxf(0,radius*radius-offset*offset))
		mesh.surface_add_vertex(center+Vector3(offset,0.12,-edge))
		mesh.surface_add_vertex(center+Vector3(offset,0.12,edge))
		mesh.surface_add_vertex(center+Vector3(-edge,0.12,offset))
		mesh.surface_add_vertex(center+Vector3(edge,0.12,offset))
	for ring in [radius,4.0]:
		mesh.surface_set_color(Color(0.2,0.85,1,1) if ring==radius else Color(1,0.3,0.2,1))
		for i in range(128):
			var a := i*TAU/128
			var b := (i+1)*TAU/128
			mesh.surface_add_vertex(center+Vector3(cos(a)*ring,0.16,sin(a)*ring))
			mesh.surface_add_vertex(center+Vector3(cos(b)*ring,0.16,sin(b)*ring))
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=Shapes.material(Color(1,1,1,0.8))
	node.material_override.vertex_color_use_as_albedo=true
	node.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	parent.add_child(node)
	return node
