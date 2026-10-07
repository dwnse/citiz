extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://world/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var network = game.get_node("Network")
	var directory: Dictionary = await network.request_json("/api/worlds")
	game.hud.set_worlds(directory.worlds)
	game.hud.open_menu_selection()
	game.hud.agent_name.text = "Superviviente"
	game.hud.enter_button.pressed.emit()
	var deadline := Time.get_ticks_msec() + 6000
	while (game.me.is_empty() or int(game.me.get("medical", 0)) != 3) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	if game.me.is_empty():
		push_error("Connection failed")
		quit(1)
		return
	var panel = game.hud.inventory_panel
	check(game.hud.backpack_button.get_global_rect().position.x > 0 and game.hud.backpack_button.get_global_rect().position.y > 0, "Backpack button offscreen")
	var click := InputEventMouseButton.new()
	click.position = game.hud.backpack_button.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	click.pressed = false
	Input.parse_input_event(click)
	await process_frame
	check(panel.visible and game.hud.modal_open and not game.playable(), "Inventory does not block gameplay")
	check(panel.model != null and panel.preview_meshes.size() > 0, "Character preview missing")
	panel.select_item("medical")
	panel.use_button.pressed.emit()
	await create_timer(0.65).timeout
	check(int(game.me.medical) == 2 and game.me.hp > 70, "Medical did not change authoritative stock and health")
	panel.select_item("food")
	panel.activate()
	await create_timer(0.65).timeout
	check(int(game.me.food) == 2 and game.me.hunger > 70, "Food did not change authoritative stock and hunger")
	panel.select_item("water")
	panel.activate()
	await create_timer(0.65).timeout
	check(int(game.me.water) == 2 and game.me.thirst > 75, "Water did not change authoritative stock and thirst")
	var quick_key := InputEventKey.new()
	quick_key.physical_keycode = KEY_1
	quick_key.pressed = true
	Input.parse_input_event(quick_key)
	await create_timer(0.65).timeout
	check(game.me.equipped == "tool", "Tool did not equip")
	panel.select_item("shotgun")
	panel.activate()
	await create_timer(0.65).timeout
	check(game.me.weapon == "shotgun" and game.me.equipped == "weapon", "Owned weapon did not equip")
	panel.select_item("ammo")
	panel.activate()
	await create_timer(2.7).timeout
	check(game.me.ammo == 6, "Weapon did not reload")
	var materials_before: int = game.me.wood
	var ammo_before: int = game.me.reserve
	panel.craft_button.pressed.emit()
	await create_timer(0.65).timeout
	check(game.me.wood == materials_before - 15 and game.me.reserve == ammo_before + 18, "Ammo recipe did not pay materials and produce ammunition")
	panel.swap_slots(0, 29)
	check(panel.order[29] == "pistol" and panel.order[0] == "", "Slot move failed")
	check(panel.count("pistol") == 1, "Moving a slot changed ownership")
	var saved_layout := ConfigFile.new()
	check(saved_layout.load("user://inventory_layout.cfg") == OK and saved_layout.get_value(panel.last_profile, "order", []) == panel.order, "Slot arrangement was not saved")
	panel.swap_slots(0, 29)
	panel.select_item("rifle")
	var prior: int = game.me.wood
	panel.activate()
	await create_timer(0.65).timeout
	check(game.me.wood == prior and not "rifle" in game.me.weapons, "Weapon fabricated without a workshop")
	panel.select_item("food")
	game.hud.toast_seconds = 0
	Input.warp_mouse(Vector2(8, 8))
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/inventory-survival.png"))
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await process_frame
	check(not panel.visible and not game.hud.modal_open and game.playable(), "Close does not restore gameplay")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_I
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(panel.visible, "I did not reopen inventory")
	game.hud.toggle_journal()
	check(not panel.visible and game.hud.journal.visible, "Inventory overlaps journal")
	game.hud.toggle_journal()
	game.hud.toggle_inventory()
	var fixture: Dictionary = game.me.duplicate(true)
	fixture.hp = 100
	panel.update_state(game.state, fixture)
	panel.select_item("medical")
	check(panel.use_button.disabled, "Medical enabled at full health")
	fixture.medical = 0
	fixture.hp = 30
	panel.update_state(game.state, fixture)
	check(panel.use_button.disabled, "Medical enabled with no stock")
	var paused: Dictionary = game.state.duplicate(true)
	paused.adventure.paused = true
	panel.update_state(paused, game.me)
	check(panel.use_button.disabled and panel.craft_button.disabled, "Paused inventory allows actions")
	root.size = Vector2i(960, 540)
	await process_frame
	check(panel.sheet.get_global_rect().end.x <= panel.get_viewport_rect().size.x and panel.sheet.get_global_rect().end.y <= panel.get_viewport_rect().size.y, "Inventory overflows small window")
	fixture.alive = false
	panel.update_state(game.state, fixture)
	check(not panel.visible, "Death did not close inventory")
	print("INVENTORY_SMOKE failures=", failures)
	network.disconnect_world()
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
