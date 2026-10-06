extends SceneTree
class Fixture:
	extends Node
	var selected_world := ""

var failures := 0
var refreshed := 0
var created := 0
var reconnected := 0
var entered: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
	else:
		print("PASS ", label)

func run() -> void:
	var fixture := Fixture.new()
	root.add_child(fixture)
	var hud = preload("res://ui/hud.gd").new()
	fixture.add_child(hud)
	hud.refresh_requested.connect(func(): refreshed += 1)
	hud.create_requested.connect(func(): created += 1)
	hud.reconnect_requested.connect(func(): reconnected += 1)
	hud.enter_requested.connect(func(world, community, agent): entered = [world, community, agent])
	await process_frame
	await process_frame
	check(hud.lobby.visible and not hud.start_menu.selection.visible, "home visible; selector closed")
	check(not hud.minimap.visible and not hud.help_label.visible, "game HUD hidden on home")
	check(hud.start_menu.continue_button.disabled, "continue unavailable before a session")
	check(hud.start_menu.exit_button.disabled, "unapproved exit has no action")
	hud.start_menu.size = Vector2(1280, 720)
	hud.start_menu.fit_art()
	check(absf(hud.start_menu.frame.scale.x - 720.0 / 941.0) < 0.001, "art keeps reference proportions")
	hud.status.text = "Desconectado. La plaza y el inventario se conservan."
	await process_frame
	await process_frame
	check(hud.start_menu.message.text == hud.status.text, "caption reflects live connection status")
	await capture(hud, "home")
	hud.start_menu.frame.get_node("Jugar").pressed.emit()
	check(hud.start_menu.selection.visible, "play opens existing selector")
	hud.set_worlds([{"id":"test-world","name":"Ciudad cercada","members":0,"capacity":40,"phase":"active","communities":[{"id":"forest","name":"Vigías del Bosque","members":1},{"id":"mountain","name":"Guardia de la Cumbre","members":2},{"id":"city","name":"Pacto del Asfalto","members":0},{"id":"underground","name":"Custodios del Umbral","members":0}]}])
	check(hud.modal_layer.visible and not hud.start_menu.frame.get_node("Configuración").visible, "modal hides background hit targets")
	await process_frame
	await process_frame
	var overlap_point: Vector2 = hud.agent_name.get_global_rect().position + Vector2(15, 10)
	var move := InputEventMouseMotion.new()
	move.position = overlap_point
	root.push_input(move)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = overlap_point
	click.pressed = true
	root.push_input(click)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await process_frame
	check(root.gui_get_focus_owner() == hud.agent_name and not hud.settings.visible, "overlapping click reaches name field, never background configuration")
	var outside := InputEventMouseButton.new()
	outside.button_index = MOUSE_BUTTON_LEFT
	outside.position = Vector2(100, 460)
	outside.pressed = true
	root.push_input(outside)
	outside = outside.duplicate()
	outside.pressed = false
	root.push_input(outside)
	check(not hud.settings.visible and hud.start_menu.selection.visible, "outside modal blocks underlying menu actions")
	check(hud.community_cards.cards.size() == 4, "four live community cards")
	hud.community_cards.cards[1].pressed.emit()
	check(hud.communities.get_selected_metadata() == "mountain", "illustrated card selects original community metadata")
	hud.community_cards.cards[0].pressed.emit()
	hud.agent_name.text = "Agente prueba"
	hud.enter_button.pressed.emit()
	check(entered == ["test-world", "forest", "Agente prueba"], "enter retains world, community and name")
	var menu: VBoxContainer = hud.start_menu.selection.get_child(0)
	for child in menu.get_children():
		if child is Button and child.text == "Actualizar partidas":
			child.pressed.emit()
		if child is Button and child.text == "Nueva partida":
			child.pressed.emit()
	check(refreshed == 1 and created == 1, "refresh and create retain original signals")
	await capture(hud, "partidas")
	hud.start_menu.frame.get_node("Configuración").pressed.emit()
	check(hud.settings.visible and not hud.start_menu.selection.visible, "configuration opens existing settings")
	await capture(hud, "ajustes")
	hud.settings.hide()
	check(not hud.modal_layer.visible and hud.start_menu.frame.get_node("Jugar").visible, "closing submenu restores home input")
	for panel in [hud.settings, hud.population_panel, hud.journal, hud.build_panel, hud.inspector]:
		check(panel.theme != null and panel.theme.default_font != null, "illustrated theme applied: " + str(panel.get_instance_id()))
	hud.journal_text.text = "LAS SEIS VOCES DEL SELLO\n\nReúne las seis claves y sigue las señales de los magos.\n\nEXPEDICIONES\nHospital: comida y botiquines. Estación: agua y chatarra.\nLaboratorio: componentes para nuevas armas.\n\nPODERES\nConsulta el maná y la recarga antes de activar una habilidad."
	hud.journal.show()
	await capture(hud, "diario")
	hud.journal.hide()
	hud.population_panel.update_state({"vault":{"x":0,"y":0},"population":{"residents":0,"capacity":2,"working":0,"food":15,"water":20,"fedSeconds":60,"rationCost":0,"people":[],"jobs":[]}}, {"x":0,"y":0,"alive":true})
	hud.population_panel.show()
	await capture(hud, "comunidad")
	hud.population_panel.hide()
	hud.lobby.hide()
	for title in ["Muro · 10", "Portón · 25", "Pozo · 30", "Huerto · 30", "Taller · 40", "Refugio · 45"]:
		hud.button(hud.build_buttons, title, func(): pass)
	hud.build_hint.text = "Selecciona una estructura para colocar el plano.\nLos materiales y costes se conservan."
	hud.build_panel.show()
	await capture(hud, "construccion")
	await process_frame
	await process_frame
	check(hud.build_panel.position.y + hud.build_panel.size.y <= 720, "construction panel fits viewport")
	hud.build_panel.hide()
	hud.inspection.text = "Portón · Nivel 1/3 · PV 100/100\nAbre o cierra el acceso de tu base."
	hud.inspector.show()
	await capture(hud, "gestion")
	await process_frame
	await process_frame
	check(hud.inspector.position.y + hud.inspector.size.y <= 720, "management panel fits viewport")
	hud.inspector.hide()
	hud.lobby.show()
	fixture.selected_world = "test-world"
	await process_frame
	await process_frame
	check(not hud.start_menu.continue_button.disabled, "continue available after selecting a session")
	hud.start_menu.continue_button.pressed.emit()
	hud.start_menu.reconnect_button.pressed.emit()
	check(reconnected == 2, "continue and reconnect use original reconnect signal")
	hud.start_menu.selection.show()
	hud.agent_name.grab_focus()
	hud.lobby.hide()
	check(not hud.start_menu.selection.visible and not hud.modal_layer.visible, "entering closes selector and removes input blocker")
	check(root.gui_get_focus_owner() != hud.agent_name, "entering releases name input focus")
	check(hud.minimap.visible and hud.help_label.visible, "game HUD restored upon entry")
	hud.lobby.show()
	check(not hud.minimap.visible and not hud.start_menu.selection.visible, "leaving restores clean home")
	hud.set_worlds([])
	check(hud.community_cards.cards.is_empty(), "empty directory clears visual cards")
	check(hud.enter_button.disabled, "empty directory still disables entering")
	print("MENU_SMOKE failures=", failures)
	fixture.queue_free()
	await process_frame
	quit(1 if failures else 0)

func capture(hud, label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	await process_frame
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/menu-" + label + ".png")
	root.get_texture().get_image().save_png(path)