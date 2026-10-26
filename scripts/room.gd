@tool
class_name Room
extends Node2D
## Rotnod för ett rum. Visar rummet ovanifrån som en inzoomad del av husets
## planritning (PlanDrawer): målat om det finns en bild, annars kodritat, med
## grannrummen nedtonade runt omkring. Klickytor och dörrar placeras efter planen:
##   Hotspot med `furniture_kind` hamnar på den möbeln i FloorPlanArt.FURNITURE.
##   RoomExit med `auto_place` hamnar på dörren, trappan eller ytterdörren dit den leder.
## Rummet färgtonas efter tiden på dygnet.

const SCREEN_SIZE := Vector2(1280, 720)
## Ytan mellan HUD:ens över- och underkant där rummet visas.
const VIEW_AREA := Rect2(40, 92, 1200, 548)
## Hur mycket av grannrummen runt omkring som syns, i meter.
const VIEW_MARGIN := 0.7
const PlanDrawerScript := preload("res://scripts/plan_drawer.gd")
const PERIOD_TINTS := {
	"morning": Color(1.0, 0.93, 0.85),
	"afternoon": Color(1, 1, 1),
	"evening": Color(1.0, 0.82, 0.72),
	"night": Color(0.55, 0.6, 0.82),
}

## Rummets id i GameState.ROOMS.
@export var room_id := "":
	set(value):
		room_id = value
		if is_node_ready():
			_layout()

var _drawer: PlanDrawer


func _ready() -> void:
	_drawer = PlanDrawerScript.new(self)
	_drawer.show_grid = false
	_drawer.show_labels = false
	_drawer.show_markers = false
	if not Engine.is_editor_hint():
		GameState.time_of_day_changed.connect(func(_period: String) -> void: _update_tint())
	_update_tint()
	_layout()


## Hur många pixlar en meter är i rumsvyn för ett rum, och var rummets mitt hamnar.
## Kartan använder samma mått för att zooma in sömlöst.
static func view_meter(plan: Rect2) -> float:
	var shown := plan.grow(VIEW_MARGIN)
	return minf(VIEW_AREA.size.x / shown.size.x, VIEW_AREA.size.y / shown.size.y)


func _layout() -> void:
	var floor_name := PlanDrawerScript.floor_of(room_id)
	if floor_name == "":
		return
	var plan: Rect2 = PlanDrawerScript.FLOOR_PLANS[floor_name][room_id]
	_drawer.floor_name = floor_name
	_drawer.focus_room = room_id
	_drawer.fit(VIEW_AREA, plan.grow(VIEW_MARGIN))
	for child in get_children():
		if child is Hotspot and child.furniture_kind != "":
			var item := FloorPlanArt.furniture_rect(room_id, child.furniture_kind)
			if item.size != Vector2.ZERO:
				_place(child, Rect2(plan.position + item.position, item.size))
		elif child is RoomExit and child.auto_place:
			var area := _drawer.exit_rect(room_id, child.target_room)
			if area.size != Vector2.ZERO:
				_place(child, area)
			# Utgångar som inte finns i planen (t.ex. mellan byggnader) visas som platshållare.
			child.show_placeholder = area.size == Vector2.ZERO
	queue_redraw()


func _place(clickable: Clickable, plan_rect: Rect2) -> void:
	var rect := _drawer.screen_rect(plan_rect)
	clickable.position = rect.position
	clickable.size = rect.size


func _update_tint() -> void:
	var period := "afternoon" if Engine.is_editor_hint() else GameState.get_time_of_day()
	self_modulate = PERIOD_TINTS[period]


func _draw() -> void:
	if _drawer != null and PlanDrawerScript.floor_of(room_id) != "":
		_drawer.draw(Rect2(Vector2.ZERO, SCREEN_SIZE))


func has_background() -> bool:
	return true


## Var familjens markörer står: i en rad på rummets golv, under mitten.
func marker_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var plan := PlanDrawerScript.plan_of(room_id)
	var rect := _drawer.screen_rect(plan)
	var spacing := minf(70.0, (rect.size.x - 60) / maxf(count, 1))
	for i in count:
		positions.append(rect.get_center() + Vector2((i - (count - 1) / 2.0) * spacing, rect.size.y * 0.22))
	return positions
