extends RefCounted
const S = preload("res://world/shapes.gd")
const Art = preload("res://world/art.gd")

static func create(root: Node3D, site: Dictionary) -> void:
	var color: Color = {"hospital":Color("b0bca1"),"station":Color("ac8751"),"laboratory":Color("487c80")}.get(site.kind,Color.GRAY)
	S.box(root,Vector3(9,0.08,9),Vector3(0,0.03,0),color.darkened(0.55))
	# Painted routes connect both open entrances and keep the objective readable.
	for z in [-4,-2,0,2,4]:
		S.box(root,Vector3(0.18,0.02,0.8),Vector3(0,0.085,z),color.lightened(0.2))
	S.cylinder(root,0.12,4,Vector3(2,2,-3),Color("4c5955"))
	S.box(root,Vector3(2.7,1,0.12),Vector3(2,3.5,-3),color)
	if site.kind=="hospital":
		for side in [-1,1]:
			S.box(root,Vector3(0.23,0.7,0.15),Vector3(2,3.5,-3+side*0.1),Color("923e39"))
			S.box(root,Vector3(0.7,0.23,0.15),Vector3(2,3.5,-3+side*0.1),Color("923e39"))
		for x in [-2.5,2.5]:
			S.box(root,Vector3(1.1,0.02,2.1),Vector3(x,0.09,1),Color("bcb69c"))
	elif site.kind=="station":
		for x in [-0.7,0.7]:
			S.cylinder(root,0.13,0.1,Vector3(x,0.13,1.8),Color("80b4bc"))
		S.box(root,Vector3(2,0.03,1),Vector3(0,0.1,2.4),Color("354b50"))
	else:
		S.box(root,Vector3(1.6,0.5,0.15),Vector3(2,3.5,-3.1),Color("65d5cd"))
		for i in range(3):
			S.box(root,Vector3(0.8,0.03,0.15),Vector3(-2.5,0.1,i-1),Color("5bbbbd"))
	Art.batch_static(root,true)
	if site.has("interior"):
		# Two visible rooms share authoritative walls; no roof obscures the player.
		for z in [-2.5,2.5]:
			S.box(root,Vector3(8.8,0.025,4.3),Vector3(0,0.09,z),color.darkened(0.25 if z<0 else 0.45))
		if site.kind=="hospital":
			for x in [-3,-1.5]:
				S.box(root,Vector3(0.9,0.55,1.8),Vector3(x,0.3,-3),Color("d1cbb4"))
				S.box(root,Vector3(0.7,0.12,0.45),Vector3(x,0.64,-3.5),Color("e4e1d3"))
		else:
			S.box(root,Vector3(2.4,0.9,0.7),Vector3(-2,0.5,-3.5),Color("48666a"))
			for x in [-2.7,-1.4]:
				S.box(root,Vector3(0.6,0.5,0.1),Vector3(x,1.1,-3.5),Color("67d8cc"))
		for key in ["entry","objective"]:
			var point: Dictionary = site.interior[key]
			var marker := Node3D.new()
			marker.name=key.capitalize()+"Marker"
			marker.position=Vector3(point.x-site.x,0.15,point.y-site.y)
			root.add_child(marker)
			S.cylinder(marker,0.7,0.05,Vector3.ZERO,Color("f0c778") if key=="entry" else Color("76e5cf"))
			if key=="objective":
				if site.kind=="hospital":
					S.box(marker,Vector3(0.4,0.6,0.3),Vector3(0,0.6,0),Color("b7aa85"))
					S.cylinder(marker,0.17,0.28,Vector3(0,1.03,0),Color("c49778"))
				else:
					S.box(marker,Vector3(0.75,1,0.45),Vector3(0,0.5,0),Color("35464e"))
					S.box(marker,Vector3(0.6,0.4,0.05),Vector3(0,0.8,0.25),Color("66dccb"))
			var sign := S.label(marker,("RADIO · E" if site.kind=="hospital" else "ENERGÍA · E") if key=="entry" else ("PACIENTE" if site.kind=="hospital" else "ARCHIVO"),1.5,Color("def0de"))
			sign.font_size=16
	var caption := S.label(root,str(site.name)+" · E",4.7,Color("9cebd6"))
	caption.name="SiteLabel"
	caption.font_size=23

static func update(root: Node3D,site: Dictionary) -> void:
	if not root.has_node("EntryMarker"): return
	var encounter = site.get("encounter")
	root.get_node("EntryMarker").visible=not encounter is Dictionary
	root.get_node("ObjectiveMarker").visible=encounter is Dictionary
