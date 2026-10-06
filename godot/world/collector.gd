extends RefCounted
const S = preload("res://world/shapes.gd")
const Art = preload("res://world/art.gd")

static func create(root: Node3D, room: Dictionary) -> void:
	S.box(root,Vector3(25,0.08,11),Vector3(0,0.03,0),Color("344449"))
	for i in range(11):
		S.box(root,Vector3(0.8,0.025,0.15),Vector3(-10+i*2,0.085,0),Color("b4a86d"))
	for side in [-1,1]:
		S.box(root,Vector3(24,0.13,0.18),Vector3(0,1,side*5.6),Color("718d8b"))
	Art.crate(root,Vector3(0,0,2))
	S.cylinder(root,0.5,0.2,Vector3(0,0.2,-3),Color("6ac3d0"))
	Art.batch_static(root,true)
	var gas := S.box(root,Vector3(24,0.04,10),Vector3(0,0.15,0),Color(0.72,0.63,0.23,0.22))
	gas.name="Gas"
	var title := S.label(root,room.name,3.8,Color("d7c399"))
	title.name="Title"
	title.font_size=24
	for entry in [["Valve",-3.0],["Cache",2.0]]:
		var marker := Node3D.new()
		marker.name=entry[0]
		marker.position=Vector3(0,0,entry[1])
		root.add_child(marker)
		var label := S.label(marker,"",1.9,Color("9fd6dc"))
		label.name="Label"
		label.font_size=20

static func update(root: Node3D, room: Dictionary) -> void:
	var now := Time.get_unix_time_from_system()*1000
	var safe: bool = room.get("purgedUntil",0)>now
	root.get_node("Gas").visible=not safe
	root.get_node("Valve/Label").text="VENTILACIÓN ACTIVA" if safe else "E · VENTILAR"
	var delay := maxi(0,int(ceil((float(room.cache.readyAt)-now)/1000)))
	root.get_node("Cache/Label").text="ARMARIO · %d s" % delay if delay>0 else ("E · SUMINISTROS" if safe else "ABRE LA VÁLVULA")
