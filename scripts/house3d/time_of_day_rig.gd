class_name TimeOfDayRig
extends Node3D
## Ljuset för husets 3D-scener per tidszon: sol (eller måne), omgivningsljus, bakgrund,
## himlen i fönstren, lampor som tänds på kvällen och natten, damm i solljuset och
## figurer som tonas. Allt som ska följa tidszonen registreras här av StyleKit och
## FurnitureKit. Riggen låter också gardiner och liknande gunga lätt.

## Per tidszon: solens vinkel (pitch, yaw), färg och styrka, omgivningsljus, bakgrund,
## himlen i fönstren, lampornas styrka och om det svävar damm i ljuset.
## "haze" är diset som omgivningen tonar bort i på avstånd (när dimman är på), och
## "reflection" hur mycket fönsterglaset speglar himlens färg (mörkt ute = mer spegling).
const PERIODS := {
	"morning": {"sun": Vector2(-28, 150), "sun_color": Color(1.0, 0.84, 0.66), "sun_energy": 1.7,
			"ambient": Color(1.0, 0.86, 0.82), "ambient_energy": 0.55, "background": Color(0.99, 0.88, 0.8),
			"haze": Color(0.86, 0.76, 0.72), "sky": Color(1.0, 0.9, 0.82), "reflection": 0.0, "lamps": 0.0, "dust": true, "tint": Color(1.0, 0.95, 0.9)},
	"afternoon": {"sun": Vector2(-34, -122), "sun_color": Color(1.0, 0.94, 0.84), "sun_energy": 2.4,
			"ambient": Color(0.98, 0.93, 0.9), "ambient_energy": 0.5, "background": Color(0.92, 0.94, 0.98),
			"haze": Color(0.64, 0.76, 0.85), "sky": Color(1.0, 1.0, 1.0), "reflection": 0.0, "lamps": 0.0, "dust": true, "tint": Color.WHITE},
	"evening": {"sun": Vector2(-14, -95), "sun_color": Color(1.0, 0.55, 0.32), "sun_energy": 1.8,
			"ambient": Color(0.72, 0.6, 0.86), "ambient_energy": 0.45, "background": Color(0.96, 0.7, 0.62),
			"haze": Color(0.82, 0.6, 0.62), "sky": Color(1.0, 0.68, 0.55), "reflection": 0.1, "lamps": 0.35, "dust": true, "tint": Color(1.0, 0.85, 0.78)},
	"night": {"sun": Vector2(-40, -120), "sun_color": Color(0.6, 0.7, 1.0), "sun_energy": 0.25,
			"ambient": Color(0.36, 0.42, 0.72), "ambient_energy": 0.4, "background": Color(0.12, 0.14, 0.26),
			"haze": Color(0.1, 0.12, 0.23), "sky": Color(0.2, 0.24, 0.48), "reflection": 0.35, "lamps": 0.9, "dust": false, "tint": Color(0.7, 0.72, 0.9)},
}

## Mjukt ljus (beslut 2026-10-25): omgivningsljuset lyfts och solen dämpas, så att
## skuggorna blir ljusare och ljuset jämnare och gosigare.
const AMBIENT_LIFT := 1.58
const SUN_SCALE := 0.8
## Hur länge ljuset glider över till nästa tidszon under dagen (solen vandrar, lamporna
## tänds). Över natten till en ny dag byts ljuset direkt, bakom dagsövergången.
const BLEND_SECONDS := 1.8

var period := "afternoon"
## Värdena som syns just nu, som PERIODS men kan ligga mitt i en övergång. Det som
## registreras får dem direkt, så att inget hamnar i en gammal tidszon.
var _shown: Dictionary = PERIODS[period]
var _blend: Tween
var environment: Environment
var sun: DirectionalLight3D
var _skies: Array[StandardMaterial3D] = []
var _glass: Array[ShaderMaterial] = []
var _lamps: Array[OmniLight3D] = []
var _lamp_energy := {}
var _shades: Array[ShaderMaterial] = []
var _dust: Array[GPUParticles3D] = []
var _tinted: Array[Node3D] = []
var _swaying: Array[Node3D] = []
var _breathing: Array[Node3D] = []
var _time := 0.0


func _init() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 1.15
	environment.adjustment_enabled = true
	# Färgkänslan "mellanvägen" (beslut 2026-10-25): lite mjukare färger och lyfta skuggor.
	environment.adjustment_saturation = 0.86
	environment.adjustment_contrast = 0.94
	environment.adjustment_brightness = 1.04
	# Djupdimma (slås på av den som har omgivning runt huset): världen tonar bort i diset.
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_density = 0.6
	environment.fog_sky_affect = 1.0
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_max_distance = 30.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _ready() -> void:
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		game_state.time_of_day_changed.connect(_on_time_of_day_changed)
		period = game_state.get_time_of_day()
	# Direkt, inte uppskjutet: ett uppskjutet anrop bar med sig tidszonen från när riggen
	# byggdes och kunde skriva över en senare (natten låg kvar när en ny dag började på en
	# annan våning). Det som registreras efteråt får ljuset i register_*.
	set_period(period)


func _process(delta: float) -> void:
	_time += delta
	# Figurer som byggts om (t.ex. när familjen flyttar sig) har tagits bort.
	_breathing = _breathing.filter(is_instance_valid)
	_tinted = _tinted.filter(is_instance_valid)
	for i in _swaying.size():
		_swaying[i].rotation.x = sin(_time * 0.9 + i * 1.7) * 0.035
	for i in _breathing.size():
		var breath := 1.0 + sin(_time * 1.3 + i) * 0.035
		_breathing[i].scale = Vector3(1.0, breath, 1.0 + (breath - 1.0) * 0.5)


func register_sky(material: StandardMaterial3D) -> void:
	_skies.append(material)
	material.albedo_color = _shown["sky"]


## Fönsterglas (glass.gdshader), som speglar himlens färg mer när det är mörkt ute.
func register_glass(material: ShaderMaterial) -> void:
	_glass.append(material)
	_tint_glass(material, _shown)


func _tint_glass(material: ShaderMaterial, p: Dictionary) -> void:
	material.set_shader_parameter("sky", p["sky"])
	material.set_shader_parameter("reflection", p["reflection"])


## En lampa som tänds på kvällen och natten. `strength` skalar tidszonens styrka.
func register_lamp(light: OmniLight3D, shade: ShaderMaterial = null, strength := 1.0) -> void:
	_lamps.append(light)
	_lamp_energy[light] = strength
	_light_lamp(light, _shown)
	if shade:
		register_lamp_shade(shade)


func _light_lamp(lamp: OmniLight3D, p: Dictionary) -> void:
	lamp.light_energy = p["lamps"] * _lamp_energy[lamp]
	lamp.visible = p["lamps"] > 0.0


## En lampskärm eller glödlampa som lyser när lamporna är tända.
func register_lamp_shade(shade: ShaderMaterial) -> void:
	_shades.append(shade)
	shade.set_shader_parameter("emission_energy", _shown["lamps"] * 0.5)


func register_dust(particles: GPUParticles3D) -> void:
	_dust.append(particles)
	particles.emitting = _shown["dust"]
	particles.visible = _shown["dust"]


## En figur (bild i rummet) som tonas efter tidszonen.
func register_tinted(node: Node3D) -> void:
	_tinted.append(node)
	node.set("modulate", _shown["tint"])


func register_sway(node: Node3D) -> void:
	_swaying.append(node)


## Något som andas lugnt (t.ex. en sovande hund).
func register_breathe(node: Node3D) -> void:
	_breathing.append(node)


## Dygnet går framåt: ljuset glider över. Bakåt (natten blir en ny morgon) byts det direkt.
func _on_time_of_day_changed(new_period: String) -> void:
	var order := PERIODS.keys()
	set_period(new_period, order.find(new_period) > order.find(period))


## Byter tidszon: solens vinkel och färg, omgivningsljus, himlen i fönstren och lamporna.
## Med `animate` glider allt dit från det som syns nu (även mitt i en övergång).
func set_period(new_period: String, animate := false) -> void:
	period = new_period
	if _blend:
		_blend.kill()
	var target: Dictionary = PERIODS[period]
	if not animate or not is_inside_tree():
		_apply(target)
		return
	var from := _shown
	_blend = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blend.tween_method(func(t: float) -> void: _apply(_mix(from, target, t)), 0.0, 1.0, BLEND_SECONDS)


## Värdena en bit (t) mellan två tidszoner. Solens vinklar tar kortaste vägen runt.
func _mix(from: Dictionary, to: Dictionary, t: float) -> Dictionary:
	var mixed := {}
	for key in to:
		var a = from[key]
		var b = to[key]
		if b is Vector2:
			mixed[key] = Vector2(rad_to_deg(lerp_angle(deg_to_rad(a.x), deg_to_rad(b.x), t)),
					rad_to_deg(lerp_angle(deg_to_rad(a.y), deg_to_rad(b.y), t)))
		elif b is Color or b is float:
			mixed[key] = lerp(a, b, t)
		else:
			mixed[key] = b if t >= 0.5 else a
	return mixed


func _apply(p: Dictionary) -> void:
	_shown = p
	var angle: Vector2 = p["sun"]
	sun.rotation_degrees = Vector3(angle.x, angle.y, 0)
	sun.light_color = p["sun_color"]
	sun.light_energy = p["sun_energy"] * SUN_SCALE
	environment.ambient_light_color = p["ambient"]
	environment.ambient_light_energy = p["ambient_energy"] * AMBIENT_LIFT
	environment.fog_light_color = p["haze"]
	environment.background_color = p["haze"] if environment.fog_enabled else p["background"]
	for sky in _skies:
		sky.albedo_color = p["sky"]
	for glass in _glass:
		_tint_glass(glass, p)
	for lamp in _lamps:
		_light_lamp(lamp, p)
	for shade in _shades:
		shade.set_shader_parameter("emission_energy", p["lamps"] * 0.5)
	for particles in _dust:
		particles.emitting = p["dust"]
		particles.visible = p["dust"]
	_tinted = _tinted.filter(is_instance_valid)
	for node in _tinted:
		node.set("modulate", p["tint"])
