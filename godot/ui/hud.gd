extends CanvasLayer
const Minimap = preload("res://ui/minimap.gd")
signal enter_requested(world: String, community: String, agent_name: String)
signal refresh_requested
signal create_requested
signal leave_requested
signal reconnect_requested
signal structure_chosen(kind: String)
signal management_action(action: String)

var lobby: PanelContainer
var worlds := OptionButton.new()
var communities := OptionButton.new()
var agent_name := LineEdit.new()
var status := Label.new()
var stats := Label.new()
var objective := Label.new()
var journal: PanelContainer
var journal_text := RichTextLabel.new()
var directory: Array = []
var help_label := Label.new()
var minimap: Control
var siege := Label.new()
var magic := Label.new()
var build_panel: PanelContainer
var build_buttons: GridContainer
var build_hint := Label.new()
var catalog_ids: Array[String] = []
var building_mode := false
var inspector: PanelContainer
var inspection := Label.new()
var management_buttons: Dictionary = {}

func button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(430, 110)
	root.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	var title := Label.new()
	title.text = "  EL CERCO  /  OPERACIÓN UMBRAL  /  3D"
	title.add_theme_color_override("font_color", Color("c6e78a"))
	rows.add_child(title)
	rows.add_child(stats)
	rows.add_child(objective)
	status.position = Vector2(24, 170)
	status.add_theme_color_override("font_color", Color("e8c68c"))
	root.add_child(status)
	build_panel=PanelContainer.new()
	build_panel.position=Vector2(18,195)
	build_panel.custom_minimum_size=Vector2(310,260)
	root.add_child(build_panel)
	var build_rows := VBoxContainer.new()
	build_panel.add_child(build_rows)
	var build_title := Label.new()
	build_title.text="CONSTRUCCIÓN · WASD mueve la cámara"
	build_rows.add_child(build_title)
	build_buttons=GridContainer.new()
	build_buttons.columns=2
	build_rows.add_child(build_buttons)
	build_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	build_hint.custom_minimum_size=Vector2(290,85)
	build_rows.add_child(build_hint)
	build_panel.hide()
	inspector=PanelContainer.new()
	inspector.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inspector.position=Vector2(-315,335)
	inspector.custom_minimum_size=Vector2(295,180)
	root.add_child(inspector)
	var inspection_rows := VBoxContainer.new()
	inspector.add_child(inspection_rows)
	inspection.custom_minimum_size=Vector2(285,70)
	inspection.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	inspection_rows.add_child(inspection)
	var actions := GridContainer.new()
	actions.columns=2
	inspection_rows.add_child(actions)
	for entry in [["use","Usar"],["repair","Reparar · 10"],["upgrade_structure","Mejorar"],["dismantle","Desmontar"]]:
		var action: String = entry[0]
		var b := button(actions,entry[1],func(): management_action.emit(action))
		b.focus_mode=Control.FOCUS_NONE
		management_buttons[action]=b
	inspector.hide()
	var controls := HBoxContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-365, 20)
	root.add_child(controls)
	button(controls, "Partidas", func(): leave_requested.emit())
	button(controls, "Reconectar", func(): reconnect_requested.emit())
	button(controls, "Diario · J", toggle_journal)
	minimap = Minimap.new()
	minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-210, 75)
	minimap.size = Vector2(190, 190)
	root.add_child(minimap)
	siege.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	siege.position = Vector2(-320, 280)
	root.add_child(siege)
	magic.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	magic.position = Vector2(24, -155)
	magic.add_theme_color_override("font_color", Color("d7bce9"))
	root.add_child(magic)
	help_label.text = "WASD mover · Ratón apuntar · Clic disparar · R recargar\nB construir · 1–8 elegir · G girar · Mayús + arrastrar: fila · Clic derecho: gestionar\nE usar · V registrar ruinas · T depositar · F reparar · X desmontar · C fabricar · J diario"
	help_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help_label.position = Vector2(24, -90)
	root.add_child(help_label)
	lobby = PanelContainer.new()
	lobby.position = Vector2(435, 210)
	lobby.custom_minimum_size = Vector2(420, 290)
	root.add_child(lobby)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 12)
	lobby.add_child(menu)
	var heading := Label.new()
	heading.text = "EL CERCO · CLIENTE GODOT\nElige una partida y conserva tu perfil al reconectar."
	menu.add_child(heading)
	menu.add_child(worlds)
	menu.add_child(communities)
	worlds.item_selected.connect(func(_i): update_communities())
	agent_name.placeholder_text = "Nombre del agente"
	agent_name.text = "Agente Godot"
	agent_name.max_length = 18
	menu.add_child(agent_name)
	button(menu, "Entrar", enter_selection)
	button(menu, "Actualizar partidas", func(): refresh_requested.emit())
	button(menu, "Nueva partida", func(): create_requested.emit())
	journal = PanelContainer.new()
	journal.position = Vector2(280, 170)
	journal.custom_minimum_size = Vector2(720, 410)
	journal.visible = false
	root.add_child(journal)
	var journal_rows := VBoxContainer.new()
	journal.add_child(journal_rows)
	journal_text.custom_minimum_size = Vector2(690, 350)
	journal_text.bbcode_enabled = false
	journal_rows.add_child(journal_text)
	button(journal_rows, "Cerrar diario", toggle_journal)

func set_worlds(items: Array) -> void:
	var previous: String = str(worlds.get_selected_metadata()) if worlds.selected>=0 else ""
	directory = items
	worlds.clear()
	var preferred := -1
	for w in items:
		worlds.add_item("%s · %d/%d · %s" % [w.name, w.members, w.capacity, w.phase])
		worlds.set_item_metadata(worlds.item_count - 1, w.id)
		if w.phase=="active" and (preferred<0 or w.id==previous): preferred=worlds.item_count-1
	if preferred>=0: worlds.select(preferred)
	update_communities()

func inspect_structure(w: Dictionary,p: Dictionary,b: Dictionary) -> void:
	inspector.visible=not b.is_empty() and p.get("alive",false) and w.get("phase","")=="active"
	if not inspector.visible: return
	var d: Dictionary = {}
	for item in w.get("buildingCatalog",[]):
		if item.id==b.get("kind","wall"): d=item
	if d.is_empty(): return
	var level := int(b.get("level",0))
	var cost := int(d.cost)*(level+1)
	var distance := Vector2(b.x-p.x,b.y-p.y).length()
	inspection.text="%s · Nivel %d/3\nPV %d/%d · Existencias %d\n%s" % [d.name,level+1,b.hp,b.get("maxHp",d.hp),b.get("stock",0),"Acércate a menos de 5 m para gestionar" if distance>5 else "Mejoras: +50% PV base; más producción en talleres, pozos y huertos."]
	management_buttons.use.disabled=distance>4.5 or b.get("kind","wall") in ["wall","spikes"]
	management_buttons.repair.disabled=distance>5 or p.wood<10 or b.hp>=b.get("maxHp",d.hp)
	management_buttons.upgrade_structure.text="Nivel máximo" if level>=2 else "Mejorar · %d" % cost
	management_buttons.upgrade_structure.disabled=distance>5 or level>=2 or p.wood<cost
	management_buttons.dismantle.text="Desmontar · +%d" % int(d.cost/2)
	management_buttons.dismantle.disabled=distance>=5

func update_communities() -> void:
	communities.clear()
	if worlds.selected < 0:
		return
	for c in directory[worlds.selected].communities:
		communities.add_item("%s · %d/10" % [c.name, c.members])
		communities.set_item_metadata(communities.item_count - 1, c.id)

func enter_selection() -> void:
	if worlds.selected >= 0 and communities.selected >= 0:
		enter_requested.emit(worlds.get_selected_metadata(), communities.get_selected_metadata(), agent_name.text)

func toggle_journal() -> void:
	if not lobby.visible:
		journal.visible = not journal.visible

func show_state(w: Dictionary, p: Dictionary, building: bool) -> void:
	lobby.hide()
	building_mode=building
	build_panel.visible=building
	if catalog_ids.is_empty():
		for item in w.get("buildingCatalog",[]):
			var kind: String = item.id
			catalog_ids.append(kind)
			var b := button(build_buttons,"%d %s · %d" % [catalog_ids.size(),item.name,item.cost],func(): structure_chosen.emit(kind))
			b.tooltip_text=item.description
			b.focus_mode=Control.FOCUS_NONE
	minimap.update_state(w, p.id)
	var siege_state: Dictionary = w.get("siege", {})
	var seconds := int(ceil(float(siege_state.get("remaining", 0)) / 1000))
	siege.text = "%s · %02d:%02d\nRequiere defensores conectados" % ["ASEDIO ACTIVO" if siege_state.get("active", false) else "Próximo asedio", seconds / 60, seconds % 60]
	siege.visible = siege_state.get("enabled", false)
	siege.modulate = Color("f0ad83") if siege_state.get("active", false) else Color("ced9c3")
	stats.text = "  %s · PV %d · Blindaje %d · Pistola %d / %d\n  Materiales %d · Bóveda %d · Oleada %d · %s" % [p.name, p.hp, p.armor, p.ammo, p.reserve, p.wood, w.vault.hp, w.wave, "PLANO ACTIVO" if building else "PISTOLA"]
	stats.text += "\n  Alimento %d · Agua %d%s" % [p.get("hunger",100),p.get("thirst",100)," · RECARGANDO %.1f s" % p.reload if p.reload>0 else ""]
	for site in w.get("obstacles",[]):
		if not str(site.id).ends_with("-ruin"): continue
		var edge := Vector2(maxf(0,absf(p.x-site.x)-site.sx),maxf(0,absf(p.y-site.y)-site.sy))
		if edge.length()<=3:
			var remaining := maxi(0,int(ceil((float(site.get("scavengeAfter",0))-Time.get_unix_time_from_system()*1000)/1000)))
			stats.text+="\n  V: +25 materiales y 6 balas" if remaining==0 else "\n  Ruinas: suministros en %d s" % remaining
			break
	var story: Dictionary = w.get("story", {})
	if w.phase != "active":
		objective.text = "  PARTIDA TERMINADA: " + str(w.phase)
	elif not p.alive:
		objective.text = "  HAS CAÍDO · Regreso si tu bóveda sigue en pie."
	elif p.get("prologue", 0) == 0:
		objective.text = "  E: recupera la radio junto al transporte."
	elif not p.get("intro", false):
		objective.text = "  Alcanza tu bóveda y pulsa E."
	else:
		objective.text = "  J: señales de los magos · %d/6 claves · Maná %d" % [story.get("fragments", []).size(), p.magic.mana]
	var text := "LAS SEIS VOCES DEL SELLO\n\n"
	var magic_text := "MANÁ %d / 100\n" % p.magic.mana
	if story.get("message") is Dictionary:
		text += str(story.message.text) + "\n\n"
	for mage in story.get("mages", []):
		text += "%s · %s · señal (%d, %d)\n" % [mage.name, mage.power, mage.x, mage.y]
	text += "\nPODERES — maná / recarga restante\n"
	for spell in story.get("spells", []):
		var learned: bool = spell.id in p.magic.known
		var remaining := maxf(0, (float(p.magic.cooldowns.get(spell.id, 0)) - Time.get_unix_time_from_system() * 1000) / 1000)
		text += "%s · %s · %s · %d maná / %.1f s\n" % [spell.key, spell.name, "Aprendido" if learned else "Sin aprender", spell.cost, remaining]
		magic_text += "%s %s [%s]  " % [spell.key, spell.name, ("%.0fs" % ceil(remaining) if remaining > 0 else ("LISTO" if p.magic.mana >= spell.cost else "SIN MANÁ")) if learned else "BLOQUEADO"]
	magic.text = magic_text
	magic.visible = not p.magic.known.is_empty()
	for fragment in story.get("fragments", []):
		text += "\n" + str(fragment.text)
	text += "\n\nSello: abierto" if story.get("opened", false) else "\n\nSello: reúne seis claves y pulsa E en (105, 105)."
	journal_text.text = text
