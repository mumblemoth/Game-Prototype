extends Node
## Visar telefonens sidor en i taget och sparar en skärmbild av varje, för att granska
## utseendet utan att spela. Körs med:
##   Godot --path . res://tools/phone_preview.tscn -- <mapp för bilderna>

const PAGES := ["home", "phone", "call", "messages", "thread", "memories", "memory", "profile", "journal", "settings", "wallpaper"]
const CROP := Rect2i(910, 20, 360, 680)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("phone_preview")
	DirAccess.make_dir_recursive_absolute(out)
	var backdrop := ColorRect.new()
	backdrop.color = Color("c9b8a6")
	backdrop.size = Vector2(1280, 720)
	add_child(backdrop)
	# Ett nytt minne och olästa sms ger notiser på låsskärmen.
	GameState.add_memory("day1_morning")
	var phone: CanvasLayer = load("res://scripts/phone.gd").new()
	add_child(phone)
	phone.open()
	await _snap(out, "lock", 0.7)
	phone._thread_contact = "husband"
	phone._call_contact = "husband"
	phone._memory = "mom_casual"
	for page in PAGES:
		phone._show(page)
		await _snap(out, page, 0.45)
	phone._show("memory")
	await get_tree().create_timer(0.3).timeout
	phone._open_sheet("Use “Sunday Morning” as wallpaper", [["Lock Screen", func() -> void: pass], ["Home Screen", func() -> void: pass], ["Both", func() -> void: pass]])
	await _snap(out, "sheet", 0.4)
	GameState.set_wallpaper("home", "memory:mom_work")
	phone._show("home")
	await _snap(out, "home_photo", 0.4)
	print("phone_preview: done -> ", out)
	get_tree().quit()


func _snap(out: String, page: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image().get_region(CROP)
	image.save_png(out.path_join("%s.png" % page))
