extends RefCounted
## Geometry is intentionally simple and replaceable with imported models.
static func material(color: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	return mat

static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color, collision := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = at
	parent.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		var hit := CollisionShape3D.new()
		var volume := BoxShape3D.new()
		volume.size = size
		hit.shape = volume
		body.add_child(hit)
		mesh.add_child(body)
	return mesh

static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: Color, collision := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 10
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = material(color)
	parent.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		var hit := CollisionShape3D.new()
		var volume := CylinderShape3D.new()
		volume.radius = radius
		volume.height = height
		hit.shape = volume
		body.add_child(hit)
		mesh.add_child(body)
	return mesh

static func label(parent: Node3D, text: String, height := 3.1, color := Color.WHITE) -> Label3D:
	var title := Label3D.new()
	title.text = text
	title.position.y = height
	title.font_size = 48
	title.pixel_size = 0.018
	title.modulate = color
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(title)
	return title
