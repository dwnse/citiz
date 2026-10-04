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
	return Vector2(8, 8) + Vector2(x, y) / float(world.get("size", 220)) * (size - Vector2(16, 16))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.06, 0.065, 0.9))
	if world.is_empty():
		return
	for community in world.get("communities", []):
		var tint := Color(community.color)
		var location := point(community.x, community.y)
		draw_circle(location, 9, tint.darkened(0.55))
		draw_circle(location, 4, tint if community.vault.hp > 0 else Color("df7667"))
	for zombie in world.get("zombies", []):
		draw_circle(point(zombie.x, zombie.y), 1.6, Color("db8972"))
	for mage in world.get("story", {}).get("mages", []):
		draw_circle(point(mage.x, mage.y), 2.6, Color("c9a3e6"))
	for player in world.get("players", []):
		if player.alive and player.get("online", false):
			draw_circle(point(player.x, player.y), 3 if player.id == player_id else 2, Color.WHITE if player.id == player_id else Color("8bc8d7"))
