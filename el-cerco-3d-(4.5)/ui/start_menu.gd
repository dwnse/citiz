extends Control
# Artwork supplied by the user. Native buttons retain the existing HUD callbacks.
const ART = preload("res://assets/ui/start_menu.png")
const ART_SIZE = Vector2(1672, 941)
var frame := Control.new()
var selection := PanelContainer.new()
var message := Label.new()
var continue_button: Button
var reconnect_button: Button
var exit_button: Button
var home_buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	frame.size = ART_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = ART_SIZE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	resized.connect(fit_art)
	fit_art()

func fit_art() -> void:
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	frame.scale = Vector2.ONE * factor
	frame.position = (size - ART_SIZE * factor) * 0.5

func hit_button(id: String, rect: Rect2, callback: Callable, hint: String) -> Button:
	var b := Button.new()
	b.name = id
	b.text = id
	b.tooltip_text = hint
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color(0, 0, 0, 0)
		skin.set_corner_radius_all(5)
		if state == "hover":
			skin.bg_color = Color(1.0, 0.84, 0.28, 0.12)
			skin.border_color = Color("e5cc65")
			skin.set_border_width_all(2)
		elif state == "pressed":
			skin.bg_color = Color(0, 0, 0, 0.28)
			skin.border_color = Color("f8dc72")
			skin.set_border_width_all(2)
		elif state == "focus":
			skin.border_color = Color("fff0b0")
			skin.set_border_width_all(3)
		elif state == "disabled":
			skin.bg_color = Color.TRANSPARENT
		b.add_theme_stylebox_override(state, skin)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]:
		b.add_theme_color_override(state, Color.TRANSPARENT)
	b.pressed.connect(callback)
	frame.add_child(b)
	home_buttons.append(b)
	return b

func show_selection() -> void:
	selection.show()

func set_connection_available(available: bool) -> void:
	continue_button.disabled = not available
	reconnect_button.disabled = not available

func install_status() -> void:
	# Cover the caption baked into the reference with the real connection status.
	var plate := PanelContainer.new()
	plate.position = Vector2(596, 856)
	plate.custom_minimum_size = Vector2(480, 42)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("080908")
	skin.set_corner_radius_all(10)
	skin.content_margin_left = 10
	skin.content_margin_right = 10
	skin.content_margin_top = 6
	skin.content_margin_bottom = 6
	plate.add_theme_stylebox_override("panel", skin)
	frame.add_child(plate)
	message.custom_minimum_size.x = 460
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 17)
	message.add_theme_color_override("font_color", Color("fff9e9"))
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(message)

func set_status(value: String) -> void:
	message.text = value if not value.is_empty() else "Elige una partida para jugar."
	message.get_parent().visible = not selection.visible
func set_modal_open(open: bool) -> void:
	for button in home_buttons:
		if open and button.has_focus():
			button.release_focus()
		button.visible = not open