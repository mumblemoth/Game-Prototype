class_name HouseWindow
extends Node3D
## Ett fönster i husets 3D-stil: glas som man ser omgivningen igenom (glass.gdshader),
## karm med spröjs efter stilen i FloorPlanArt.WINDOW_STYLES, fönsterbräda och gardiner
## eller rullgardin som glider mellan lägena "open", "half" och "closed". Vilket läge
## gardinerna ska ha bestäms av Curtains; HouseView3D anropar set_curtains().
## Byggs lokalt: x längs väggen (åt höger sett inifrån), y uppåt och z in i rummet, med
## nollpunkten mitt i öppningen på väggens mittlinje, vid golvet.

const GLASS := preload("res://shaders/glass.gdshader")
const STATES := {"closed": 0.0, "half": 0.5, "open": 1.0}
## Så lång tid det tar att dra för eller ifrån helt.
const CURTAIN_SECONDS := 1.1
## Gardinernas färg per rum (annars StyleKit.CURTAIN).
const CURTAIN_COLORS := {
	"son_room_1": Color(0.32, 0.34, 0.48),  # mörkläggningsgardiner till gamingen
	"son_room_2": Color(0.45, 0.58, 0.74),
	"bedroom": Color(0.9, 0.7, 0.66),
	"living_room": Color(0.74, 0.8, 0.66),
}
const BLIND_COLOR := Color(0.97, 0.95, 0.9)
## En hopdragen gardin är så här bred, och stången når så här långt utanför öppningen.
const GATHERED := 0.26
const OVERHANG := 0.22
const FOLDS := 7

## Fönstrets data ur FloorPlanArt.windows().
var spec := {}
var room_id := ""
var state := "open"
var _openness := 1.0
## Gardinerna: en upphängningspunkt per gardin på stången (den gungar lätt), med tyget
## som första barn och knytbandet som andra. Sidan är -1 (vänster) eller 1 (höger).
var _panels: Array[Node3D] = []
var _sides: Array[float] = []
var _drop := 1.0
var _blind: Node3D
var _blind_bar: Node3D
var _tween: Tween


## Bygger ett fönster i en vägg. `at` är öppningens mitt på väggens mittlinje vid golvet
## och `inward` pekar in i rummet.
static func build(parent: Node3D, rig: TimeOfDayRig, window: Dictionary, at: Vector3, inward: Vector3) -> HouseWindow:
	var node := HouseWindow.new()
	node.spec = window
	node.room_id = window["room"]
	node.name = "Window%d" % window["index"]
	node.set_meta("kind", "window")
	node.position = at
	node.basis = Basis(Vector3.UP.cross(inward), Vector3.UP, inward)
	parent.add_child(node)
	node._build(rig)
	return node


func has_curtains() -> bool:
	return not _panels.is_empty() or _blind != null


## Drar gardinerna (eller rullgardinen) till ett läge, med en kort glidning.
func set_curtains(new_state: String, animate := true) -> void:
	if not STATES.has(new_state) or not has_curtains():
		return
	state = new_state
	var target: float = STATES[new_state]
	if _tween:
		_tween.kill()
	if not animate or not is_inside_tree() or is_equal_approx(target, _openness):
		_set_openness(target)
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_openness, _openness, target, CURTAIN_SECONDS * absf(target - _openness))


# --- Bygget -------------------------------------------------------------------

func _build(rig: TimeOfDayRig) -> void:
	var w: float = spec["width"]
	var sill: float = spec["sill"]
	var top: float = spec["top"]
	var h := top - sill
	var mid := (sill + top) / 2.0
	var style: Dictionary = FloorPlanArt.WINDOW_STYLES[spec["style"]]
	# Glaset: en ruta mitt i väggen som omgivningen syns igenom.
	var glass := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	glass.mesh = quad
	glass.position = Vector3(0, mid, 0)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = GLASS
	material.set_shader_parameter("pane_size", Vector2(w, h))
	material.set_shader_parameter("frosted", 1.0 if spec["frosted"] else 0.0)
	glass.material_override = material
	add_child(glass)
	if rig:
		rig.register_glass(material)
	if StyleKit.painted_views:
		StyleKit._painted_view(self, rig, Vector3(0, mid, 0), Vector3(0, 0, -1), Vector2(w, h))
	# Karmen runt öppningen, mittposter, spröjs och tvärpost.
	var frame := StyleKit.mat(StyleKit.WHITE)
	var t := 0.06
	var depth := StyleKit.WALL + 0.04
	for s in [-1, 1]:
		StyleKit.box(self, Vector3(t, h, depth), Vector3(s * w / 2, mid, 0), frame)
		StyleKit.box(self, Vector3(w + t, t, depth), Vector3(0, mid + s * h / 2, 0), frame)
	var columns: int = style["columns"] if style["columns"] > 0 else maxi(1, roundi(w / 0.7))
	for i in range(1, columns):
		StyleKit.box(self, Vector3(0.04, h, 0.05), Vector3(-w / 2 + w * i / columns, mid, 0), frame, false)
	var rows: int = style["rows"]
	var pane_top: float = style.get("transom", top)
	for i in range(1, rows):
		StyleKit.box(self, Vector3(w, 0.03, 0.045), Vector3(0, sill + (pane_top - sill) * i / rows, 0), frame, false)
	if style.has("transom"):
		StyleKit.box(self, Vector3(w, 0.05, 0.06), Vector3(0, style["transom"], 0), frame, false)
	if sill > 0.3:
		# Fönsterbräda på insidan.
		StyleKit.box(self, Vector3(w + 0.2, 0.04, 0.22), Vector3(0, sill - 0.02, 0.08), frame)
	match spec["curtains"]:
		"drapes":
			_build_drapes(rig, [-1.0, 1.0])
		"single_left":
			_build_drapes(rig, [-1.0])
		"single_right":
			_build_drapes(rig, [1.0])
		"blind":
			_build_blind()
	set_curtains(spec["default"], false)


## Gardiner på en mässingsstång. Varje gardin hänger från sin yttre kant och dras in mot
## mitten; tyget är veckat (_pleats) och skalas i bredd, så att vecken tätnar när
## gardinen dras ifrån. Uppknutna med ett band när de är helt ifrån.
func _build_drapes(rig: TimeOfDayRig, sides: Array) -> void:
	var w: float = spec["width"]
	var rod_y: float = spec["top"] + 0.12
	var floor_length: bool = FloorPlanArt.WINDOW_STYLES[spec["style"]].get("floor_curtains", false)
	var bottom := 0.04 if floor_length else maxf(spec["sill"] - 0.15, 0.04)
	var z := StyleKit.WALL / 2 + 0.08
	var brass := StyleKit.mat(StyleKit.BRASS, 0.8)
	var rod := StyleKit.cylinder(self, 0.012, 0.012, w + OVERHANG * 2 + 0.12, Vector3(0, rod_y, z), brass, 12)
	rod.rotation_degrees = Vector3(0, 0, 90)
	for s in [-1, 1]:
		StyleKit.sphere(self, 0.026, Vector3(s * (w / 2 + OVERHANG + 0.07), rod_y, z), brass)
	_drop = rod_y - 0.02 - bottom
	var fabric := StyleKit.mat(CURTAIN_COLORS.get(room_id, StyleKit.CURTAIN))
	for s in sides:
		var pivot := Node3D.new()
		pivot.position = Vector3(s * (w / 2 + OVERHANG), rod_y - 0.02, z)
		add_child(pivot)
		var cloth := MeshInstance3D.new()
		cloth.mesh = _pleats(-s, _drop)
		cloth.material_override = fabric
		pivot.add_child(cloth)
		var tie := StyleKit.box(pivot, Vector3(GATHERED + 0.05, 0.045, 0.1), Vector3.ZERO, StyleKit.mat(StyleKit.ROSE))
		tie.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_panels.append(pivot)
		_sides.append(s)
		if rig:
			rig.register_sway(pivot)


## Rullgardin: en kassett överst och en duk med list nedtill som rullas ned över glaset.
func _build_blind() -> void:
	var w: float = spec["width"]
	var top: float = spec["top"]
	var z := StyleKit.WALL / 2 + 0.05
	var housing := StyleKit.cylinder(self, 0.035, 0.035, w + 0.1, Vector3(0, top + 0.07, z), StyleKit.mat(StyleKit.WHITE), 12)
	housing.rotation_degrees = Vector3(0, 0, 90)
	_blind = Node3D.new()
	_blind.position = Vector3(0, top + 0.05, z + 0.01)
	add_child(_blind)
	StyleKit.box(_blind, Vector3(w, 1.0, 0.008), Vector3(0, -0.5, 0), StyleKit.mat(BLIND_COLOR, 0.0, 6, 0.12, BLIND_COLOR.darkened(0.05)), true, 0.0)
	_blind_bar = StyleKit.box(self, Vector3(w + 0.02, 0.025, 0.03), Vector3(0, 0, z + 0.01), StyleKit.mat(StyleKit.OAK.darkened(0.1)))
	StyleKit.sphere(_blind_bar, 0.018, Vector3(0, -0.04, 0.01), StyleKit.mat(StyleKit.OAK.darkened(0.1)))


## Lägger gardinerna efter `value`: 0 = fördragna, 1 = helt ifrån.
func _set_openness(value: float) -> void:
	_openness = value
	var w: float = spec["width"]
	var reach := w / 2 + OVERHANG + 0.03 if _panels.size() > 1 else w + OVERHANG * 2
	for i in _panels.size():
		var cloth := _panels[i].get_child(0) as Node3D
		cloth.scale.x = lerpf(reach, GATHERED, value)
		var tie := _panels[i].get_child(1) as Node3D
		tie.visible = value > 0.9
		tie.position = Vector3(-_sides[i] * GATHERED / 2, -_drop * 0.58, 0.0)
	if _blind:
		var length := lerpf(spec["top"] - spec["sill"] + 0.03, 0.06, value)
		_blind.scale.y = length
		_blind_bar.position.y = _blind.position.y - length


static var _pleat_cache := {}


## Ett veckat tyg, 1 bred (skalas till gardinens bredd) och `height` högt, från x = 0
## till x = `dir`, hängande nedåt från y = 0. Båda sidor byggs, så att det syns från båda håll.
static func _pleats(dir: float, height: float) -> ArrayMesh:
	var key := "%s_%.3f" % [dir, height]
	if _pleat_cache.has(key):
		return _pleat_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := FOLDS * 6
	var depth := 0.035
	for face in [1.0, -1.0]:
		for i in steps:
			var points: Array[Vector3] = []
			var normals: Array[Vector3] = []
			for u in [float(i) / steps, float(i + 1) / steps]:
				var phase: float = u * FOLDS * TAU
				var z := depth * 0.5 * sin(phase) - (0.006 if face < 0 else 0.0)
				# Normalerna lutar bara till hälften med vecken, så att ljuset delar tyget i
				# breda toner i stället för tunna blanka streck.
				var slope := depth * 0.5 * FOLDS * TAU * cos(phase) * dir * 0.5
				points.append(Vector3(u * dir, 0, z))
				normals.append(Vector3(-slope, 0, 1).normalized() * face)
			var quad := [[points[0], normals[0]], [points[1], normals[1]],
					[points[1] + Vector3(0, -height, 0), normals[1]], [points[0] + Vector3(0, -height, 0), normals[0]]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				var a: Array = quad[tri[0]]
				var b: Array = quad[tri[1]]
				var c: Array = quad[tri[2]]
				# Godots framsida är medurs sedd framifrån.
				if ((b[0] as Vector3) - a[0]).cross((c[0] as Vector3) - a[0]).dot(Vector3(0, 0, face)) > 0.0:
					var swap := b
					b = c
					c = swap
				for v in [a, b, c]:
					st.set_normal(v[1])
					st.add_vertex(v[0])
	var mesh := st.commit()
	_pleat_cache[key] = mesh
	return mesh
