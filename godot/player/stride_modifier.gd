extends SkeletonModifier3D
## Rotate the complete leg chain together, then preserve the upper body's pose.
## Feet are root siblings in this imported rig, so they must rotate explicitly.
var heading := 0.0
func _process_modification() -> void:
	if absf(heading)<0.001: return
	var rig := get_skeleton()
	var body := rig.find_bone("Body")
	var hips := rig.find_bone("Hips")
	var body_pose := rig.get_bone_global_pose(body)
	var upper_pose := rig.get_bone_global_pose(hips)
	var turn := Basis(Vector3.UP,heading)
	var feet := {}
	for name_ in ["Foot.L","Foot.R","PoleTarget.L","PoleTarget.R"]:
		var index := rig.find_bone(name_)
		feet[index]=rig.get_bone_global_pose(index)
	body_pose.basis=turn*body_pose.basis
	rig.set_bone_global_pose(body,body_pose)
	rig.set_bone_global_pose(hips,upper_pose)
	for index in feet:
		var pose: Transform3D = feet[index]
		pose.origin=body_pose.origin+turn*(pose.origin-body_pose.origin)
		pose.basis=turn*pose.basis
		rig.set_bone_global_pose(index,pose)
