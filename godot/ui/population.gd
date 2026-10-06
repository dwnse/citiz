extends PanelContainer
signal command(action: String, id: String)
signal resident_order(order: String, id: String)
var summary := Label.new()
var jobs := VBoxContainer.new()
var job_rows: Dictionary = {}
var residents := OptionButton.new()
var resident_status := Label.new()
var resident_ids: Array[String] = []
var resident_buttons: Array[Button] = []
var people: Array = []

func _ready() -> void:
	position=Vector2(355,75)
	custom_minimum_size=Vector2(590,390)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",12)
	add_child(rows)
	var title := Label.new()
	title.text="EL CERCO / COMUNIDAD"
	rows.add_child(title)
	summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size=Vector2(550,90)
	rows.add_child(summary)
	rows.add_child(residents)
	residents.item_selected.connect(func(_index): update_resident_status())
	resident_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	resident_status.custom_minimum_size=Vector2(550,42)
	rows.add_child(resident_status)
	var orders := HBoxContainer.new()
	rows.add_child(orders)
	for entry in [["move","Mover…"],["hold","Detener"],["return","Al refugio"],["auto","Trabajo automático"]]:
		var order: String = entry[0]
		var button := Button.new()
		button.text=entry[1]
		button.focus_mode=Control.FOCUS_NONE
		button.pressed.connect(func():
			if residents.selected>=0 and residents.selected<resident_ids.size():
				resident_order.emit(order,resident_ids[residents.selected])
		)
		orders.add_child(button)
		resident_buttons.append(button)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(555,130)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(scroll)
	scroll.add_child(jobs)
	var close := Button.new()
	close.text="Volver · O / Esc"
	close.focus_mode=Control.FOCUS_NONE
	close.pressed.connect(hide)
	rows.add_child(close)
	hide()

func update_state(w: Dictionary,p: Dictionary) -> void:
	var pop: Dictionary = w.get("population",{})
	summary.text="Rescatados %d / %d plazas · Trabajando %d\nReservas donadas: %d comida y %d agua · Alimentados %d s\nCada minuto: %d comida + agua; usa también huertos y pozos.\nLas órdenes funcionan desde tu base. Dona suministros en un refugio." % [pop.get("residents",0),pop.get("capacity",0),pop.get("working",0),pop.get("food",0),pop.get("water",0),pop.get("fedSeconds",0),pop.get("rationCost",0)]
	var forecast: Dictionary = pop.get("forecast",{})
	if not forecast.is_empty():
		summary.text+="\nSaldo teórico/min: %+.1f comida · %+.1f agua" % [forecast.foodBalance,forecast.waterBalance]
		if forecast.foodBalance<0 or forecast.waterBalance<0: summary.text+="\nProducción insuficiente: añade huertos/pozos o dona raciones."
		summary.tooltip_text="Producción máxima menos raciones de residentes. No incluye consumo del jugador, reservas llenas ni desconexión. La lluvia y las mejoras cambian la producción."
	var can_manage: bool = p.get("alive",false) and not w.get("adventure",{}).get("paused",false) and Vector2(p.x-w.vault.x,p.y-w.vault.y).length()<=24+float(w.vault.get("upgrades",0))*6
	people=pop.get("people",[])
	var ids: Array[String] = []
	for person in people: ids.append(str(person.id))
	if ids!=resident_ids:
		var old := resident_ids[residents.selected] if residents.selected>=0 and residents.selected<resident_ids.size() else ""
		resident_ids=ids
		residents.clear()
		for person in people: residents.add_item(str(person.name))
		if old in resident_ids: residents.select(resident_ids.find(old))
	update_resident_status()
	for button in resident_buttons:
		button.disabled=not can_manage or people.is_empty()
		button.tooltip_text="Vuelve a tu base para dar órdenes" if not can_manage else "Las órdenes manuales suspenden el trabajo; conserva la carga."
	var keep := {}
	for job in pop.get("jobs",[]):
		var id: String = job.id
		keep[id]=true
		if not job_rows.has(id):
			var row := HBoxContainer.new()
			jobs.add_child(row)
			var label := Label.new()
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size=Vector2(330,55)
			label.add_theme_font_size_override("font_size",13)
			row.add_child(label)
			var buttons: Array[Button] = []
			for entry in [["staff","Priorizar"],["unstaff","Pausar"]]:
				var action: String = entry[0]
				var button := Button.new()
				button.text=entry[1]
				button.focus_mode=Control.FOCUS_NONE
				button.pressed.connect(func(): command.emit(action,id))
				row.add_child(button)
				buttons.append(button)
			job_rows[id]={"row":row,"label":label,"buttons":buttons}
		job_rows[id].label.text="%s (%d,%d) · %d/60\n%s" % ["Aserradero" if job.kind=="sawmill" else "Cantera",job.x,job.y,job.stock,job.reason if job.get("reason","")!="" else "Trabajando"]
		for button in job_rows[id].buttons: button.disabled=not can_manage
	for id in job_rows.keys():
		if not keep.has(id):
			job_rows[id].row.queue_free()
			job_rows.erase(id)

func update_resident_status() -> void:
	if residents.selected<0 or residents.selected>=people.size():
		resident_status.text="Sin residentes: rescata supervivientes y construye refugios."
		return
	var person: Dictionary = people[residents.selected]
	var cargo = person.get("cargo")
	resident_status.text="%s · (%d, %d)\n%s" % [person.get("status",""),person.x,person.y,"Carga: %d materiales" % cargo.amount if cargo is Dictionary else "Sin carga · Mover: elige después un punto en el suelo"]
