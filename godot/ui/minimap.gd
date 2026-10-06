extends Control
var world: Dictionary = {}
var player_id := ""

func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_state(value: Dictionary, viewer: String) -> void:
	world = value
	player_id = viewer
	queue_redraw()

func point(x: float, y: float) -> Vector2:
	# An inscribed square retains every world landmark within the circular frame.
	var span := (minf(size.x, size.y) - 24.0) / sqrt(2.0)
	return size * 0.5 + (Vector2(x, y) / float(world.get("size", 220)) - Vector2(0.5, 0.5)) * span

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 5
	draw_circle(center + Vector2(0, 3), radius + 4, Color("050906aa"))
	draw_circle(center, radius, Color("243721ee"))
	draw_arc(center, radius, 0, TAU, 96, Color("c2a970"), 3, true)
	draw_arc(center, radius - 4, 0, TAU, 96, Color("74633c"), 1, true)
	draw_line(Vector2(center.x - 5, 5), Vector2(center.x + 5, 5), Color("ffdf8a"), 3)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 5, 19), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff0bc"))
	for tick in range(24):
		var angle := float(tick) / 24.0 * TAU
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * (radius - 9), center + direction * (radius - 5), Color("ad9c6266"), 1, true)
	if world.is_empty():
		return
	for community in world.get("communities", []):
		var tint := Color(community.color)
		var location := point(community.x, community.y)
		draw_circle(location, 9, tint.darkened(0.55))
		draw_circle(location, 4, tint if community.vault.hp > 0 else Color("df7667"))
	for site in world.get("adventure",{}).get("sites",[]):
		draw_rect(Rect2(point(site.x,site.y)-Vector2(2,2),Vector2(4,4)),Color("70ccc8"))
	if world.get("adventure",{}).get("incident") is Dictionary:
		var event: Dictionary = world.adventure.incident
		draw_arc(point(event.x,event.y),6,0,TAU,16,Color("ffd17a"),2)
	for resident in world.get("workers",[]): draw_circle(point(resident.x,resident.y),1.5,Color("edc07c"))
	for resource in world.get("resources",[]):
		if resource.hits>0: draw_circle(point(resource.x,resource.y),0.6,Color("708e66") if resource.kind=="tree" else Color("a0a8a6"))
	for zombie in world.get("zombies", []):
		draw_circle(point(zombie.x, zombie.y), 1.6, Color("db8972"))
	for passage in world.get("adventure",{}).get("passages",[]): draw_circle(point(passage.x,passage.y),3,Color("c5a9eb"))
	for mage in world.get("story", {}).get("mages", []):
		draw_circle(point(mage.x, mage.y), 2.6, Color("c9a3e6"))
	for player in world.get("players", []):
		if player.alive and player.get("online", false):
			draw_circle(point(player.x, player.y), 3 if player.id == player_id else 2, Color.WHITE if player.id == player_id else Color("8bc8d7"))
