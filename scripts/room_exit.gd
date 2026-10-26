@tool
class_name RoomExit
extends Clickable
## En dörr, trappa eller väg till ett annat rum. Ett klick flyttar spelaren dit.
## Namnet på målrummet hämtas från GameState.ROOMS.

enum Direction { DOOR, UP, DOWN, LEFT, RIGHT }

# Autoloaden finns inte i editorn, så rumsnamnen läses direkt från skriptets konstanter.
const GameStateScript := preload("res://scripts/game_state.gd")

@export var target_room := "":
	set(value):
		target_room = value
		queue_redraw()
@export var direction := Direction.DOOR:
	set(value):
		direction = value
		queue_redraw()
@export var travel_minutes := 0
## Låt rummet placera utgången på dörren, trappan eller ytterdörren i planen.
@export var auto_place := true
## Rita dörren som platshållare även när rummet har en bild, för dörrar
## som ännu inte finns med i bakgrundsbilden.
@export var show_placeholder := false:
	set(value):
		show_placeholder = value
		queue_redraw()


func _draw() -> void:
	if _is_on_background() and not show_placeholder:
		_draw_on_background(_target_name())
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.12, 0.1, 0.08, 0.55 if _hovered else 0.35))
	if _hovered:
		draw_rect(rect, Color.WHITE, false, 3.0)

	var center := Vector2(size.x / 2, size.y / 2 - 20)
	var white := Color(1, 1, 1, 0.9)
	match direction:
		Direction.DOOR:
			draw_circle(Vector2(size.x - 22, size.y / 2), 7, white)
		Direction.UP:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -24), center + Vector2(22, 12), center + Vector2(-22, 12)]), white)
		Direction.DOWN:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, 24), center + Vector2(-22, -12), center + Vector2(22, -12)]), white)
		Direction.LEFT:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-24, 0), center + Vector2(12, -22), center + Vector2(12, 22)]), white)
		Direction.RIGHT:
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(24, 0), center + Vector2(-12, 22), center + Vector2(-12, -22)]), white)

	# Krymp långa namn tills de får plats på dörren.
	var font := ThemeDB.fallback_font
	var label := _target_name()
	var font_size := 18
	while font_size > 11 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 10:
		font_size -= 1
	draw_string(font, Vector2(0, size.y - 18), label,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)


func activate() -> void:
	GameState.go_to_room(target_room, travel_minutes)


func get_hint() -> String:
	if travel_minutes > 0:
		return "Gå till %s  –  tar %s" % [_target_name(), GameState.format_duration(travel_minutes)]
	return "Gå till %s" % _target_name()


func _target_name() -> String:
	return GameStateScript.ROOMS.get(target_room, {}).get("name", target_room)
