@tool
class_name Clickable
extends Area2D
## Bas för allt man kan klicka på i ett rum: klickyta, hover och muspekare.
## Subklasser bestämmer utseende (_draw), hovertext (get_hint) och vad ett klick gör (activate).

@export var size := Vector2(120, 80):
	set(value):
		size = value
		_update_shape()
		queue_redraw()

var _hovered := false
var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _update_shape() -> void:
	if _shape == null:
		return
	(_shape.shape as RectangleShape2D).size = size
	_shape.position = size / 2


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		activate()


## Sant när rummet har en riktig bakgrundsbild. Då ska klickytan vara osynlig
## tills man håller musen över den, i stället för att ritas som platshållare.
func _is_on_background() -> bool:
	var room := get_parent() as Room
	return room != null and room.has_background()


## Ritar klickytan ovanpå en bakgrundsbild: en ram och en namnlapp vid hover,
## och en tunn ram i editorn så att den går att placera.
func _draw_on_background(label: String) -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if not _hovered:
		if Engine.is_editor_hint():
			draw_rect(rect, Color(1, 1, 1, 0.6), false, 2.0)
		return
	draw_rect(rect, Color(1, 1, 1, 0.12))
	draw_rect(rect, Color.WHITE, false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 16
	var text_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var tag := Rect2(Vector2((size.x - text_width) / 2 - 8, -font.get_height(font_size) - 12),
			Vector2(text_width + 16, font.get_height(font_size) + 6))
	draw_rect(tag, Color(0.1, 0.08, 0.06, 0.85))
	draw_string(font, tag.position + Vector2(8, 3 + font.get_ascent(font_size)), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Vad som händer vid klick.
func activate() -> void:
	pass


## Texten som visas längst ned när musen är över objektet.
func get_hint() -> String:
	return ""


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	GameState.show_hint(get_hint())


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	GameState.show_hint("")
