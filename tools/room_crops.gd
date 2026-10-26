extends SceneTree
## Ritar varje rum ovanifrån som en egen bild (rummet plus PlanDrawer.PAINT_MARGIN meter
## runt om) att måla om med img2img. Den målade bilden läggs sedan som
## Assets/plan_rooms/<rum>.png (eller .webp) och visas automatiskt i planen och rumsvyn.
##
## Kör (inte headless, ritningen behöver renderas):
##   godot --path . -s res://tools/room_crops.gd              alla våningar i huset
##   godot --path . -s res://tools/room_crops.gd -- Entréplan  en våning
## Utklippen hamnar i Assets/sketches/rooms/<rum>_input.png.

const OUT := "res://Assets/sketches/rooms/"
## Utklippens längsta sida i pixlar.
const LONG_SIDE := 1024
const HOUSE_FLOORS := ["Vind", "Övervåning", "Entréplan", "Källare"]


func _initialize() -> void:
	# PlanDrawer laddas först här, efter att GameState har startat (den behöver dörrarna).
	var drawer_script: GDScript = load("res://scripts/plan_drawer.gd")
	var floors: Array = HOUSE_FLOORS
	if not OS.get_cmdline_user_args().is_empty():
		floors = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	for floor_name in floors:
		for room_id in drawer_script.FLOOR_PLANS[floor_name]:
			var crop: Rect2 = drawer_script.FLOOR_PLANS[floor_name][room_id].grow(drawer_script.PAINT_MARGIN)
			# Samma skala på båda ledder, avrundat till 16-tal (det hanterar modellen).
			var scale_factor := LONG_SIDE / maxf(crop.size.x, crop.size.y)
			var size := Vector2i(
				maxi(64, roundi(crop.size.x * scale_factor / 16.0) * 16),
				maxi(64, roundi(crop.size.y * scale_factor / 16.0) * 16))

			var viewport := SubViewport.new()
			viewport.size = size
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			var canvas := Control.new()
			canvas.size = size
			viewport.add_child(canvas)
			root.add_child(viewport)
			var drawer = drawer_script.new(canvas)
			drawer.floor_name = floor_name
			drawer.export_mode = true
			drawer.meter = scale_factor
			drawer.origin = -crop.position * scale_factor
			canvas.draw.connect(func() -> void: drawer.draw(Rect2(Vector2.ZERO, Vector2(size))))
			await process_frame
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path(OUT + "%s_input.png" % room_id)
			viewport.get_texture().get_image().save_png(path)
			print("%s: %s" % [room_id, size])
			viewport.queue_free()
	quit()
