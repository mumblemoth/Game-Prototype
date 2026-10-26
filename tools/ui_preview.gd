extends Node
## Visar UI-kitets skärmar en i taget och sparar en skärmbild av varje, för att granska
## utseendet utan att spela: titelskärmen, HUD:en, rummets meny, pausmenyns sidor,
## dagens slut och övergångarna. Körs med:
##   Godot --path . res://tools/ui_preview.tscn -- <mapp för bilderna>

var _out := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("ui_preview")
	DirAccess.make_dir_recursive_absolute(_out)
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await _snap("01_title", 1.4)
	menu._open_settings()
	await _snap("02_title_settings", 0.5)
	menu.queue_free()

	# Lite av allt, så att sidorna har något att visa.
	GameState.inventory["painting"] = 2
	GameState.owned.append_array(["dishwasher", "gift_cleats", "outfit:date"])
	GameState.social["charm"] = 34
	GameState.social["knowledge"] = 12
	GameState.add_memory("day1_morning")
	var house: Node = load("res://scenes/main.tscn").instantiate()
	add_child(house)
	await get_tree().create_timer(1.0).timeout
	for i in 4:
		if GameState.playing_scene != "":
			GameState.finish_scene()
		await get_tree().create_timer(0.5).timeout
	await _snap("03_hud", 2.5)
	house._on_room_clicked("kitchen")
	await _snap("04_room_menu", 1.0)
	house._close_menu()
	var pause: CanvasLayer = house._pause
	pause.open()
	await _snap("05_pause", 0.8)
	for page in ["status", "items", "memories", "settings"]:
		pause._show(page)
		await _snap("06_pause_" + page, 0.5)
	pause._items_tab = "purchases"
	pause._show("items")
	await _snap("07_pause_items_purchases", 0.5)
	pause._memory = "mom_casual"
	pause._show("memories")
	await _snap("08_pause_memory", 0.5)
	pause._choose("title")
	await _snap("09_pause_confirm", 0.4)
	pause._back()
	pause.close()
	await get_tree().create_timer(0.4).timeout
	UiTransition.banner(self, "Evening", "Monday · Day 1")
	await _snap("10_banner", 0.35)
	await get_tree().create_timer(1.6).timeout
	UiTransition.wipe(self, func() -> void: pass, "Day 2 · Tuesday")
	await _snap("11_wipe", 0.5)
	await get_tree().create_timer(1.2).timeout
	GameState.day_ended.emit()
	await _snap("12_day_end", 1.0)
	print("ui_preview: done -> ", _out)
	get_tree().quit()


func _snap(file_name: String, wait: float) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join("%s.png" % file_name))
