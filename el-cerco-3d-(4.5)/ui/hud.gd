extends CanvasLayer
const Placement = preload("res://building/placement.gd")
const Minimap = preload("res://ui/minimap.gd")
signal enter_requested(world: String, community: String, agent_name: String)
signal refresh_requested
signal create_requested
signal leave_requested
signal reconnect_requested
signal structure_chosen(kind: String)
signal management_action(action: String)
signal build_requested
signal equip_requested
signal find_plot_requested
signal pause_requested
signal weapon_requested(kind: String)
signal cosmetic_requested(style: String)
signal rebuild_requested

var population_panel := preload("res://ui/population.gd").new()
var settings := preload("res://ui/settings.gd").new()
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
var performance := Label.new()
var toast := Label.new()
var toast_seconds := 0.0
var health := ProgressBar.new()
var hunger_bar := ProgressBar.new()
var water_bar := ProgressBar.new()
var build_toggle: Button
var enter_button: Button
var equip_button: Button
var rebuild_button: Button
var category := OptionButton.new()
var pause_button: Button
var stamina := ProgressBar.new()
var last_incident := ""
var cosmetic_buttons: Dictionary = {}

func card(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=10
	style.content_margin_bottom=10
	return style

func notify_action(message: String, success: bool) -> void:
	toast.text=("✓  " if success else "!  ")+message
	toast.modulate=Color("9ce4bc") if success else Color("ffbf8c")
	toast.show()
	toast_seconds=5

func _process(delta: float) -> void:
	toast_seconds=maxf(0,toast_seconds-delta)
	toast.visible=toast_seconds>0

func button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready() -> void:
	var root := Control.new()
	var theme := Theme.new()
	theme.default_font_size=15
	theme.set_stylebox("panel","PanelContainer",card(Color("121e28ee"),Color("324753")))
	theme.set_stylebox("normal","Button",card(Color("263844"),Color("415660")))
	theme.set_stylebox("hover","Button",card(Color("345666"),Color("75cbb1")))
	theme.set_stylebox("pressed","Button",card(Color("226254"),Color("98f0ce")))
	theme.set_stylebox("disabled","Button",card(Color("1c272f"),Color("29363e")))
	theme.set_color("font_color","Label",Color("dbe8ed"))
	root.theme=theme
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
	title.text = "EL CERCO    /    SUPERVIVENCIA"
	title.add_theme_color_override("font_color", Color("c6e78a"))
	rows.add_child(title)
	stats.add_theme_font_size_override("font_size",13)
	rows.add_child(stats)
	rows.add_child(objective)
	var needs := HBoxContainer.new()
	rows.add_child(needs)
	for entry in [[health,"VIDA",Color("77d6a7")],[hunger_bar,"COMIDA",Color("dec88a")],[water_bar,"AGUA",Color("72bfe6")],[stamina,"ENERGÍA",Color("ad9de1")]]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		needs.add_child(column)
		var label := Label.new()
		label.text=entry[1]
		label.add_theme_font_size_override("font_size",11)
		column.add_child(label)
		var bar: ProgressBar = entry[0]
		bar.show_percentage=false
		bar.custom_minimum_size=Vector2(82,6)
		bar.add_theme_stylebox_override("fill",card(entry[2],entry[2]))
		column.add_child(bar)
	status.position = Vector2(24, 279)
	status.add_theme_font_size_override("font_size",12)
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	status.add_theme_color_override("font_color", Color("e8c68c"))
	root.add_child(status)
	build_panel=PanelContainer.new()
	build_panel.position=Vector2(18,300)
	build_panel.custom_minimum_size=Vector2(310,260)
	root.add_child(build_panel)
	var build_rows := VBoxContainer.new()
	build_panel.add_child(build_rows)
	var build_title := Label.new()
	build_title.text="BASE / CONSTRUCCIÓN"
	build_rows.add_child(build_title)
	for label in ["Todo","Defensa","Supervivencia","Industria"]: category.add_item(label)
	build_rows.add_child(category)
	category.focus_mode=Control.FOCUS_NONE
	var legend := Label.new()
	legend.text="AZUL: tu parcela · ROJO: centro reservado\nPlano VERDE: clic para construir\nU junto a la bóveda: ampliar territorio"
	legend.add_theme_font_size_override("font_size",12)
	build_rows.add_child(legend)
	button(build_rows,"Mostrar un lugar disponible",func(): find_plot_requested.emit()).focus_mode=Control.FOCUS_NONE
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(285,110)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	build_rows.add_child(scroll)
	build_buttons=GridContainer.new()
	build_buttons.columns=2
	scroll.add_child(build_buttons)
	build_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	build_hint.custom_minimum_size=Vector2(290,48)
	build_hint.add_theme_font_size_override("font_size",12)
	build_hint.max_lines_visible=4
	build_rows.add_child(build_hint)
	build_panel.hide()
	toast.position=Vector2(370,555)
	toast.custom_minimum_size=Vector2(560,55)
	toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("normal",card(Color("13202bf2"),Color("537369")))
	root.add_child(toast)
	toast.hide()
	var hotbar := HBoxContainer.new()
	hotbar.position=Vector2(350,670)
	root.add_child(hotbar)
	build_toggle=button(hotbar,"B  Construir",func(): build_requested.emit())
	build_toggle.focus_mode=Control.FOCUS_NONE
	equip_button=button(hotbar,"Q  Hacha-pico",func(): equip_requested.emit())
	equip_button.focus_mode=Control.FOCUS_NONE
	rebuild_button=button(hotbar,"K  Reconstruir bóveda · 100",func(): rebuild_requested.emit())
	rebuild_button.focus_mode=Control.FOCUS_NONE
	rebuild_button.hide()
	button(hotbar,"J  Diario",toggle_journal).focus_mode=Control.FOCUS_NONE
	pause_button=button(hotbar,"P  Pausa",func(): pause_requested.emit())
	pause_button.focus_mode=Control.FOCUS_NONE
	performance.position=Vector2(1190,690)
	performance.add_theme_font_size_override("font_size",12)
	performance.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(performance)
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
	for entry in [["use","Usar"],["armor","Blindaje · 25"],["auto_close","Cierre automático"],["deposit_materials","Guardar materiales"],["deposit_ammo","Guardar 30 balas"],["withdraw_ammo","Retirar 30 balas"],["staff","Priorizar trabajador"],["unstaff","Pausar puesto"],["supply_workers","Donar comida + agua"],["repair","Reparar · 10"],["upgrade_structure","Mejorar"],["dismantle","Desmontar"]]:
		var action: String = entry[0]
		var b := button(actions,entry[1],func(): management_action.emit(action))
		b.focus_mode=Control.FOCUS_NONE
		b.clip_text=true
		b.custom_minimum_size.x=132
		b.add_theme_font_size_override("font_size",12)
		management_buttons[action]=b
	inspector.hide()
	var controls := HBoxContainer.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-465, 20)
	root.add_child(controls)
	button(controls, "Partidas", func(): leave_requested.emit())
	button(controls, "Reconectar", func(): reconnect_requested.emit())
	button(controls, "Comunidad",toggle_population)
	button(controls, "Ajustes",func():
		journal.hide()
		population_panel.hide()
		settings.visible=not settings.visible
	)
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
	help_label.position = Vector2(24, -110)
	help_label.add_theme_font_size_override("font_size",12)
	help_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
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
	enter_button=button(menu, "Entrar", enter_selection)
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
	var weapons := HBoxContainer.new()
	journal_rows.add_child(weapons)
	for entry in [["pistol","Pistola"],["shotgun","Escopeta · 60 + 2 componentes"],["rifle","Rifle · 90 + 4 componentes"]]:
		var kind: String = entry[0]
		button(weapons,entry[1],func(): weapon_requested.emit(kind)).focus_mode=Control.FOCUS_NONE
	var styles := HBoxContainer.new()
	journal_rows.add_child(styles)
	for entry in [["standard","Guardia · gratis"],["ember","Brasa · 6 monedas"],["mist","Niebla · 6 monedas"],["seal","Custodio · 12 + 1 sello"]]:
		var style_id: String = entry[0]
		var choice := button(styles,entry[1],func(): cosmetic_requested.emit(style_id))
		choice.focus_mode=Control.FOCUS_NONE
		cosmetic_buttons[style_id]=choice
	button(journal_rows, "Cerrar diario", toggle_journal)
	root.add_child(settings)
	root.add_child(population_panel)

func set_worlds(items: Array) -> void:
	var previous: String = str(worlds.get_selected_metadata()) if worlds.selected>=0 else ""
	directory = items
	worlds.clear()
	var preferred := -1
	for w in items:
		worlds.add_item("%s · %d/%d · %s" % [w.name, w.members, w.capacity, "Activa" if w.phase=="active" else "Terminada"])
		worlds.set_item_metadata(worlds.item_count - 1, w.id)
		worlds.set_item_disabled(worlds.item_count-1,w.phase!="active")
		if w.phase=="active" and (preferred<0 or w.id==previous): preferred=worlds.item_count-1
	worlds.select(preferred)
	if preferred<0:
		status.text="No hay partidas activas. Pulsa Nueva partida para empezar con un personaje vivo."
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
	var kind: String = b.get("kind","wall")
	var operation: Dictionary = b.get("operation",{})
	inspection.text="%s · Nivel %d/3 · PV %d/%d\n%s" % [d.name,level+1,b.hp,b.get("maxHp",d.hp),operation.get("description",d.get("description",""))]
	inspection.add_theme_font_size_override("font_size",13)
	if kind in ["well","garden","raincollector"]:
		inspection.text+="\nDisponible: %d/5 · %s" % [b.get("stock",0),"Depósito lleno" if b.get("stock",0)>=5 else "Próxima producción: %d s" % operation.get("nextProduction",0)]
	if distance>4.5: inspection.text+="\nAcércate para usar: %.1f / 4,5 m" % distance
	var primary := {"wall":"Defensa pasiva","gate":"Cerrar portón" if b.get("open",false) else "Abrir portón","spikes":"Trampa automática","workshop":"Fabricar %d balas · 15" % (30+level*6),"infirmary":"Curar %d PV · 10" % (35+level*10),"well":"Beber agua · +40","garden":"Comer · +35","storage":"Retirar materiales"}
	management_buttons.use.text=primary.get(kind,"Usar")
	var extra_names := {"turret":"Cargar 30 balas","generator":"Energía · 20 mat.","recycler":"Reciclar 10 balas","kitchen":"Preparar comida","raincollector":"Beber agua · +40","sandbag":"Defensa pasiva"}
	if extra_names.has(kind): management_buttons.use.text=extra_names[kind]
	for action in ["armor","auto_close","deposit_materials","deposit_ammo","withdraw_ammo"]:
		management_buttons[action].visible=(kind=="workshop" and action=="armor") or (kind=="gate" and action=="auto_close") or (kind=="storage" and action in ["deposit_materials","deposit_ammo","withdraw_ammo"])
		management_buttons[action].disabled=distance>4.5
	for action in ["staff","unstaff","supply_workers"]:
		management_buttons[action].visible=(kind in ["sawmill","quarry"] and action!="supply_workers") or (kind=="shelter" and action=="supply_workers")
		management_buttons[action].disabled=(Vector2(p.x-w.vault.x,p.y-w.vault.y).length()>24+float(w.vault.get("upgrades",0))*6) if action in ["staff","unstaff"] else distance>4.5
	management_buttons.auto_close.text="Auto: SÍ · 5 s" if b.get("autoClose",false) else "Auto: NO"
	management_buttons.armor.disabled=distance>4.5 or p.wood<25 or p.armor>=100
	management_buttons.deposit_materials.disabled=distance>4.5 or p.wood<=0 or b.get("stock",0)>=200+level*100
	management_buttons.deposit_ammo.disabled=distance>4.5 or p.reserve<=0 or b.get("ammoStock",0)>=120+level*60
	management_buttons.withdraw_ammo.disabled=distance>4.5 or b.get("ammoStock",0)<=0
	management_buttons.use.disabled=distance>4.5 or b.get("kind","wall") in ["wall","spikes"]
	if kind=="sandbag": management_buttons.use.disabled=true
	if kind=="well": management_buttons.use.disabled=distance>4.5 or p.get("thirst",100)>=100 or b.get("stock",0)<=0
	if kind=="garden": management_buttons.use.disabled=distance>4.5 or p.get("hunger",100)>=100 or b.get("stock",0)<=0
	if kind=="infirmary": management_buttons.use.disabled=distance>4.5 or p.hp>=100 or p.wood<10
	if kind=="workshop": management_buttons.use.disabled=distance>4.5 or p.wood<15
	if kind=="storage": management_buttons.use.disabled=distance>4.5 or b.get("stock",0)<=0
	management_buttons.repair.disabled=distance>5 or p.wood<10 or b.hp>=b.get("maxHp",d.hp)
	management_buttons.upgrade_structure.text="Nivel máximo" if level>=2 else "Mejorar · %d" % cost
	management_buttons.upgrade_structure.disabled=distance>5 or level>=2 or p.wood<cost
	management_buttons.dismantle.text="Desmontar · +%d" % int(d.cost/2)
	management_buttons.dismantle.disabled=distance>=5
	for button_node in management_buttons.values(): button_node.tooltip_text=button_node.text

func update_communities() -> void:
	communities.clear()
	enter_button.disabled=worlds.selected<0
	if worlds.selected < 0:
		return
	for c in directory[worlds.selected].communities:
		communities.add_item("%s · %d/10" % [c.name, c.members])
		communities.set_item_metadata(communities.item_count - 1, c.id)

func enter_selection() -> void:
	if worlds.selected >= 0 and communities.selected >= 0:
		if directory[worlds.selected].phase!="active":
			notify_action("Esta partida terminó. Crea una nueva para jugar.",false)
			return
		enter_requested.emit(worlds.get_selected_metadata(), communities.get_selected_metadata(), agent_name.text)

func toggle_population() -> void:
	if not lobby.visible:
		journal.hide()
		settings.hide()
		population_panel.visible=not population_panel.visible

func toggle_journal() -> void:
	if not lobby.visible:
		population_panel.hide()
		settings.hide()
		journal.visible = not journal.visible

func show_state(w: Dictionary, p: Dictionary, building: bool) -> void:
	lobby.hide()
	population_panel.update_state(w,p)
	building_mode=building
	help_label.visible=not building
	rebuild_button.visible=w.vault.hp<=0 and p.alive and w.phase=="active"
	build_toggle.disabled=not p.alive or w.phase!="active"
	equip_button.text="Q  "+str(w.get("adventure",{}).get("weapon",{}).get("name","Pistola")) if p.get("equipped","weapon")=="tool" else "Q  Hacha-pico"
	build_toggle.text="B  Volver al personaje" if building else "B  Construir"
	health.value=p.hp
	hunger_bar.value=p.get("hunger",100)
	water_bar.value=p.get("thirst",100)
	stamina.value=p.get("stamina",100)
	pause_button.text="P  Continuar" if w.get("adventure",{}).get("paused",false) else "P  Pausa"
	build_panel.visible=building
	if catalog_ids.is_empty():
		for item in w.get("buildingCatalog",[]):
			var kind: String = item.id
			catalog_ids.append(kind)
			var shortcut := "%d " % catalog_ids.size() if catalog_ids.size()<=8 else ""
			var b := button(build_buttons,"%s%s · %d" % [shortcut,item.name,item.cost],func(): structure_chosen.emit(kind))
			b.tooltip_text=item.description
			b.focus_mode=Control.FOCUS_NONE
			b.clip_text=true
			b.custom_minimum_size.x=130
			b.add_theme_font_size_override("font_size",12)
	for i in range(build_buttons.get_child_count()):
		var item: Dictionary = w.buildingCatalog[i]
		var b: Button = build_buttons.get_child(i)
		var group := 1 if item.id in ["wall","gate","spikes","sandbag","turret"] else (2 if item.id in ["well","garden","infirmary","kitchen","raincollector","shelter"] else 3)
		b.visible=category.selected==0 or category.selected==group
		b.modulate=Color.WHITE if Placement.can_pay(p,item) else Color("8e9aa3")
		b.tooltip_text=item.name+"\n"+item.description+"\n"+Placement.recipe_text(item)+"\nRecuperados: sustituyen cualquier material"
	minimap.update_state(w, p.id)
	var siege_state: Dictionary = w.get("siege", {})
	var seconds := int(ceil(float(siege_state.get("remaining", 0)) / 1000))
	siege.text = "%s · %02d:%02d\nRequiere defensores conectados" % ["ASEDIO ACTIVO" if siege_state.get("active", false) else "Próximo asedio", seconds / 60, seconds % 60]
	siege.visible = siege_state.get("enabled", false)
	siege.modulate = Color("f0ad83") if siege_state.get("active", false) else Color("ced9c3")
	stats.text = "  %s · PV %d · Blindaje %d · Pistola %d / %d\n  Materiales %d · Bóveda %d · Oleada %d · %s" % [p.name, p.hp, p.armor, p.ammo, p.reserve, p.wood, w.vault.hp, w.wave, "PLANO ACTIVO" if building else ("HACHA-PICO" if p.get("equipped","")=="tool" else str(w.get("adventure",{}).get("weapon",{}).get("name","Pistola")).to_upper())]
	stats.text += "\n  Alimento %d · Agua %d%s" % [p.get("hunger",100),p.get("thirst",100)," · RECARGANDO %.1f s" % p.reload if p.reload>0 else ""]
	stats.text=stats.text.replace("Pistola",w.get("adventure",{}).get("weapon",{}).get("name","Pistola"))
	stats.text += "\n  Mochila: H comida %d · Y agua %d · N botiquín %d" % [p.get("food",0),p.get("water",0),p.get("medical",0)]
	var threat: Dictionary = w.get("adventure",{}).get("threat",{})
	if not threat.is_empty(): stats.text+="\n  Oleada prevista: %d s · Amenaza %d/3" % [threat.seconds,threat.level]
	if p.get("equipped","weapon")=="tool":
		stats.text=stats.text.replace("PISTOLA","HACHA-PICO")
		objective.text="Apunta al tronco o roca · Mantén clic · Alcance 3,2 m"
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
		var seconds_left := maxi(0,int(ceil((float(p.get("respawn",0))-Time.get_unix_time_from_system()*1000)/1000)))
		objective.text = "  HAS CAÍDO · Reapareces en %d s." % seconds_left if seconds_left>0 else "  Reapareciendo: buscando un lugar libre cerca de tu bóveda…"
	elif p.get("prologue", 0) == 0:
		objective.text = "  E: recupera la radio junto al transporte."
	elif not p.get("intro", false):
		objective.text = "  Alcanza tu bóveda y pulsa E."
	else:
		objective.text = "  J: señales de los magos · %d/6 claves · Maná %d" % [story.get("fragments", []).size(), p.magic.mana]
	var account: Dictionary = w.get("cosmetics",{})
	for style_id in cosmetic_buttons:
		var item: Dictionary = account.get("catalog",{}).get(style_id,{})
		var owned: bool = style_id in account.get("owned",[])
		var equipped: bool = style_id==account.get("equipped","standard")
		var choice: Button = cosmetic_buttons[style_id]
		choice.text=("Activo: " if equipped else "Equipar: ")+str(item.get("name",style_id)) if owned else str(item.get("name",style_id))+" · %d monedas" % item.get("coins",0)+(" + 1 sello" if item.get("seals",0)>0 else "")
		choice.disabled=equipped or item.is_empty() or (not owned and (account.get("coins",0)<item.get("coins",0) or account.get("seals",0)<item.get("seals",0)))
		choice.tooltip_text="Aspecto visual sin ventaja de combate. Las monedas y los sellos se obtienen al completar una campaña."
	var campaign: Dictionary = w.get("adventure",{})
	var text := "EL CERCO · %s · Día real %d/30\nCUENTA: %d monedas · %d sellos cosméticos\n\nLAS SEIS VOCES DEL SELLO\n\n" % [campaign.get("campaignPhase","Llegada"),campaign.get("campaignDay",1),account.get("coins",0),account.get("seals",0)]
	text+="Aspecto: "+str(account.get("equipped","standard"))+" · Comprar equipa; los adquiridos se cambian gratis.\n"
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
	magic.visible = not building and not p.magic.known.is_empty()
	for fragment in story.get("fragments", []):
		text += "\n" + str(fragment.text)
	text += "\n\nSello: abierto" if story.get("opened", false) else "\n\nSello: reúne seis claves y pulsa E en (105, 105)."
	var adventure: Dictionary = w.get("adventure",{})
	text+="\n\nEXPEDICIONES · Señales turquesas del mapa\nHospital: comida y botiquines · Estación: agua y chatarra\nLaboratorio: componentes para nuevas armas. E registra la zona.\nEntrega cada informe con E en tu bóveda: investigación +1.\nFabricación de armas: acércate a un taller; el cambio devuelve las balas.\n"
	text+="Informes entregados: %d\nRefugios: 2 plazas cada uno. Hospitales rescatan trabajadores.\nAserraderos/canteras necesitan trabajador y recurso vivo a 10 m.\nLaboratorio: mejora extracción y torretas; sintetiza la cura.\nVictoria: una comunidad viva + sus seis claves + su derrota del Paciente 0.\nAntes de 30 días reales; las monedas de cuenta solo son cosméticas.\n" % p.get("expeditions",0)
	text+="\nSUMINISTROS Y AMENAZA\nZombis comunes: 1–2 balas; comida, agua y botiquines ocasionales.\nC fabrica munición; un taller mejora el rendimiento.\nPuestos mejorados: extraen en 16/12 s; investigar aumenta su carga.\nOleadas: 60 s de día y 45 s de noche; niveles 1, 2 y 3 cada tres oleadas.\nLa primera oleada de una partida nueva llega a los 90 s.\n"
	for site in adventure.get("sites",[]):
		text+="%s (%d, %d)\n" % [site.name,site.x,site.y]
		if site.get("encounter") is Dictionary: text+=str(site.get("hint",""))+"\n"
	text+="\nINTERIORES: radio/energía amarilla → sala del objetivo turquesa.\nElimina la amenaza y permanece junto al paciente o archivo; después E recoge el informe.\nDispones de 180 s de tiempo jugado. La dificultad cambia con la fase del mes.\n"
	for entry in adventure.get("expeditionHistory",[]): text+="Completado: %s · %s\n" % [entry.title,entry.phase]
	var population: Dictionary = w.get("population",{})
	text+="\nPOBLACIÓN: %d / %d plazas · %d trabajando\nReservas donadas: %d comida, %d agua · Alimentados: %d s\nConsumo cada minuto: %d comida y agua (también usa huertos y pozos).\n" % [population.get("residents",0),population.get("capacity",0),population.get("working",0),population.get("food",0),population.get("water",0),population.get("fedSeconds",0),population.get("rationCost",0)]
	for job in population.get("jobs",[]): text+="%s (%d,%d): %s · reserva %d/60\n" % ["Aserradero" if job.kind=="sawmill" else "Cantera",job.x,job.y,"Trabajando" if job.working else job.reason,job.stock]
	text+="\nJEFES: Cantor cura; Sepulturero levanta hasta 2 caídos; Heraldo acelera y refuerza la horda; Portador descarga en área.\nDurante la preparación, 80 de daño interrumpen su habilidad. El Paciente 0 no se interrumpe.\n"
	if adventure.get("incident") is Dictionary:
		var event: Dictionary = adventure.incident
		if last_incident!=str(w.id)+str(event.id):
			last_incident=str(w.id)+str(event.id)
			notify_action("Radio: "+str(event.title)+" · señal dorada del mapa · J para detalles",true)
		text+="\nSEÑAL DE RADIO: %s · %d s\n%s\nDestino (%d,%d) · E para recuperar: %s\n" % [event.title,maxi(0,int(event.endsAt-adventure.elapsed)),event.description,event.x,event.y,event.reward]
	text+="\nCOLECTORES: accesos violetas cerca del cruce central. E baja a una galería por 25 resistencia. Recorre el interior, abre la válvula y registra el armario. E en la otra escalera sale gratis; espera entre accesos: 3 s.\n"
	journal_text.text = text
	if p.get("intro",false) and p.alive:
		var guide: Dictionary = adventure.get("guide",{})
		objective.text="%d/5 · %s" % [guide.get("step",0),guide.get("text","")]
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x=390
	objective.max_lines_visible=2
	objective.add_theme_font_size_override("font_size",12)
	var materials: Dictionary = p.get("materials",{})
	stats.text+="\n  Madera %d · Piedra %d · Chatarra %d\n  Recuperados %d · Componentes %d" % [materials.get("timber",0),materials.get("stone",0),materials.get("scrap",0),materials.get("reclaimed",0),materials.get("components",0)]
	help_label.text="WASD mover · Mayús correr · Espacio esquivar · R recargar\nQ hacha-pico · B construir · E usar · V registrar · J diario y armas\nH comida · Y agua · N botiquín · O comunidad · P pausa individual"
	if p.get("cargo") is Dictionary: objective.text="INFORME: vuelve a tu bóveda y pulsa E · "+str(p.cargo.site)
	for site in adventure.get("sites",[]):
		if Vector2(site.x-p.x,site.y-p.y).length()<=4:
			objective.text="E · Registrar "+str(site.name)+" · Entrega después el informe en tu bóveda"
			if site.has("interior"): objective.text=str(site.get("hint",""))
	for passage in adventure.get("passages",[]):
		if Vector2(passage.x-p.x,passage.y-p.y).length()<=3: objective.text="E · Cruzar "+str(passage.name)+" · %d resistencia" % passage.get("cost",25)
	if p.get("sample",false): objective.text="MUESTRA DEL ORIGEN · E en tu laboratorio: sintetizar cura (6 claves + 3 informes)"
	if adventure.get("paused",false): objective.text="PARTIDA PAUSADA · P para continuar"
	status.text="Día %d · %s · Cambio en %d s · Energía %d" % [adventure.get("day",1),("Noche" if adventure.get("night",false) else "Día")+(" / Lluvia" if adventure.get("weather","")=="rain" else ""),adventure.get("nextPhase",360),p.get("stamina",100)]
	if w.vault.hp<=0 and p.alive: objective.text="BÓVEDA DESTRUIDA · K cerca del núcleo: reconstruir por 100 materiales"
	if not w.has("resources"):
		status.text="Servidor antiguo: ciérralo con Ctrl+C y ejecuta node tools/start-godot.mjs para cargar árboles y rocas."
	if p.get("equipped","weapon")=="tool" and p.alive and w.phase=="active" and not adventure.get("paused",false): objective.text="Q: arma · Clic en árbol o roca a menos de 3,2 m"

	for room in adventure.get("collectors",[]):
		if absf(room.x-p.x)<12 and absf(room.y-p.y)<5.5 and p.alive and w.phase=="active" and not adventure.get("paused",false):
			var safe: bool = room.get("purgedUntil",0)>Time.get_unix_time_from_system()*1000
			objective.text="GALERÍA · Gas: abre la válvula azul con E; consume resistencia y luego salud" if not safe else "GALERÍA VENTILADA · E en el armario recoge suministros · Busca la otra escalera"
			for passage in adventure.get("passages",[]):
				if passage.get("interior",false) and Vector2(passage.x-p.x,passage.y-p.y).length()<=3: objective.text="E · Salir de la galería · Sin coste de resistencia"
