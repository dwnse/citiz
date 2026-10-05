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
	var caption := S.label(root,str(site.name)+" · E",4.7,Color("9cebd6"))
	caption.name="SiteLabel"
	caption.font_size=23
