extends PanelContainer
signal command(action: String, id: String)
var summary := Label.new()
var jobs := VBoxContainer.new()
var job_rows: Dictionary = {}

func _ready() -> void:
	position=Vector2(355,145)
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
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(555,190)
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
	var can_manage: bool = p.get("alive",false) and not w.get("adventure",{}).get("paused",false) and Vector2(p.x-w.vault.x,p.y-w.vault.y).length()<=24+float(w.vault.get("upgrades",0))*6
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
