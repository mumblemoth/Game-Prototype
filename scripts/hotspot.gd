@tool
class_name Hotspot
extends Clickable
## Ett föremål i ett rum. Ett klick utför en handling som påverkar
## mätarna och kostar tid. Ritas som en färgad platshållarruta tills riktig grafik finns.

@export var display_name := "Objekt":
	set(value):
		display_name = value
		queue_redraw()
@export var color := Color(0.6, 0.6, 0.6):
	set(value):
		color = value
		queue_redraw()
## Möbeln i planen (typ i FloorPlanArt.FURNITURE) som klickytan ska ligga på.
## Rummet placerar och storleksanpassar den automatiskt.
@export var furniture_kind := ""
@export_multiline var action_text := "Du gör något."
@export var time_cost_minutes := 30

@export_group("Effekter")
@export var home_effect := 0
@export var work_effect := 0


func _draw() -> void:
	if _is_on_background():
		_draw_on_background(display_name)
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, color.lightened(0.25) if _hovered else color)
	if _hovered:
		draw_rect(rect, Color.WHITE, false, 3.0)
	var font := UiKit.body_font()
	draw_string(font, Vector2(0, size.y / 2 + 7), display_name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(0.1, 0.1, 0.1))


func activate() -> void:
	var effects := {
		"home": home_effect,
		"work": work_effect,
	}
	GameState.perform_action(action_text, effects, time_cost_minutes)


func get_hint() -> String:
	return "%s  –  tar %s" % [display_name, GameState.format_duration(time_cost_minutes)]
