extends Control
## Verktyg: ritar husets våningar som planritningar med rummens mått och tar en bild av
## varje våning i 3D, till dokumentationen i docs/floor_plans/. Körs som egen scen:
##   Godot --path . res://tools/house_plan_export.tscn

const OUT := "res://docs/floor_plans/"
const FLOORS := {"Källare": "basement", "Entréplan": "ground_floor", "Övervåning": "upstairs", "Vind": "attic", "Utanför": "outside"}
## Hela husets yta (entréplanet); alla våningar ritas i samma skala inuti den.
const FOOTPRINT := Rect2(0, 0, 12.8, 8.8)
## Tomten med gårdarna (våningen Utanför) ritas i en egen, mindre skala.
const LOT := Rect2(-3.6, -7.0, 20.0, 23.4)
const CLOSE_UPS := ["hall", "upstairs_hall", "basement_hall", "kitchen", "living_room", "son_room_1", "bedroom", "backyard"]

var _floor := ""
var _drawer: PlanDrawer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_drawer = PlanDrawer.new(self)
	_drawer.show_markers = false
	for floor_name in FLOORS:
		_floor = floor_name
		queue_redraw()
		await _frames(3)
		get_viewport().get_texture().get_image().save_png(OUT + "%s_plan.png" % FLOORS[floor_name])
	_floor = ""
	queue_redraw()
	var view := HouseView3D.new()
	add_child(view)
	for floor_name in FLOORS:
		view.show_floor(floor_name)
		await _frames(20)
		get_viewport().get_texture().get_image().save_png(OUT + "%s_3d.png" % FLOORS[floor_name])
	# Närbilder på hallarna (trappan) och några rum.
	for room_id in CLOSE_UPS:
		view.show_floor(PlanDrawer.floor_of(room_id))
		view.focus_room(room_id)
		await _frames(60)
		get_viewport().get_texture().get_image().save_png(OUT + "%s_3d.png" % room_id)
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await RenderingServer.frame_post_draw


func _draw() -> void:
	if _floor == "":
		return
	_drawer.floor_name = _floor
	_drawer.fit(Rect2(50, 70, size.x - 100, size.y - 110), LOT if _floor == "Utanför" else FOOTPRINT)
	_drawer.draw(Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	# Husets yttermått streckat, så att vind och källare syns i förhållande till huset.
	var outline := _drawer.screen_rect(FOOTPRINT)
	for side in [[outline.position, Vector2(outline.end.x, outline.position.y)], [Vector2(outline.end.x, outline.position.y), outline.end],
			[outline.end, Vector2(outline.position.x, outline.end.y)], [Vector2(outline.position.x, outline.end.y), outline.position]]:
		draw_dashed_line(side[0], side[1], Color(PlanDrawer.WALL, 0.35), 1.5, 8.0)
	draw_string(font, Vector2(50, 44), "%s  ·  house %.1f × %.1f m  ·  north is up, the camera looks from the south" % [PlanDrawer.FLOOR_LABELS[_floor], FOOTPRINT.size.x, FOOTPRINT.size.y],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PlanDrawer.TEXT)
	for room_id in _drawer.plans():
		var plan: Rect2 = _drawer.plans()[room_id]
		var rect := _drawer.screen_rect(plan)
		var text := "%.1f × %.1f m  (%.0f m²)" % [plan.size.x, plan.size.y, plan.get_area()]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var at := rect.get_center() + Vector2(-width / 2, 26)
		draw_rect(Rect2(at + Vector2(-6, -14), Vector2(width + 12, 19)), Color(PlanDrawer.PAPER, 0.9))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PlanDrawer.TEXT)
