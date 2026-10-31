class_name Backyard
## Trädgårdens egna regler, ovanpå de vanliga handlingarna i RoomActions:
##   - Rabatterna (FloorPlanArt "flower_bed" med stil "garden") behöver vatten. Har de
##     inte vattnats på THIRSTY_DAYS dagar vissnar de i 3D-vyn och valet säger det.
##     Handlingar med "waters_plants" (eller delegerade av en sådan) vattnar dem.
##   - Rex kan kallas ut: en handling med "calls_dog" flyttar hunden till trädgården
##     resten av tidszonen (en storyöverstyrning i Schedules), så han syns där och man
##     kan klappa honom.
##   - Aktiviteterna har en kort animation i 3D-vyn ("fx", se HouseView3D.play_activity).
## All text spelaren ser är på engelska.

## Dagar utan vatten innan rabatterna vissnar.
const THIRSTY_DAYS := 2
## Hur länge en aktivitets animation spelas innan handlingen genomförs (sekunder).
const FX_SECONDS := 1.6
## Överstyrningen som håller Rex i trädgården efter att mamman har kallat på honom.
const DOG_OVERRIDE := "dog_called_to_garden"
## Grupperna för rabatternas friska och vissna blommor (HomeKit._flower_bed).
const FRESH_GROUP := "garden_fresh"
const WILTED_GROUP := "garden_wilted"


## Om rabatterna har stått torra för länge.
static func plants_thirsty() -> bool:
	return GameState.day - GameState.last_watered >= THIRSTY_DAYS


## Visar de friska eller de vissna blommorna i en rabatt.
static func show_thirst(fresh: Node3D, wilted: Node3D) -> void:
	var thirsty := plants_thirsty() and not Engine.is_editor_hint()
	fresh.visible = not thirsty
	wilted.visible = thirsty


## Uppdaterar alla trädgårdsrabatter i ett träd (efter vattning eller en ny dag).
static func refresh_plants(tree: SceneTree) -> void:
	var fresh := tree.get_nodes_in_group(FRESH_GROUP)
	var wilted := tree.get_nodes_in_group(WILTED_GROUP)
	for i in mini(fresh.size(), wilted.size()):
		show_thirst(fresh[i], wilted[i])


## Trädgårdens följder av en handling (anropas av GameState.do_room_action). Returnerar
## korta texter till återkopplingen.
static func apply_action(action: Dictionary) -> Array[String]:
	var notes: Array[String] = []
	if _waters(action):
		if plants_thirsty():
			notes.append("The flower beds perk up")
		GameState.last_watered = GameState.day
	if action.get("calls_dog", false) and GameState.get_character_room("dog") != "backyard":
		GameState.set_schedule_override(DOG_OVERRIDE, "dog", "backyard", "playing",
				GameState.day, GameState.day, [GameState.get_time_of_day()])
		notes.append("Rex stays out in the garden")
	return notes


## Extra taggar i rummets meny för trädgårdens val.
static func tags(action: Dictionary) -> Array[String]:
	var parts: Array[String] = []
	if _waters(action) and plants_thirsty():
		parts.append("the plants are wilting")
	return parts


static func _waters(action: Dictionary) -> bool:
	if action.get("waters_plants", false):
		return true
	var chore: String = action.get("delegated_chore", "")
	if chore == "":
		return false
	for original: Dictionary in RoomActions.ACTIONS.get("backyard", []):
		if original["id"] == chore:
			return original.get("waters_plants", false)
	return false
