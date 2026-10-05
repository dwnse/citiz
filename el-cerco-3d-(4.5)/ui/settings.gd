extends PanelContainer
signal shadows_changed(enabled: bool)
var preferences := ConfigFile.new()
var volume := HSlider.new()
var shadows := CheckButton.new()
var limit := OptionButton.new()
var fullscreen := CheckButton.new()

func _ready() -> void:
	position=Vector2(420,180)
	custom_minimum_size=Vector2(440,300)
	preferences.load("user://preferences.cfg")
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",12)
	add_child(rows)
	var title := Label.new()
	title.text="EL CERCO / AJUSTES"
	rows.add_child(title)
	var info := Label.new()
	info.text="La pausa individual se activa con P.\nEn multijugador el mundo sigue activo."
	rows.add_child(info)
	var label := Label.new()
	label.text="Volumen"
	rows.add_child(label)
	volume.min_value=0
	volume.max_value=100
	volume.value=preferences.get_value("audio","volume",70)
	rows.add_child(volume)
	volume.value_changed.connect(func(value):
		AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,value/100)))
		preferences.set_value("audio","volume",value)
		preferences.save("user://preferences.cfg")
	)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,volume.value/100)))
	shadows.text="Sombras (desactiva para mejorar rendimiento)"
	shadows.button_pressed=preferences.get_value("video","shadows",true)
	rows.add_child(shadows)
	shadows.toggled.connect(func(enabled):
		shadows_changed.emit(enabled)
		preferences.set_value("video","shadows",enabled)
		preferences.save("user://preferences.cfg")
	)
	for text in ["Límite: 144 FPS","Límite: 60 FPS"]: limit.add_item(text)
	limit.select(int(preferences.get_value("video","limit",0)))
	rows.add_child(limit)
	limit.item_selected.connect(func(index):
		Engine.max_fps=144 if index==0 else 60
		preferences.set_value("video","limit",index)
		preferences.save("user://preferences.cfg")
	)
	Engine.max_fps=144 if limit.selected==0 else 60
	fullscreen.text="Pantalla completa"
	fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	rows.add_child(fullscreen)
	fullscreen.toggled.connect(func(enabled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	var close := Button.new()
	close.text="Volver · Esc"
	rows.add_child(close)
	close.pressed.connect(hide)
	hide()
