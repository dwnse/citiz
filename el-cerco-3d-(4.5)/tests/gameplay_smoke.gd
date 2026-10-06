extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://world/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var network = game.get_node("Network")
	var directory: Dictionary = await network.request_json("/api/worlds")
	if not directory.has("worlds"):
		quit(1)
		return
	game.hud.set_worlds(directory.worlds)
	game.hud.open_menu_selection()
	game.hud.agent_name.text = "Agente Godot"
	game.hud.enter_button.pressed.emit()
	var deadline := Time.get_ticks_msec() + 5000
	while (not network.connected or game.hud.gameplay_overlay.last_player.is_empty()) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	if not network.connected or game.hud.modal_layer.visible or game.hud.lobby.visible:
		push_error("Gameplay transition failed")
		quit(1)
		return
	var overlay = game.hud.gameplay_overlay
	if overlay.tiles.size() != 5 or game.hud.equip_button.get_parent() != overlay.action_row:
		push_error("Original action buttons not preserved")
		quit(1)
		return
	var c: Vector2 = game.hud.minimap.size * 0.5
	for corner in [Vector2.ZERO, Vector2(220, 0), Vector2(0, 220), Vector2(220, 220)]:
		if game.hud.minimap.point(corner.x, corner.y).distance_to(c) > 90:
			push_error("Landmark outside circular map")
			quit(1)
			return
	await create_timer(1.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/hud-gameplay.png"))
	game.hud.toggle_journal()
	await create_timer(0.25).timeout
	if not game.hud.modal_layer.visible or game.playable():
		push_error("Journal does not block gameplay")
		quit(1)
		return
	game.hud.toggle_journal()
	if game.hud.modal_layer.visible or not game.playable():
		push_error("Closing journal does not restore gameplay")
		quit(1)
		return
	# Validate availability and payloads with a deterministic UI fixture.
	var fixture: Dictionary = overlay.last_player.duplicate(true)
	var world_fixture: Dictionary = overlay.last_world.duplicate(true)
	fixture["medical"] = 2
	fixture["hp"] = 50
	overlay.update_state(world_fixture, fixture, false)
	if overlay.supplies[0].button.disabled:
		push_error("Available medical supply cannot be used")
		quit(1)
		return
	var actions: Array = []
	game.hud.quick_action_requested.connect(func(action, payload): actions.append([action, payload]))
	overlay.supplies[0].button.pressed.emit()
	if actions != [["consume", {"item": "medical"}]]:
		push_error("Medical button sends wrong command")
		quit(1)
		return
	fixture["hp"] = 100
	overlay.update_state(world_fixture, fixture, false)
	if not overlay.supplies[0].button.disabled:
		push_error("Medical supply enabled at full health")
		quit(1)
		return
	world_fixture["adventure"]["paused"] = true
	overlay.update_state(world_fixture, fixture, false)
	if not overlay.reload_button.disabled or not overlay.state_badge.text.begins_with("PAUSA"):
		push_error("Paused HUD remains actionable")
		quit(1)
		return
	fixture["magic"] = {"known": ["heal"], "mana": 100, "cooldowns": {"heal": (Time.get_unix_time_from_system() + 5) * 1000}}
	world_fixture["story"]["spells"] = [{"id": "heal", "key": "2", "cost": 20, "name": "Curar"}]
	world_fixture["adventure"]["paused"] = false
	overlay.update_state(world_fixture, fixture, false)
	if not overlay.power_buttons["heal"].disabled:
		push_error("Power enabled during cooldown")
		quit(1)
		return
	fixture["magic"]["cooldowns"] = {}
	overlay.update_state(world_fixture, fixture, false)
	if overlay.power_buttons["heal"].disabled:
		push_error("Ready power is not available")
		quit(1)
		return
	print("HUD_SMOKE failures=0")
	network.disconnect_world()
	game.queue_free()
	await process_frame
	quit()