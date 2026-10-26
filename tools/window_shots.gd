extends Control
## Verktyg: tar närbilder av rum i 3D för att granska fönster och gardiner. Körs som egen
## scen, med utmappen och rummen efter "--":
##   Godot --path . res://tools/window_shots.tscn -- <utmapp> kitchen son_room_1:evening ...
## Varje rum skrivs "rum[:tidszon[:val...]]"; utan tidszon blir det eftermiddag. Valen är
## "overview" (hela våningen) och ett gardinläge ("open", "half", "closed") för rummet.

var _view: HouseView3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("window_shots: ange en utmapp och rum efter --")
		get_tree().quit(1)
		return
	var out: String = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_view = HouseView3D.new()
	add_child(_view)
	for spec in args.slice(1):
		var parts: PackedStringArray = spec.split(":")
		var room_id := parts[0]
		var period := parts[1] if parts.size() > 1 else "afternoon"
		GameState.period = GameState.TIME_PERIODS.find(period)
		GameState.refresh_schedules()
		GameState.time_of_day_changed.emit(period)
		_view.show_floor(PlanDrawer.floor_of(room_id))
		_view.settle_lighting()
		var flags := parts.slice(2)
		if "overview" in flags:
			_view.focus_overview()
		else:
			_view.focus_room(room_id)
		for state in HouseWindow.STATES:
			if state in flags:
				Curtains.set_for_now(room_id, state)
				_view.refresh_curtains(false)
		await _frames(50)
		get_viewport().get_texture().get_image().save_png(out.path_join("%s.png" % spec.replace(":", "_")))
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await RenderingServer.frame_post_draw
