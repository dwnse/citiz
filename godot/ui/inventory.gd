extends Control
## Inventory is a view of authoritative snapshots. Only server actions change stock.
signal action_requested(action: String, payload: Dictionary)
const ICONS = preload("res://ui/gameplay_overlay.gd").Icon
const ITEMS := {
	"pistol": ["Pistola", "gun", "Arma de servicio. Recarga con munición de reserva."],
	"shotgun": ["Escopeta", "gun", "Corta distancia. Fabricación en taller: 60 materiales + 2 componentes."],
	"rifle": ["Rifle", "gun", "Arma de largo alcance. Fabricación en taller: 90 materiales + 4 componentes."],
	"tool": ["Hacha-pico", "tool", "Equipa y mantén clic sobre árboles o rocas para recolectar."],
	"food": ["Comida", "food", "Recupera 35 de comida. Consume una unidad."],
	"water": ["Agua", "water", "Recupera 40 de hidratación. Consume una unidad."],
	"medical": ["Botiquín", "medical", "Recupera 30 de vida. Consume una unidad."],
	"ammo": ["Munición", "ammo", "Reserva compartida por tus armas. Selecciona Recargar para llenar el cargador."],
	"timber": ["Madera", "timber", "Material de construcción: muros, refugios y producción."],
	"stone": ["Piedra", "stone", "Material de construcción: defensas y edificios."],
	"scrap": ["Chatarra", "scrap", "Material para talleres, industria y defensas."],
	"components": ["Componentes", "components", "Componentes de laboratorio para fabricar armas y progresar."],
	"reclaimed": ["Recuperados", "reclaimed", "Sustituyen materiales específicos al construir."],
	"armor": ["Blindaje", "armor", "Protección actual. Repárala usando una armería cercana."],
	"cargo": ["Informe", "book", "Carga de expedición. Entrega el informe junto a tu bóveda con E."]
}
var player: Dictionary = {}
var world: Dictionary = {}
var selected := "food"
const DEFAULT_ORDER := ["pistol", "tool", "food", "water", "medical", "ammo", "timber", "stone", "scrap", "components", "reclaimed", "shotgun", "rifle", "cargo"]
var order: Array = DEFAULT_ORDER.duplicate()
var sheet := Control.new()
var cells: Array[Button] = []
var quick_cells: Array[Button] = []
var title: Label
var item_name: Label
var description: Label
var status: Label
var vitals: Label
var use_button: Button
var craft_button: Button
var viewport := SubViewport.new()
var model: Node3D
var preview_meshes: Array[MeshInstance3D] = []
var equipment: Array[Button] = []
var last_profile := ""
var busy := false
var busy_until := 0

static func skin(fill: String = "20211f", border: String = "66513b") -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(fill)
	s.border_color = Color(border)
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s

func label(text: String, at: Vector2, extent: Vector2, font_size: int = 15, color: String = "e2d9ca") -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.size = extent
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(color))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(l)
	return l

func button(text: String, at: Vector2, extent: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = extent
	b.add_theme_stylebox_override("normal", skin())
	b.add_theme_stylebox_override("hover", skin("393024", "dc914c"))
	b.add_theme_stylebox_override("pressed", skin("573820", "ffb766"))
	b.add_theme_stylebox_override("disabled", skin("191b19", "393b35"))
	b.add_theme_stylebox_override("focus", skin("00000000", "f5bd7a"))
	b.pressed.connect(callback)
	sheet.add_child(b)
	return b

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sheet)
	sheet.size = Vector2(1160, 650)
	var panel := RustPanel.new()
	panel.size = sheet.size
	panel.add_theme_stylebox_override("panel", skin("171b19fa", "a76a38"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(panel)
	label("INVENTARIO", Vector2(26, 16), Vector2(500, 44), 29)
	title = label("", Vector2(550, 20), Vector2(490, 40), 14, "bdae95")
	button("×", Vector2(1092, 17), Vector2(44, 40), hide)
	label("EQUIPO", Vector2(26, 76), Vector2(400, 26), 19, "e69b55")
	label("MOCHILA", Vector2(480, 76), Vector2(600, 26), 19, "e69b55")
	make_preview()
	for entry in [["armor", Vector2(28, 120)], ["tool", Vector2(28, 337)], ["pistol", Vector2(352, 120)], ["ammo", Vector2(352, 337)]]:
		var id: String = entry[0]
		var b := button("", entry[1], Vector2(80, 98), func(): select_item(str(player.get("weapon", "pistol")) if id == "pistol" else id))
		decorate(b, id, 80)
		equipment.append(b)
	for i in range(30):
		var b := Slot.new()
		b.inventory = self
		b.slot = i
		b.position = Vector2(480 + (i % 6) * 106, 114 + (i / 6) * 77)
		b.size = Vector2(99, 70)
		b.add_theme_stylebox_override("hover", skin("393024", "dc914c"))
		b.add_theme_stylebox_override("focus", skin("00000000", "f5bd7a"))
		b.pressed.connect(func(): select_item(str(order[i]) if i < order.size() else ""))
		sheet.add_child(b)
		decorate(b, "", 99)
		cells.append(b)
	vitals = label("", Vector2(28, 443), Vector2(425, 30), 15)
	label("ACCESO RÁPIDO", Vector2(28, 493), Vector2(420, 24), 16, "e69b55")
	for i in range(5):
		var id: String = ["tool", "pistol", "medical", "food", "water"][i]
		var b := button("", Vector2(28 + i * 84, 528), Vector2(77, 72), func(): select_item(id); activate())
		decorate(b, id, 77)
		var key := Label.new()
		key.text = str(i + 1)
		key.position = Vector2(5, 2)
		key.add_theme_font_size_override("font_size", 10)
		key.add_theme_color_override("font_color", Color("efb66c"))
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(key)
		quick_cells.append(b)
	item_name = label("", Vector2(480, 502), Vector2(620, 25), 19, "f0b66e")
	description = label("", Vector2(480, 532), Vector2(620, 42), 13)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use_button = button("Usar", Vector2(480, 583), Vector2(230, 36), activate)
	craft_button = button("Fabricar munición · 15 mat.", Vector2(724, 583), Vector2(270, 36), func(): send_action("craft", {}))
	status = label("", Vector2(28, 619), Vector2(990, 25), 12, "bdae95")
	label("I / Esc · Cerrar", Vector2(1010, 619), Vector2(140, 25), 12, "bdae95")
	resized.connect(fit)
	visibility_changed.connect(func():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
		if visible: refresh()
	)
	fit()
	hide()

func decorate(b: Button, id: String, width: float) -> void:
	b.set_meta("item", id)
	var icon := ItemIcon.new()
	icon.name = "Art"
	icon.kind = str(ITEMS[id][1]) if ITEMS.has(id) else ""
	icon.position = Vector2((width - 44) * 0.5, 3)
	icon.size = Vector2(44, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var caption := Label.new()
	caption.name = "Caption"
	caption.position = Vector2(3, 46)
	caption.size = Vector2(width - 6, 20)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 11)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caption)

func fit() -> void:
	var factor := minf((size.x - 24) / 1160.0, (size.y - 24) / 650.0)
	sheet.scale = Vector2.ONE * maxf(0.1, factor)
	sheet.position = (size - sheet.size * sheet.scale) * 0.5

func make_preview() -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(22, 108)
	container.size = Vector2(420, 330)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(container)
	viewport.size = Vector2i(480, 660)
	container.stretch = true
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	container.add_child(viewport)
	var space := Node3D.new()
	viewport.add_child(space)
	model = preload("res://assets/characters/Sam.glb").instantiate()
	space.add_child(model)
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if animation: animation.stop()
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	skeleton.reset_bone_poses()
	# The imported bind pose has lowered arms. Rotate a separate preview rig;
	# gameplay animation and the shared source mesh remain untouched.
	for side in ["L", "R"]:
		var upper := skeleton.find_bone("UpperArm." + side)
		var lower := skeleton.find_bone("LowerArm." + side)
		var direction := Vector3.RIGHT if skeleton.get_bone_global_pose(upper).origin.x > 0 else Vector3.LEFT
		align_bone(skeleton, upper, skeleton.get_bone_global_pose(lower).origin - skeleton.get_bone_global_pose(upper).origin, direction)
		align_bone(skeleton, lower, skeleton.get_bone_global_pose(lower).basis.y, direction)
	var pistol := model.find_child("Pistol", true, false)
	if pistol: pistol.hide()
	for node in skeleton.get_children():
		if node is MeshInstance3D:
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/characters/cerco_palette.gdshader")
			var original: StandardMaterial3D = node.mesh.surface_get_material(0)
			material.set_shader_parameter("atlas", original.albedo_texture)
			node.material_override = material
			preview_meshes.append(node)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d9dfeb")
	environment.environment.ambient_light_energy = 0.7
	space.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -30, 0)
	light.light_energy = 1.4
	space.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.85
	camera.position = Vector3(0, 0.8, 4)
	space.add_child(camera)
	camera.look_at(Vector3(0, 0.8, 0))

func align_bone(skeleton: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	var parent := skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone))
	var desired := Basis(Quaternion(from.normalized(), to.normalized())) * pose.basis
	skeleton.set_bone_pose_rotation(bone, (parent.basis.inverse() * desired).orthonormalized().get_rotation_quaternion())

func update_state(w: Dictionary, p: Dictionary) -> void:
	world = w
	player = p
	if str(p.get("id", "")) != last_profile:
		last_profile = str(p.get("id", ""))
		order = DEFAULT_ORDER.duplicate()
		var config := ConfigFile.new()
		if config.load("user://inventory_layout.cfg") == OK:
			var saved: Variant = config.get_value(last_profile, "order", [])
			if saved is Array and saved.size() == 30:
				var seen: Array = []
				for id in saved:
					if ITEMS.has(id) and id != "armor" and not id in seen: seen.append(id)
				if seen.size() == 14: order = saved
		while order.size() < 30: order.append("")
	if not p.get("alive", false): hide()
	if visible: refresh()

func count(id: String) -> int:
	if id in ["pistol", "shotgun", "rifle"]: return 1 if id in player.get("weapons", ["pistol"]) else 0
	if id == "tool": return 1
	if id == "ammo": return int(player.get("reserve", 0))
	if id == "armor": return int(player.get("armor", 0))
	if id == "cargo": return 1 if player.get("cargo") != null else 0
	if id in ["timber", "stone", "scrap", "components", "reclaimed"]: return int(player.get("materials", {}).get(id, player.get("wood", 0) if id == "reclaimed" else 0))
	return int(player.get(id, 0))

func can_act() -> bool:
	return player.get("alive", false) and world.get("phase", "") == "active" and not world.get("adventure", {}).get("paused", false) and not busy

func update_cell(b: Button, id: String) -> void:
	b.set_meta("item", id)
	var icon: Control = b.get_node("Art")
	icon.kind = str(ITEMS[id][1]) if ITEMS.has(id) else ""
	icon.modulate.a = 1.0 if count(id) > 0 else 0.3
	icon.queue_redraw()
	var caption: Label = b.get_node("Caption")
	caption.text = "%s · %d" % [ITEMS[id][0], count(id)] if ITEMS.has(id) else ""
	b.tooltip_text = str(ITEMS[id][2]) if ITEMS.has(id) else "Espacio libre · arrastra aquí un objeto"
	b.add_theme_stylebox_override("normal", skin("3a2d21" if id == selected else "20211f", "eea45e" if id == selected else "514b3d"))

func refresh() -> void:
	if player.is_empty(): return
	title.text = "%s    /    %d materiales    /    %d + %d balas" % [player.get("name", "Superviviente"), player.get("wood", 0), player.get("ammo", 0), player.get("reserve", 0)]
	for i in range(cells.size()): update_cell(cells[i], str(order[i]) if i < order.size() else "")
	equipment[2].set_meta("item", str(player.get("weapon", "pistol")))
	for b in equipment: update_cell(b, str(b.get_meta("item")))
	for b in quick_cells:
		var id: String = b.get_meta("item")
		update_cell(b, id)
		b.disabled = not can_act() or (id in ["food", "water", "medical"] and (count(id) == 0 or float(player.get({"food":"hunger", "water":"thirst", "medical":"hp"}[id], 100)) >= 100))
	vitals.text = "VIDA %d    BLINDAJE %d\nCOMIDA %d    AGUA %d" % [player.get("hp", 0), player.get("armor", 0), player.get("hunger", 0), player.get("thirst", 0)]
	var tint: Color = {"standard":Color("81917b"), "ember":Color("df8e43"), "mist":Color("7bc1bd"), "seal":Color("b297de")}.get(player.get("appearance", "standard"), Color("81917b"))
	for mesh in preview_meshes: mesh.set_instance_shader_parameter("insignia", tint)
	item_name.text = str(ITEMS[selected][0]) if ITEMS.has(selected) else "Selecciona un objeto"
	description.text = str(ITEMS[selected][2]) if ITEMS.has(selected) else "Arrastra objetos entre casillas para organizar tu mochila."
	use_button.text = "Usar"
	use_button.disabled = not can_act()
	if selected in ["food", "water", "medical"]:
		var stat: String = {"food":"hunger", "water":"thirst", "medical":"hp"}[selected]
		use_button.disabled = use_button.disabled or count(selected) <= 0 or float(player.get(stat, 100)) >= 100
		if float(player.get(stat, 100)) >= 100: use_button.text = "Necesidad completa"
		elif count(selected) <= 0: use_button.text = "Sin existencias"
	elif selected in ["pistol", "shotgun", "rifle", "tool"]:
		var equipped: bool = (selected == "tool" and player.get("equipped", "weapon") == "tool") or (selected == player.get("weapon", "pistol") and player.get("equipped", "weapon") == "weapon")
		use_button.text = "Equipada" if equipped else ("Equipar" if count(selected) > 0 else "Fabricar y equipar")
		use_button.disabled = use_button.disabled or equipped or float(player.get("reload", 0)) > 0
	elif selected == "ammo":
		use_button.text = "Recargar"
		use_button.disabled = use_button.disabled or count("ammo") <= 0 or float(player.get("reload", 0)) > 0 or player.get("ammo", 0) >= world.get("adventure", {}).get("weapon", {}).get("capacity", 12)
	else:
		use_button.text = "Material / equipo pasivo"
		use_button.disabled = true
	craft_button.disabled = not can_act() or int(player.get("wood", 0)) < 15
	status.text = "PAUSA · P para continuar" if world.get("adventure", {}).get("paused", false) else ("Esperando al servidor…" if busy else "Selecciona para usar o equipar · Arrastra para ordenar · El mundo sigue activo")

func select_item(id: String) -> void:
	selected = id
	refresh()

func activate() -> void:
	refresh()
	if use_button.disabled: return
	if selected in ["food", "water", "medical"]: send_action("consume", {"item":selected})
	elif selected == "tool": send_action("equip", {"item":"tool"})
	elif selected in ["pistol", "shotgun", "rifle"]:
		if selected == player.get("weapon", "pistol"): send_action("equip", {"item":"weapon"})
		else: send_action("weapon", {"weapon":selected})
	elif selected == "ammo": send_action("reload", {})

func send_action(action: String, payload: Dictionary) -> void:
	if not can_act(): return
	busy = true
	busy_until = Time.get_ticks_msec() + 350
	action_requested.emit(action, payload)
	refresh()

func _process(_delta: float) -> void:
	if busy and Time.get_ticks_msec() >= busy_until:
		busy = false
		if visible: refresh()

func swap_slots(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= 30 or b >= 30: return
	while order.size() < 30: order.append("")
	var old: Variant = order[a]
	order[a] = order[b]
	order[b] = old
	var config := ConfigFile.new()
	config.load("user://inventory_layout.cfg")
	config.set_value(last_profile, "order", order)
	config.save("user://inventory_layout.cfg")
	refresh()

class Slot extends Button:
	var inventory: Control
	var slot := 0
	func _get_drag_data(_at: Vector2) -> Variant:
		if slot >= inventory.order.size() or inventory.order[slot] == "": return null
		var preview := Label.new()
		preview.text = inventory.ITEMS[inventory.order[slot]][0]
		set_drag_preview(preview)
		return {"inventory":inventory, "slot":slot}
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.get("inventory") == inventory and data.has("slot")
	func _drop_data(_at: Vector2, data: Variant) -> void:
		inventory.swap_slots(int(data.slot), slot)

class ItemIcon extends Control:
	const EXTRA := {
		"ammo":preload("res://assets/ui/inventory/ammo.svg"),
		"armor":preload("res://assets/ui/inventory/armor.svg"),
		"timber":preload("res://assets/ui/inventory/timber.svg"),
		"stone":preload("res://assets/ui/inventory/stone.svg"),
		"scrap":preload("res://assets/ui/inventory/scrap.svg"),
		"components":preload("res://assets/ui/inventory/components.svg"),
		"reclaimed":preload("res://assets/ui/inventory/reclaimed.svg")
	}
	var kind := ""
	func _draw() -> void:
		if ICONS.TEXTURES.has(kind):
			ICONS.paint(self, kind, Vector2.ZERO, size)
		elif EXTRA.has(kind): draw_texture_rect(EXTRA[kind], Rect2(Vector2.ZERO, size), false)

class RustPanel extends Panel:
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 6241
		for i in range(1800):
			var at := Vector2(rng.randf_range(2, size.x - 2), rng.randf_range(2, size.y - 2))
			draw_line(at, at + Vector2(rng.randf_range(1, 7), 0), Color(0.55, 0.32, 0.16, rng.randf_range(0.025, 0.12)))
		draw_line(Vector2(24, 66), Vector2(1136, 66), Color("775135"))
		draw_line(Vector2(458, 84), Vector2(458, 602), Color("473e30"))
		for at in [Vector2(9, 9), Vector2(1151, 9), Vector2(9, 641), Vector2(1151, 641)]:
			draw_circle(at, 3, Color("8b7452"))
