extends Camera3D
@export var offset := Vector3(18, 30, 26)
@export var smoothing := 7.0
var focus := Vector3(50, 0, 58)
func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 32
	far = 450
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=144
	position = focus + offset
	look_at(focus)
func _process(delta: float) -> void:
	position = position.lerp(focus + offset, 1 - exp(-smoothing * delta))
	# Fixed orientation keeps WASD aligned with screen directions.
func ground_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	return point_from_screen(mouse)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: size=maxf(22,size-2)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: size=minf(48,size+2)

func point_from_screen(mouse: Vector2) -> Vector3:
	var hit = Plane(Vector3.UP, 0).intersects_ray(project_ray_origin(mouse), project_ray_normal(mouse))
	return hit if hit != null else focus
