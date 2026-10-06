extends RefCounted

static func box(fill: Color, edge: Color, width: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_corner_radius_all(9)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color("050804dd")
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 4)
	return s

static func make_theme(font_size: int = 17) -> Theme:
	var t := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial", "DejaVu Sans"])
	font.font_weight = 800
	t.default_font = font
	t.default_font_size = font_size
	var panel := box(Color("182512fa"), Color("8b9345"), 4)
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 22
	panel.content_margin_bottom = 22
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "PopupMenu", box(Color("1b2815"), Color("d6b340")))
	t.set_stylebox("hover", "PopupMenu", box(Color("59632b"), Color("ffd752"), 2))
	for type in ["Label", "Button", "OptionButton", "CheckButton", "CheckBox", "LineEdit", "RichTextLabel", "PopupMenu"]:
		t.set_color("font_color", type, Color("fff3ce"))
		t.set_color("font_outline_color", type, Color("090d07"))
		t.set_constant("outline_size", type, 2)
		t.set_color("font_hover_color", type, Color("fff6ce"))
		t.set_color("font_pressed_color", type, Color("fff6ce"))
		t.set_color("font_focus_color", type, Color("fff6ce"))
		t.set_color("font_disabled_color", type, Color("93987a"))
	for type in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
		t.set_stylebox("normal", type, box(Color("3b4520"), Color("939b4b")))
		t.set_stylebox("hover", type, box(Color("58602a"), Color("ffdb58")))
		t.set_stylebox("pressed", type, box(Color("5e692b"), Color("ffdc57"), 4))
		t.set_stylebox("disabled", type, box(Color("26301d"), Color("535e37"), 2))
		var focus := box(Color.TRANSPARENT, Color("ffe684"), 2)
		focus.shadow_size = 0
		t.set_stylebox("focus", type, focus)
	t.set_stylebox("normal", "LineEdit", box(Color("111b0f"), Color("727f3c"), 2))
	t.set_stylebox("focus", "LineEdit", box(Color("17220f"), Color("ffcf46")))
	t.set_stylebox("normal", "RichTextLabel", box(Color("111c0dd9"), Color("485c2d"), 2))
	t.set_stylebox("slider", "HSlider", box(Color("0c150a"), Color("6d7839"), 2))
	t.set_stylebox("grabber_area", "HSlider", box(Color("dc9b17"), Color("ffdd5d"), 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(Color("f9bd29"), Color("ffe884"), 2))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 8)
	return t

static func accent(button: Button, color: String) -> void:
	var fill := Color(color)
	button.add_theme_stylebox_override("normal", box(fill, fill.lightened(0.4)))
	button.add_theme_stylebox_override("hover", box(fill.lightened(0.12), Color("ffe376"), 4))
	button.add_theme_stylebox_override("pressed", box(fill.darkened(0.15), Color("ffd14d"), 4))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func heading(label: Label, font_size: int = 28) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff0be"))
	label.add_theme_color_override("font_outline_color", Color("080c06"))
	label.add_theme_constant_override("outline_size", 4)

static func decorate(panel: PanelContainer, font_size: int = 17) -> void:
	panel.theme = make_theme(font_size)
	var trim := Trim.new()
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(trim)
	panel.visibility_changed.connect(func():
		if not panel.visible: return
		var previous = panel.get_meta("reveal_tween") if panel.has_meta("reveal_tween") else null
		if previous is Tween and previous.is_valid(): previous.kill()
		panel.modulate.a = 0.25
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		panel.set_meta("reveal_tween", tween)
	)

class Trim:
	extends Control
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		var corners := [Vector2(-19, -17), Vector2(size.x + 19, -17), Vector2(-19, size.y + 17), Vector2(size.x + 19, size.y + 17)]
		for i in range(4):
			var corner: Vector2 = corners[i]
			var direction := Vector2(1 if i % 2 == 0 else -1, 1 if i < 2 else -1)
			var points := PackedVector2Array()
			for point in [Vector2(0, 33), Vector2(0, 12), Vector2(12, 0), Vector2(48, 0), Vector2(48, 13), Vector2(21, 13), Vector2(13, 21), Vector2(13, 33)]:
				points.append(corner + point * direction)
			draw_colored_polygon(points, Color("dfa21c"))
			var outline := points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, Color("080c06"), 5, true)
			draw_polyline(outline, Color("ffd967"), 2, true)
			draw_circle(corner + Vector2(9, 13) * direction, 3, Color("614316"))

class Facets:
	extends Control
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		for i in range(9):
			var x := size.x * float(i) / 9.0
			var step := size.x / 9.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + step, 0), Vector2(x + step * 0.66, size.y * 0.6), Vector2(x + step * 0.12, size.y)]), Color(1, 0.94, 0.55, 0.055 if i % 2 == 0 else 0.025))

static func facets(button: Button) -> void:
	var surface := Facets.new()
	button.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
static func compact_theme() -> Theme:
	var t := make_theme(14)
	for widget in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style: StyleBoxFlat = t.get_stylebox(state, widget).duplicate()
			style.content_margin_left = 10
			style.content_margin_right = 10
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			t.set_stylebox(state, widget, style)
	var panel: StyleBoxFlat = t.get_stylebox("panel", "PanelContainer").duplicate()
	panel.content_margin_top = 16
	panel.content_margin_bottom = 16
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_constant("separation", "VBoxContainer", 8)
	return t