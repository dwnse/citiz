extends Control
const Palette = preload("res://ui/illustrated_theme.gd")
var hud: CanvasLayer
var last_world: Dictionary = {}
var last_player: Dictionary = {}
var tiles: Array[Dictionary] = []
var action_row := HBoxContainer.new()
var objective_card := PanelContainer.new()
var detail := Label.new()
var font := SystemFont.new()
var supply_row := HBoxContainer.new()
var supplies: Array[Dictionary] = []
var power_buttons: Dictionary = {}
var reload_button := Button.new()
var state_badge := Label.new()
var dock := Panel.new()
var building_mode := false
var cooldown_tick := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font.font_names = PackedStringArray(["Arial"])
	font.font_weight = 600
	resized.connect(layout)
	add_child(dock)
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_theme_stylebox_override("panel", plate())
	add_child(supply_row)
	supply_row.add_theme_constant_override("separation", 6)
	supply_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_row)
	action_row.add_theme_constant_override("separation", 6)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_card)
	objective_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_card.add_theme_stylebox_override("panel", plate())
	add_child(detail)
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", Color("f4e9c7"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(state_badge)
	state_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_badge.add_theme_font_size_override("font_size", 14)
	state_badge.add_theme_color_override("font_color", Color("ffe2a0"))
	layout()

func plate() -> StyleBoxFlat:
	var s := Palette.box(Color("11190ee8"), Color("aa925b"), 2)
	s.set_corner_radius_all(10)
	s.shadow_color = Color("00000080")
	s.shadow_size = 5
	s.border_color = Color("827349")
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s

func configure(owner_hud: CanvasLayer, old_hotbar: HBoxContainer) -> void:
	hud = owner_hud
	hud.objective.reparent(objective_card, false)
	var kinds := ["build", "tool", "build", "book", "pause"]
	var keys := ["B", "Q", "K", "J", "P"]
	var labels := ["Construir", "Equipo", "Bóveda", "Diario", "Pausa"]
	var index := 0
	for child in old_hotbar.get_children():
		if not child is Button: continue
		var b: Button = child
		b.reparent(action_row, false)
		style_button(b)
		b.clip_text = true
		b.custom_minimum_size = Vector2(74, 77)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			b.add_theme_color_override(state, Color.TRANSPARENT)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var skin := plate()
			if state == "hover": skin.border_color = Color("ffdc78")
			elif state == "pressed": skin.bg_color = Color("50401c")
			elif state == "disabled": skin.border_color = Color("575540")
			b.add_theme_stylebox_override(state, skin)
		var icon := Icon.new()
		icon.kind = kinds[index]
		icon.position = Vector2(17, 8)
		icon.size = Vector2(40, 40)
		b.add_child(icon)
		var caption := Label.new()
		caption.position = Vector2(0, 51)
		caption.size = Vector2(74, 22)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 11)
		caption.add_theme_color_override("font_color", Color("fff1c9"))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.text = labels[index]
		b.add_child(caption)
		var key := Label.new()
		key.text = keys[index]
		key.position = Vector2(5, 3)
		key.add_theme_font_size_override("font_size", 10)
		key.add_theme_color_override("font_color", Color("ffe198"))
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key)
		tiles.append({"button":b, "icon":icon, "caption":caption})
		index += 1
	for spec in [["medical", "N", "Botiquín", "hp", 30], ["water", "Y", "Agua", "thirst", 40], ["food", "H", "Comida", "hunger", 35]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 77)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_font_size_override("font_size", 11)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.text = "\n\n" + spec[1]
		style_button(b)
		var icon := Icon.new()
		icon.kind = spec[0]
		icon.position = Vector2(17, 11)
		icon.size = Vector2(30, 30)
		b.add_child(icon)
		b.pressed.connect(func(): hud.quick_action_requested.emit("consume", {"item": spec[0]}))
		supply_row.add_child(b)
		supplies.append({"button": b, "icon": icon, "spec": spec})
	reload_button.text = "R  RECARGAR"
	reload_button.custom_minimum_size = Vector2(140, 27)
	reload_button.add_theme_font_size_override("font_size", 10)
	style_button(reload_button)
	reload_button.pressed.connect(func(): hud.quick_action_requested.emit("reload", {}))
	add_child(reload_button)
	hud.minimap.reparent(self, false)
	hud.siege.reparent(self, false)
	layout()

func style_button(b: Button) -> void:
	b.mouse_entered.connect(func():
		if not b.disabled: b.modulate = Color(1.12, 1.10, 1.03)
	)
	b.mouse_exited.connect(func(): b.modulate = Color.WHITE)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var skin := plate()
		if state == "hover" or state == "focus":
			skin.border_color = Color("ffda7b")
			skin.bg_color = Color("39402aef")
		if state == "pressed": skin.bg_color = Color("65512b")
		if state == "disabled": skin.border_color = Color("454936")
		b.add_theme_stylebox_override(state, skin)
	b.add_theme_color_override("font_color", Color("fff0c9"))
	b.add_theme_color_override("font_disabled_color", Color("8b9181"))

func layout() -> void:
	var dock_width := supply_row.get_combined_minimum_size().x + action_row.get_combined_minimum_size().x + 42
	var dock_x := (size.x - dock_width) * 0.5
	dock.position = Vector2(dock_x, size.y - 105)
	dock.size = Vector2(dock_width, 94)
	supply_row.position = dock.position + Vector2(12, 8)
	action_row.position = supply_row.position + Vector2(supply_row.get_combined_minimum_size().x + 18, 0)
	reload_button.position = Vector2(size.x * 0.5 - 70, size.y - 142)
	state_badge.position = Vector2(size.x * 0.5 - 230, 67)
	state_badge.size = Vector2(460, 28)
	objective_card.position = Vector2(14, 157)
	objective_card.custom_minimum_size = Vector2(300, 50)
	detail.position = Vector2(22, 222)
	detail.size = Vector2(276, 46)
	if is_instance_valid(hud):
		hud.minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hud.minimap.position = Vector2(size.x - 204, 76)
		hud.minimap.size = Vector2(190, 190)
		hud.siege.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hud.siege.position = Vector2(size.x - 236, 276)
		hud.siege.add_theme_font_size_override("font_size", 11)
	queue_redraw()

func update_state(w: Dictionary, p: Dictionary, building: bool) -> void:
	last_world = w
	last_player = p
	building_mode = building
	hud.stats.visible = false
	hud.status.visible = not hud.status.text.begins_with("Día ")
	hud.journal_text.text = hud.stats.text.strip_edges() + "\n\nCONTROLES\n" + hud.help_label.text + "\n\n" + hud.journal_text.text
	hud.magic.visible = false
	hud.objective.custom_minimum_size.x = 276
	hud.objective.add_theme_font_size_override("font_size", 13)
	hud.objective.max_lines_visible = 2
	objective_card.visible = not building
	detail.text = "%s · Materiales %d · Bóveda %d\n%s" % [p.name, p.wood, w.vault.hp, "HACHA-PICO" if p.get("equipped", "") == "tool" else w.get("adventure", {}).get("weapon", {}).get("name", "Pistola")]
	detail.tooltip_text = hud.stats.text
	for tile in tiles:
		tile.button.tooltip_text = tile.button.text
		if tile.button == hud.equip_button:
			tile.icon.kind = "tool" if p.get("equipped", "") == "tool" else "gun"
			tile.icon.queue_redraw()
			tile.caption.text = "%d / %d" % [p.ammo, p.reserve]
		if tile.button.text.begins_with("J "):
			tile.button.tooltip_text += "\n" + hud.stats.text
		if tile.button == hud.pause_button:
			tile.caption.text = "Continuar" if w.get("adventure", {}).get("paused", false) else "Pausa"
	for supply in supplies:
		var spec: Array = supply.spec
		var count := int(p.get(spec[0], 0))
		var full := float(p.get(spec[3], 100)) >= 100
		supply.button.text = "\n\n%s  ×%d" % [spec[1], count]
		supply.button.disabled = count <= 0 or full or not can_act()
		supply.icon.modulate.a = 0.4 if supply.button.disabled else 1.0
		supply.button.tooltip_text = "%s [%s] · +%d\n%s" % [spec[2], spec[1], spec[4], "Sin existencias: recoge botín con E." if count <= 0 else ("La necesidad ya está completa." if full else "Clic para usar un suministro.")]
	reload_button.disabled = not can_act() or p.get("reserve", 0) <= 0 or p.get("equipped", "") == "tool"
	reload_button.tooltip_text = "Recarga el arma equipada con la munición de reserva [R]."
	var paused: bool = w.get("adventure", {}).get("paused", false)
	state_badge.text = "PAUSA · Pulsa P para continuar" if paused else ("CONSTRUCCIÓN · G girar · Esc cancelar" if building else ("SALUD CRÍTICA · Busca cobertura o usa un botiquín" if p.hp <= 25 else ""))
	for tile in tiles:
		var selected: bool = (tile.button == hud.build_toggle and building) or (tile.button == hud.pause_button and paused) or (tile.button == hud.equip_button and p.get("equipped", "") != "tool")
		var skin := plate()
		if selected:
			skin.border_color = Color("ffdb77")
			skin.bg_color = Color("393a20ee")
		tile.button.add_theme_stylebox_override("normal", skin)
	update_powers()
	layout()
	queue_redraw()

func can_act() -> bool:
	return last_player.get("alive", false) and last_world.get("phase", "") == "active" and not last_world.get("adventure", {}).get("paused", false)

func _process(delta: float) -> void:
	if not visible or last_player.is_empty(): return
	cooldown_tick += delta
	if cooldown_tick >= 0.1:
		cooldown_tick = 0.0
		update_powers()

func update_powers() -> void:
	var magic_data: Dictionary = last_player.get("magic", {})
	var known: Array = magic_data.get("known", [])
	for b in power_buttons.values(): b.hide()
	var index := 0
	for spell in last_world.get("story", {}).get("spells", []):
		if not spell.id in known: continue
		if not power_buttons.has(spell.id):
			var b := Button.new()
			b.custom_minimum_size = Vector2(62, 62)
			b.add_theme_font_size_override("font_size", 12)
			style_button(b)
			b.pressed.connect(func(): hud.quick_action_requested.emit("cast", {"power": spell.id}))
			add_child(b)
			power_buttons[spell.id] = b
		var button: Button = power_buttons[spell.id]
		button.show()
		button.position = Vector2(size.x - 78 - (index % 3) * 68, size.y - 85 - (index / 3) * 68)
		var remaining := maxf(0, float(magic_data.get("cooldowns", {}).get(spell.id, 0)) / 1000.0 - Time.get_unix_time_from_system())
		button.disabled = not can_act() or remaining > 0 or magic_data.get("mana", 0) < spell.cost
		button.text = "%s\n%s" % [str(spell.key), ("%d s" % int(ceil(remaining))) if remaining > 0 else ("%d MP" % spell.cost)]
		button.tooltip_text = "%s [%s] · %d maná\n%s" % [spell.get("name", spell.id), str(spell.key), spell.cost, "Recargando" if remaining > 0 else ("Maná insuficiente" if magic_data.get("mana", 0) < spell.cost else "Clic para activar")]
		index += 1
	queue_redraw()

func label_at(position: Vector2, text: String, font_size: int = 14, color: Color = Color("fff0ca")) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func bar(position: Vector2, width: float, value: float, color: Color) -> void:
	draw_style_box(Palette.box(Color("101812"), Color("52604a"), 1), Rect2(position, Vector2(width, 14)))
	var fill := Palette.box(color, color.lightened(0.15), 1)
	fill.shadow_size = 0
	if value > 0: draw_style_box(fill, Rect2(position, Vector2(maxf(2, width * clampf(value / 100.0, 0, 1)), 14)))

func _draw() -> void:
	if last_player.is_empty(): return
	var p := last_player
	var adventure: Dictionary = last_world.get("adventure", {})
	draw_style_box(plate(), Rect2(14, 14, 290, 132))
	draw_style_box(plate(), Rect2(14, 215, 300, 52))
	draw_circle(Vector2(32, 34), 5, Color("ef5851"))
	draw_circle(Vector2(40, 34), 5, Color("ef5851"))
	draw_colored_polygon(PackedVector2Array([Vector2(27, 35), Vector2(45, 35), Vector2(36, 46)]), Color("ef5851"))
	bar(Vector2(55, 29), 158, p.hp, Color("c53c3d"))
	label_at(Vector2(223, 42), "%d / 100" % p.hp, 12)
	draw_colored_polygon(PackedVector2Array([Vector2(29, 61), Vector2(43, 61), Vector2(42, 72), Vector2(36, 78), Vector2(30, 72)]), Color("508bdc"))
	bar(Vector2(55, 62), 158, p.armor, Color("397cc9"))
	label_at(Vector2(223, 75), "%d / 100" % p.armor, 12)
	draw_line(Vector2(22, 89), Vector2(294, 89), Color("6f6843"), 1)
	label_at(Vector2(28, 111), "COMIDA", 9, Color("dfc187"))
	label_at(Vector2(91, 111), str(int(p.get("hunger", 100))), 12)
	bar(Vector2(115, 99), 42, p.get("hunger", 100), Color("d9b96a"))
	label_at(Vector2(171, 111), "AGUA", 9, Color("89d8e7"))
	label_at(Vector2(217, 111), str(int(p.get("thirst", 100))), 12)
	bar(Vector2(246, 99), 42, p.get("thirst", 100), Color("79c2de"))
	label_at(Vector2(29, 134), "ENERGÍA", 9)
	bar(Vector2(95, 123), 194, p.get("stamina", 100), Color("aaa17c"))
	var clock_x := size.x * 0.5 - 205
	draw_style_box(plate(), Rect2(clock_x, 15, 355, 41))
	var wave: Dictionary = adventure.get("threat", {})
	label_at(Vector2(clock_x + 12, 41), "%s  Día %d · %d s" % ["☾" if adventure.get("night", false) else "☀", adventure.get("day", 1), adventure.get("nextPhase", 360)], 13)
	label_at(Vector2(clock_x + 178, 41), "Oleada %d · %02d:%02d" % [last_world.wave, int(wave.get("seconds", 0)) / 60, int(wave.get("seconds", 0)) % 60], 13, Color("f5946c"))
	if not power_buttons.is_empty():
		label_at(Vector2(size.x - 211, size.y - (166 if power_buttons.size() > 3 else 98)), "MANÁ  %d / 100" % p.get("magic", {}).get("mana", 0), 11, Color("88d9e3"))
	label_at(Vector2(dock.position.x + 14, dock.position.y - 7), "SUMINISTROS", 9, Color("c4b787"))
	
	if p.hp <= 25:
		draw_style_box(Palette.box(Color("00000000"), Color("cc5445"), 2), Rect2(14, 14, 290, 132))

class Icon:
	extends Control
	const TEXTURES = {"gun": preload("res://assets/ui/hud/gun.svg"), "build": preload("res://assets/ui/hud/build.svg"), "tool": preload("res://assets/ui/hud/tool.svg"), "book": preload("res://assets/ui/hud/book.svg"), "pause": preload("res://assets/ui/hud/pause.svg"), "medical": preload("res://assets/ui/hud/medical.svg"), "water": preload("res://assets/ui/hud/water.svg"), "food": preload("res://assets/ui/hud/food.svg")}
	var kind := "tool"
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		paint(self, kind, Vector2.ZERO, size)
	static func paint(canvas: CanvasItem, type: String, origin: Vector2, extent: Vector2) -> void:
		if TEXTURES.has(type):
			canvas.draw_texture_rect(TEXTURES[type], Rect2(origin, extent), false)
			return
