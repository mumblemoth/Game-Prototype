class_name PhoneData
## Innehållet i mammans iPhone: kontakter, samtal, sms, minnen och quests.
## Allt här är data; vad spelaren har hittat eller startat sparas i GameState.
## Platshållare tills riktig story skrivs. All text som spelaren ser är på engelska.

## Kontakter som kan finnas i telefonen. Kontakter som är familjemedlemmar har samma
## id som i GameState.CHARACTERS.
const CONTACTS := {
	"husband": {"name": "Eric", "color": Color(0.25, 0.4, 0.7)},
	"son_1": {"name": "Miles", "color": Color(0.3, 0.6, 0.35)},
	"son_2": {"name": "Tyler", "color": Color(0.85, 0.6, 0.2)},
	"principal": {"name": "Principal", "color": Color(0.5, 0.42, 0.62)},
	"best_friend": {"name": "Best Friend", "color": Color(0.85, 0.4, 0.55)},
	"neighbor": {"name": "Neighbor", "color": Color(0.55, 0.6, 0.85)},
	# Bankens sms om lön och räkningar (GameState._payday och _money_new_day).
	"bank": {"name": "Bank", "color": Color(0.3, 0.55, 0.45)},
}

## Vad som sägs när man ringer någon: repliker i ordning, [talare, text].
## "default" används för kontakter utan egna repliker.
const CALLS := {
	"husband": [["Eric", "Hey, you. Everything okay?"], ["Mom", "Just wanted to hear your voice. (Placeholder call.)"]],
	"default": [["", "The phone rings for a while…"], ["", "(Placeholder – the real call comes later.)"]],
}

## Vad man kan skriva till en kontakt och svaret man får: [ditt sms, svaret].
## "default" används för kontakter utan egna val.
const REPLIES := {
	"husband": [
		["Can you pick up coffee on the way home?", "Already on it :) (Placeholder reply.)"],
		["Miss you.", "Miss you more. (Placeholder reply.)"],
	],
	"default": [
		["Hi! How's your day going?", "Pretty good, thanks! (Placeholder reply.)"],
		["Are you home for dinner?", "Yep, see you then. (Placeholder reply.)"],
	],
}

## Sms som redan finns när spelet startar: kontakt -> [[avsändare, text]].
## Avsändaren är "me" (mamman) eller "them".
const START_MESSAGES := {
	"husband": [["them", "Don't forget we're out of coffee."]],
	"son_2": [["them", "can u drive me to practice tmrw??"]],
}

## Minnen som kan samlas i appen Memories. Två typer:
##   "picture" – en bild man hittar eller får i världen; visas över hela skärmen.
##       image  – bildens sökväg
##   "scene"   – en scen man har varit med om; kan upplevas igen.
##       scene  – scenens id i StoryScenes (minnet läggs till när scenen är slut)
##       thumb  – bild på rutan (valfri; annars ritas ett kort i tidszonens färg)
## title är minnets namn. source är varifrån det kom ("Found in the attic"); den kan
## skrivas över när minnet läggs till. Minnen som inte är upplåsta visas som låsta rutor.
## Minnen med bild (image eller thumb) kan bli bakgrundsbild; wallpaper_focus (0–1,
## valfri) säger vilken höjd i bilden som ska synas när den beskärs (0 = överkanten).
## När och var minnet kom, och hur en scen spelas igen, sparas i GameState.memories.
const MEMORIES := {
	"day1_morning": {"type": "scene", "title": "The First Day", "scene": "day1_morning"},
	"day1_night": {"type": "scene", "title": "One Day at a Time", "scene": "day1_night"},
	"mom_casual": {"type": "picture", "title": "Sunday Morning", "image": "res://Assets/2026-10-24_18-12-17-anima-base-v1.0-1795721044.png", "source": "Taken by Husband (placeholder)", "wallpaper_focus": 0.3},
	"mom_work": {"type": "picture", "title": "Ready for Class", "image": "res://Assets/2026-10-24_21-26-57-anima-base-v1.0-1490281203.png", "source": "School staff photo (placeholder)"},
	"mom_evening": {"type": "picture", "title": "After Hours", "image": "res://Assets/2026-10-24_21-17-30-anima-base-v1.0-1490281203.png", "source": "Found in the bedroom (placeholder)"},
	"secret_1": {"type": "picture", "title": "???", "image": ""},
	"secret_2": {"type": "scene", "title": "???", "scene": ""},
	"secret_3": {"type": "picture", "title": "???", "image": ""},
}


## Minnet som en scen ger, eller tom sträng om scenen inte blir ett minne.
static func memory_for_scene(scene_id: String) -> String:
	for memory_id in MEMORIES:
		if scene_id != "" and MEMORIES[memory_id].get("scene", "") == scene_id:
			return memory_id
	return ""

## Telefonens bakgrundsbilder. Två platser: låsskärmen och hemskärmen. Värdet i
## GameState.phone_wallpapers är "preset:<id>" eller "memory:<minnets id>".
const WALLPAPER_SLOTS := {"lock": "Lock Screen", "home": "Home Screen"}
const DEFAULT_WALLPAPERS := {"lock": "memory:mom_casual", "home": "preset:dusk"}
## Färdiga bakgrunder: en toning uppifrån och ned. Finns
## res://Assets/ui/phone/wallpapers/<id>.png används bilden i stället.
const WALLPAPER_PRESETS := {
	"dusk": {"name": "Dusk", "colors": [Color("f4b9a0"), Color("8d7fc4")]},
	"sage": {"name": "Sage", "colors": [Color("dfe6d2"), Color("6f9a7e")]},
	"terracotta": {"name": "Terracotta", "colors": [Color("f5d2b0"), Color("c0634a")]},
	"night": {"name": "Night", "colors": [Color("4a4a7a"), Color("1c1b2e")]},
}


## Bakgrundens namn, t.ex. "Dusk" eller minnets titel.
static func wallpaper_name(value: String) -> String:
	var parts := value.split(":")
	if parts[0] == "preset":
		return WALLPAPER_PRESETS.get(parts[1], {}).get("name", "")
	return MEMORIES.get(parts[1], {}).get("title", "")


## Bilden ett minne har att visa som bakgrund, eller tom sträng.
static func memory_image(memory_id: String) -> String:
	var memory: Dictionary = MEMORIES.get(memory_id, {})
	return memory.get("image", memory.get("thumb", ""))

## Quests som kan startas. Journalen visar startade och avklarade.
const QUESTS := {
	"first_week": {"title": "One Day at a Time", "description": "Get through your first week without letting home, work or romance fall apart. (Placeholder quest.)"},
	"coffee": {"title": "Out of Coffee", "description": "Your husband says you're out of coffee. Pick some up after school. (Placeholder quest.)"},
	"practice": {"title": "Ride to Practice", "description": "Son 2 needs a ride to practice. (Placeholder quest.)"},
}
