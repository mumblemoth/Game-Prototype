extends Node
## Globalt speltillstÃ¥nd (autoload "GameState"): livsomrÃ¥denas mÃ¤tare, dygnets
## tidszoner med morgon- och nattscener, och vilket rum spelaren befinner sig i.

signal stats_changed
signal message_posted(text: String)
## En handling har gjorts: texten och mÃ¤tarnas Ã¤ndringar ("Hemmet +15").
signal action_performed(text: String, changes: String)
signal hint_changed(text: String)
signal day_ended
signal room_changed(room_id: String)
signal time_of_day_changed(period: String)
signal map_toggled(is_open: bool)
## En scen ska spelas (morgon- eller nattscen). Spelaren har inte kontroll fÃ¶rrÃ¤n
## finish_scene() anropas.
signal scene_requested(scene_id: String)
signal scene_finished
## NÃ¥got i telefonen har Ã¤ndrats (ny kontakt, sms, minne eller quest).
signal phone_changed
## Ett scenminne ska spelas igen, och nÃ¤r det Ã¤r slut.
signal memory_replay_requested(memory_id: String)
signal memory_replay_finished(memory_id: String)
## Mammans utseende har Ã¤ndrats (klÃ¤der, smink, hÃ¥r ...).
signal appearance_changed
## NÃ¥got som kan lÃ¥sa upp platser har Ã¤ndrats (en hÃ¤ndelse i storyn).
signal locations_changed
## En relation har fÃ¥tt poÃ¤ng eller gÃ¥tt upp i rank.
signal link_changed(character_id: String)
## Mammans egenskaper (Charm, Knowledge, Fitness) har Ã¤ndrats.
signal social_changed
## NÃ¥gon har bytt rum eller aktivitet (ny tidszon, ny dag eller en hÃ¤ndelse i storyn).
## VÃ¤rlden ritar om personerna pÃ¥ den hÃ¤r signalen.
signal schedules_changed
## En person har flyttat; tom strÃ¤ng betyder borta frÃ¥n kartan.
signal character_moved(character_id: String, from_room: String, to_room: String)
## En framtida NPC har fÃ¶rts in i vÃ¤rlden (har fÃ¥tt rutin, social link och kontakt).
signal character_introduced(character_id: String)
## Saldot har Ã¤ndrats (lÃ¶n, rÃ¤kning, kÃ¶p eller sidoinkomst).
signal money_changed
## En mÃ¤tare, en fÃ¶rfrÃ¥gan eller en skuld i Requests har Ã¤ndrats.
signal requests_changed
## En dialogruta har Ã¶ppnats eller stÃ¤ngts. Telefonen gÃ¶ms och spÃ¤rras medan active Ã¤r sant.
signal dialogue_changed(active: bool)

## Dygnets fasta tidszoner, som i Persona. Bara eftermiddagen och kvÃ¤llen Ã¤r spelbara:
##   Morgon      â€“ dagen bÃ¶rjar hÃ¤r; en scen visas om dagen har en, annars hoppas den Ã¶ver.
##   Eftermiddag â€“ efter jobbet pÃ¥ skolan; en aktivitet som tar tid leder till kvÃ¤llen.
##   KvÃ¤ll       â€“ en aktivitet till, sedan Ã¤r den spelbara delen av dagen slut.
##   Natt        â€“ en scen visas om dagen har en; sedan Ã¤r dagen slut.
const TIME_PERIODS := ["morning", "afternoon", "evening", "night"]
const PLAYABLE_PERIODS := ["afternoon", "evening"]
const PERIOD_NAMES := {
	"morning": "Morning",
	"afternoon": "Afternoon",
	"evening": "Evening",
	"night": "Night",
}
const WEEKDAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

## Alla rum. Nyckeln Ã¤r rummets id; scenen ligger i res://scenes/rooms/<id>.tscn.
const ROOMS := {
	"attic": {"name": "Attic", "floor": "Attic"},
	"upstairs_hall": {"name": "Upstairs Hall", "floor": "Upstairs"},
	"son_room_1": {"name": "Son's Room 1", "floor": "Upstairs"},
	"son_room_2": {"name": "Son's Room 2", "floor": "Upstairs"},
	"bathroom": {"name": "Bathroom", "floor": "Upstairs"},
	"bedroom": {"name": "Bedroom", "floor": "Upstairs"},
	"hall": {"name": "Hallway", "floor": "Ground Floor"},
	"kitchen": {"name": "Kitchen", "floor": "Ground Floor"},
	"living_room": {"name": "Living Room", "floor": "Ground Floor"},
	"home_office": {"name": "Home Office", "floor": "Ground Floor"},
	"guest_wc": {"name": "Guest Bathroom", "floor": "Ground Floor"},
	"basement_hall": {"name": "Basement Hall", "floor": "Basement"},
	"laundry": {"name": "Laundry Room", "floor": "Basement"},
	"hobby_room": {"name": "Hobby Room", "floor": "Basement"},
	"storage": {"name": "Storage", "floor": "Basement"},
	"outside": {"name": "Front Yard", "floor": "Outside"},
	"backyard": {"name": "Backyard", "floor": "Outside"},
	# Platserna i grannskapet (Locations); "floor" Ã¤r platsens namn.
	"classroom": {"name": "Classroom", "floor": "School"},
	"teachers_lounge": {"name": "Teachers' Lounge", "floor": "School"},
	"neighbor_living": {"name": "Neighbor's Living Room", "floor": "Neighbor's House"},
	"gym": {"name": "Gym Floor", "floor": "Fitness Center"},
	"yoga_studio": {"name": "Yoga Studio", "floor": "Fitness Center"},
	"locker_room": {"name": "Locker Room", "floor": "Fitness Center"},
	"entrance": {"name": "Main Entrance", "floor": "Shopping Center"},
	"center_court": {"name": "Center Court", "floor": "Shopping Center"},
	"west_promenade": {"name": "West Promenade", "floor": "Shopping Center"},
	"east_promenade": {"name": "East Promenade", "floor": "Shopping Center"},
	"grocery": {"name": "Grocery Store", "floor": "Shopping Center"},
	"boutique": {"name": "Clothing Boutique", "floor": "Shopping Center"},
	"restaurant": {"name": "Restaurant", "floor": "Shopping Center"},
	"salon": {"name": "Hair Salon", "floor": "Shopping Center"},
	"cafe": {"name": "CafÃ©", "floor": "Shopping Center"},
	"bookstore": {"name": "Bookstore", "floor": "Shopping Center"},
	"park": {"name": "Park", "floor": "Park"},
}
## DÃ¶rrar mellan rum som saknar gamla rumsscener (rummen i platserna).
const ROOM_LINKS := {
	"neighbor_living": [],
	"gym": ["yoga_studio", "locker_room"],
	"yoga_studio": ["gym", "locker_room"],
	"locker_room": ["gym", "yoga_studio"],
	# KÃ¶pcentret: ingÃ¥ngen leder till ljusgÃ¥rden med fontÃ¤nen, och promenaderna Ã¥t
	# vÃ¤ster och Ã¶ster gÃ¥r till ankarbutikerna i Ã¤ndarna (livsmedel och klÃ¤der).
	"entrance": ["center_court"],
	"center_court": ["entrance", "west_promenade", "east_promenade", "cafe", "bookstore"],
	"west_promenade": ["center_court", "grocery", "restaurant"],
	"east_promenade": ["center_court", "boutique", "salon"],
	"grocery": ["west_promenade"],
	"restaurant": ["west_promenade"],
	"cafe": ["center_court"],
	"boutique": ["east_promenade"],
	"salon": ["east_promenade"],
	"bookstore": ["center_court"],
	"park": [],
}
## VÃ¥ningarna som rÃ¤knas som hemma.
const HOME_FLOORS := ["Attic", "Upstairs", "Ground Floor", "Basement", "Outside"]
const START_ROOM := "kitchen"

## Familjen och huvud-NPC:erna. Familjens namn Ã¤r satta, NPC:ernas Ã¤r platshÃ¥llare. Var de Ã¤r stÃ¥r i
## Schedules. Framtida NPC:er har introduced_by: hÃ¤ndelsen (flags) som fÃ¶r in dem i
## vÃ¤rlden. Innan dess heter de stranger_name om de syns, och dÃ¥ har de ingen social link.
const CHARACTERS := {
	"mom": {"name": "Mom", "initials": "Ma", "color": Color(0.78, 0.3, 0.2)},
	"husband": {"name": "Eric", "initials": "Er", "color": Color(0.25, 0.4, 0.7)},
	"son_1": {"name": "Miles", "initials": "Mi", "color": Color(0.3, 0.6, 0.35)},
	"son_2": {"name": "Tyler", "initials": "Ty", "color": Color(0.85, 0.6, 0.2)},
	"dog": {"name": "Rex", "initials": "R", "color": Color(0.55, 0.4, 0.28)},
	"neighbor": {"name": "Neighbor", "initials": "Nb", "color": Color(0.55, 0.6, 0.85), "introduced_by": "met_neighbor", "stranger_name": "New Neighbor"},
	"principal": {"name": "Principal", "initials": "Pr", "color": Color(0.5, 0.42, 0.62), "introduced_by": "met_principal", "stranger_name": "Principal"},
	"best_friend": {"name": "Best Friend", "initials": "BF", "color": Color(0.85, 0.4, 0.55), "introduced_by": "met_best_friend", "stranger_name": "Familiar Face"},
}

const STAT_MAX := 100
## Hur mycket varje mÃ¤tare sjunker Ã¶ver natten.
const NIGHTLY_DECAY := 10

const STAT_NAMES := {
	"home": "Home",
	"work": "Work",
}

var day := 1
## Index i TIME_PERIODS. Lika med TIME_PERIODS.size() nÃ¤r dagen Ã¤r slut.
var period := 0
var stats := {"home": 50, "work": 50}
var current_room := START_ROOM
var map_open := false
## Scenen som spelas just nu, eller tom strÃ¤ng.
var playing_scene := ""
## En rankscen startades av talk_to(); tiden går vidare när dialogen är slut.
var _rank_scene_started := false

# Telefonen (innehÃ¥llet finns i PhoneData).
## Kontakter mamman har i telefonen.
var known_contacts: Array[String] = ["husband", "son_1", "son_2"]
## Sms-trÃ¥dar: kontakt -> [[avsÃ¤ndare, text]], avsÃ¤ndaren Ã¤r "me" eller "them".
var messages := {}
## Kontakter med olÃ¤sta sms.
var unread: Array[String] = []
## Minnen spelaren har fÃ¥tt (vad de Ã¤r stÃ¥r i PhoneData.MEMORIES). Bara vanliga vÃ¤rden,
## sÃ¥ att det kan sparas som det Ã¤r:
##   memory_id -> {
##     "day": int, "period": String  â€“ nÃ¤r minnet kom
##     "room": String                â€“ var mamman var (id i ROOMS)
##     "source": String              â€“ varifrÃ¥n, om det skiljer sig frÃ¥n PhoneData ("" annars)
##     "seen": bool                  â€“ false tills spelaren har Ã¶ppnat det i telefonen
##     "replay": {                   â€“ bara scener: hur scenen spelas igen
##       "scene": String,            â€“   id i StoryScenes
##       "flags": Dictionary,        â€“   hÃ¤ndelserna nÃ¤r scenen bÃ¶rjade (styr vilka repliker som visas)
##     }
##   }
var memories := {}
## Minnet som spelas upp igen just nu, eller tom strÃ¤ng.
var replaying_memory := ""
## Startade quests: quest -> "active" eller "completed".
var quests := {"first_week": "active", "coffee": "active"}
## Telefonens bakgrunder: plats ("lock"/"home") -> "preset:<id>" eller "memory:<id>".
var phone_wallpapers := PhoneData.DEFAULT_WALLPAPERS.duplicate()

# Mamman och relationerna.
## Hur mamman ser ut: kategori -> val (se AppearanceData).
var appearance := AppearanceData.DEFAULTS.duplicate()
## Relationer (social links) i Persona-anda: person -> {rank, points, lust}.
## lust Ã¤r 0â€“100 (se CONTRACT.md, avsnitt 2).
var links := {"son_1": {"rank": 1, "points": 0, "lust": 0.0}, "son_2": {"rank": 1, "points": 0, "lust": 0.0}, "husband": {"rank": 1, "points": 0, "lust": 0.0}}
## Mammans egenskaper: egenskap -> XP (nivÃ¥er och namn finns i SocialStats).
var social := {"charm": 0, "knowledge": 0, "fitness": 0}
## Dagen dÃ¥ en egenskap som kan tappas (SocialStats.DECAY) senast trÃ¤nades.
var last_trained := {"fitness": 1}
## Snabba handlingar som redan gjorts i dag (de ger bara effekt en gÃ¥ng per dag).
var used_today: Array[String] = []
## HÃ¤ndelser i storyn som har hÃ¤nt (lÃ¥ser upp platser och annat), t.ex. "met_neighbor".
var flags := {}
## Scheman som storyn har Ã¤ndrat (gÃ¥r fÃ¶re Schedules regler och rutiner). Sparas med spelet:
##   override_id -> {"character", "room", "activity", "from_day", "to_day" (-1 = tills
##   vidare), "periods" ([] = hela dygnet)}
var schedule_overrides := {}
## Var alla Ã¤r just nu (Schedules.resolve fÃ¶r dagen och tidszonen). RÃ¤knas om av
## refresh_schedules(), sÃ¥ att frÃ¥gor under tidszonen inte behÃ¶ver rÃ¤kna.
var whereabouts := {}

# Ekonomin (priser, lÃ¶n och rÃ¤kningar finns i Economy).
## Pengarna pÃ¥ kontot. Kan gÃ¥ minus av rÃ¤kningar, men inte av kÃ¶p.
var money := Economy.START_MONEY
## Kontoutdraget, nyast sist: [{"day", "label", "amount"}]. Bara de senaste LEDGER_MAX.
var ledger: Array[Dictionary] = []
## Saker hon har kÃ¶pt: id i Economy.PURCHASES och "kategori:val" i Economy.LOOKS.
var owned: Array[String] = []
## Saker i huset som Ã¤r sÃ¥lda (Economy.SELLABLES).
var sold: Array[String] = []
## Abonnemang som lÃ¶per (Economy.SUBSCRIPTIONS).
var subscriptions: Array[String] = []
## Saker hon har flera av: sak -> antal (Economy.ITEMS).
var inventory := {}
## Vad varje sidoinkomst har gett hittills: income_id -> summa.
var income_earned := {}
## Work varje kvÃ¤ll sedan fÃ¶rra lÃ¶nen: summan och antalet kvÃ¤llar (ger bonusen).
var work_log := {"sum": 0, "days": 0}
## Dagen dÃ¥ veckohandlingen senast gjordes (annars blir det hÃ¤mtmat).
var last_groceries := 1
## Dagen dÃ¥ trÃ¤dgÃ¥rdens rabatter senast vattnades (se Backyard).
var last_watered := 1

# FÃ¶rfrÃ¥gningar (mÃ¤tare, typer och sysslor finns i Requests).
## MÃ¤tarna 0â€“100: person -> vÃ¤rde. Desire fÃ¶r vuxna och mamman, wants fÃ¶r sÃ¶nerna.
var meters := {}
## Ã–ppna fÃ¶rfrÃ¥gningar: person -> {"type": id i Requests.TYPES, "day": dagen den kom}.
var requests := {}
## Sysslor personer Ã¤r skyldiga mamman: person -> antal.
var owed := {}
## Dagen dÃ¥ personens fÃ¶rra fÃ¶rfrÃ¥gan avslutades (fÃ¶r cooldown).
var last_request := {}

## DÃ¶rrarna mellan rummen: room_id -> {mÃ¥lrum: restid}. LÃ¤ses frÃ¥n rumsscenerna.
var _exits := {}
## HÃ¤ndelserna nÃ¤r den pÃ¥gÃ¥ende scenen bÃ¶rjade (sparas i scenens minne).
var _scene_flags := {}


func _ready() -> void:
	for room_id in ROOMS:
		var links := {}
		# Husets rum har gamla rumsscener med dÃ¶rrarna; nya platser anger dem i ROOM_LINKS.
		if ResourceLoader.exists(get_room_scene_path(room_id)):
			var room: Node = load(get_room_scene_path(room_id)).instantiate()
			for child in room.get_children():
				if child.get("target_room") != null:
					links[child.target_room] = child.travel_minutes
			room.free()
		for target in ROOM_LINKS.get(room_id, []):
			links[target] = 0
		_exits[room_id] = links
	for contact_id in PhoneData.START_MESSAGES:
		messages[contact_id] = (PhoneData.START_MESSAGES[contact_id] as Array).duplicate(true)
		unread.append(contact_id)
	for memory_id in ["mom_casual", "mom_work"]:
		_record_memory(memory_id, "Already on your phone")
		memories[memory_id]["seen"] = true
	Requests.validate()
	for character_id in Requests.DESIRE.keys() + Requests.WANTS.keys():
		meters[character_id] = Requests.meter_info(character_id).get("start", 20.0)
	refresh_schedules()


## BÃ¶rjar om frÃ¥n bÃ¶rjan (New Game pÃ¥ titelskÃ¤rmen): alla variabler fÃ¥r sina startvÃ¤rden
## frÃ¥n en ny, tillfÃ¤llig GameState, och mammans egna gardinval glÃ¶ms.
func reset() -> void:
	var fresh: Node = get_script().new()
	fresh._ready()
	for property in get_script().get_script_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(property["name"], fresh.get(property["name"]))
	fresh.free()
	Curtains.reset()
	refresh_schedules()


# --- Rummens handlingar, utseende och relationer ---------------------------------

## PoÃ¤ng som krÃ¤vs fÃ¶r att nÃ¥ varje rank (index = rank). Rank 10 Ã¤r max.
const LINK_THRESHOLDS := [0, 0, 3, 7, 12, 18, 25, 33, 42, 52, 63]
const LINK_MAX_RANK := 10


## VarfÃ¶r en handling i ett rum inte gÃ¥r att gÃ¶ra just nu, eller tom strÃ¤ng om den gÃ¥r.
func action_block_reason(action: Dictionary, room_id: String) -> String:
	# "needs": personen mÃ¥ste vara i rummet; "needs_home": nÃ¥gonstans i huset.
	for key in ["needs", "needs_home"]:
		var who: String = action.get(key, "")
		if who == "":
			continue
		var where := get_character_room(who)
		var home: bool = where != "" and ROOMS.has(where) and ROOMS[where]["floor"] in HOME_FLOORS
		var person := character_name(who)
		# Den som Ã¤r i rummet Ã¤r "hemma" Ã¤ven i en plats (t.ex. grannen i sitt hus).
		if not home and where != room_id:
			return "%s isn't home" % person
		if key == "needs" and where != room_id:
			return "%s isn't here" % person
		if is_busy(who):
			return "%s is %s" % [person, Schedules.ACTIVITIES[whereabouts[who]["activity"]]["label"].to_lower()]
	if action.get("periods", []).size() > 0 and not get_time_of_day() in action["periods"]:
		return "Only in the %s" % " or ".join(Array(action["periods"]).map(func(p: String) -> String: return PERIOD_NAMES[p].to_lower()))
	var weekdays: Array = action.get("weekdays", [])
	if not weekdays.is_empty() and not ((day - 1) % WEEKDAYS.size()) in weekdays:
		return "Only on %s" % " and ".join(weekdays.map(func(d: int) -> String: return WEEKDAYS[d] + "s"))
	var missing := requirement_block_reason(action.get("requires", {}))
	if missing != "":
		return missing
	if _once_per_day(action) and action["id"] in used_today:
		return "Done today"
	var item: String = action.get("needs_item", "")
	if item != "" and inventory.get(item, 0) < 1:
		return "You don't have a %s" % Economy.ITEMS[item]["name"].to_lower()
	var cost := action_cost(action)
	if cost > money:
		return "Costs %s â€“ you have %s" % [Economy.format(cost), Economy.format(money)]
	return ""


## Snabba handlingar som ger nÃ¥got (mÃ¤tare, egenskap eller relation) gÃ¥r bara en gÃ¥ng per dag.
func _once_per_day(action: Dictionary) -> bool:
	return not action.get("time", false) and (not action.get("effects", {}).is_empty() or action.get("relief", 0) > 0 or not action.get("social", {}).is_empty() or action.get("link", "") != "")


## UtfÃ¶r en handling frÃ¥n ett rums meny: mÃ¤tare, relation, dagens anvÃ¤ndning och tid.
func do_room_action(action: Dictionary) -> void:
	if not is_playable():
		return
	var cost := action_cost(action)
	if cost > 0 and not spend(cost, action.get("ledger_label", action["label"])):
		return
	if _once_per_day(action):
		used_today.append(action["id"])
	var link: String = action.get("link", "")
	var link_note := ""
	if link != "":
		var points: int = action.get("link_points", 1)
		var bonus := 1 if points > 0 and attractiveness_tier() >= SocialStats.LINK_BONUS_TIER else 0
		link_note = add_link_points(link, points + bonus)
	var changes: Array[String] = []
	if cost > 0:
		changes.append(Economy.format(-cost))
	changes.append_array(_apply_money_action(action))
	for key in action.get("effects", {}):
		var delta: int = action["effects"][key]
		if delta == 0:
			continue
		stats[key] = clampi(stats[key] + delta, 0, STAT_MAX)
		changes.append("%s %+d" % [STAT_NAMES[key], delta])
	_relieve_mom(action.get("relief", 0))
	for stat in action.get("social", {}):
		changes.append(add_social_xp(stat, action["social"][stat]))
	if link_note != "":
		changes.append(link_note)
	changes.append_array(_apply_request_action(action))
	changes.append_array(Backyard.apply_action(action))
	# Handlingar kan fÃ¶ra storyn framÃ¥t: sÃ¤tta en hÃ¤ndelse eller avsluta en quest.
	if action.get("sets_flag", "") != "":
		var income_id := Economy.income_for_flag(action["sets_flag"])
		if income_id != "" and not has_flag(action["sets_flag"]):
			changes.append("â˜… New way to earn: %s" % Economy.SIDE_INCOME[income_id]["name"])
		set_flag(action["sets_flag"])
	if action.get("completes", "") != "":
		complete_quest(action["completes"])
	action_performed.emit(action["text"], ", ".join(changes))
	stats_changed.emit()
	if action.get("time", false):
		advance_period()


## Ger poÃ¤ng i en relation. Returnerar en kort text fÃ¶r Ã¥terkopplingen, t.ex.
## "Son 1 â™¥ +2" eller "Son 1 â™¥ Rank 3!" nÃ¤r relationen gÃ¥r upp en rank. MinuspoÃ¤ng
## (t.ex. nÃ¤r man sÃ¤ljer nÃ¥gons saker) tar aldrig bort en rank, bara vÃ¤gen mot nÃ¤sta.
func add_link_points(character_id: String, points: int) -> String:
	var link: Dictionary = links[character_id]
	var person: String = CHARACTERS[character_id]["name"]
	if link["rank"] >= LINK_MAX_RANK:
		return "%s â™¥ max" % person
	link["points"] = maxi(link["points"] + points, LINK_THRESHOLDS[link["rank"]])
	var note := "%s â™¥ %+d" % [person, points]
	var old_rank: int = link["rank"]
	while link["rank"] < LINK_MAX_RANK and link["points"] >= LINK_THRESHOLDS[link["rank"] + 1]:
		link["rank"] += 1
		note = "%s â™¥ Rank %d!" % [person, link["rank"]]
	link_changed.emit(character_id)
	# Scheman kan bero pÃ¥ rank (link_rank i Schedules.RULES).
	if link["rank"] != old_rank:
		refresh_schedules()
	return note


## Ger XP i en egenskap. Returnerar en kort text fÃ¶r Ã¥terkopplingen, t.ex. "Charm +4"
## eller "Charm â†‘ Charismatic!" nÃ¤r den gÃ¥r upp en nivÃ¥. Meddelar ocksÃ¥ om
## Attractiveness nÃ¥r en ny nivÃ¥.
func add_social_xp(stat: String, xp: int) -> String:
	var old_level := social_level(stat)
	var old_tier := attractiveness_tier()
	social[stat] += xp
	if last_trained.has(stat):
		last_trained[stat] = day
	var stat_name: String = SocialStats.STATS[stat]["name"]
	var note := "%s +%d" % [stat_name, xp]
	var level := social_level(stat)
	if level > old_level:
		note = "%s â†‘ %s!" % [stat_name, SocialStats.level_name(stat, level)]
		message_posted.emit("%s rose to level %d: %s." % [stat_name, level, SocialStats.level_name(stat, level)])
	var tier := attractiveness_tier()
	if tier > old_tier:
		var unlock: String = SocialStats.ATTRACTIVENESS_UNLOCKS.get(tier, "")
		message_posted.emit("Attractiveness %.1f â€“ %s!%s" % [attractiveness(), SocialStats.attractiveness_title(attractiveness()), " " + unlock + "." if unlock != "" else ""])
	social_changed.emit()
	return note


func social_level(stat: String) -> int:
	return SocialStats.level_for_xp(social[stat])


## Hur lÃ¥ngt en egenskap har kommit mot nÃ¤sta nivÃ¥, 0â€“1.
func social_progress(stat: String) -> float:
	var level := social_level(stat)
	if level >= SocialStats.MAX_LEVEL:
		return 1.0
	var low: int = SocialStats.LEVEL_XP[level - 1]
	var high: int = SocialStats.LEVEL_XP[level]
	return clampf(float(social[stat] - low) / float(high - low), 0.0, 1.0)


## MedelvÃ¤rdet av de tre nivÃ¥erna, 1.0â€“5.0.
func attractiveness() -> float:
	return (social_level("charm") + social_level("knowledge") + social_level("fitness")) / 3.0


## Attractiveness avrundat nedÃ¥t, 1â€“5 (bestÃ¤mmer namnet och vad som Ã¤r upplÃ¥st).
func attractiveness_tier() -> int:
	return floori(attractiveness())


## VarfÃ¶r krav pÃ¥ egenskaper inte uppfylls, eller tom strÃ¤ng. Kraven Ã¤r t.ex.
## {"charm": 3} eller {"attractiveness": 4}. AnvÃ¤nds av rummens val och senare av
## dialogval.
func requirement_block_reason(requires: Dictionary) -> String:
	for key in requires:
		var needed: int = requires[key]
		if key == "attractiveness":
			if attractiveness_tier() < needed:
				return "Needs %s Attractiveness (%d)" % [SocialStats.ATTRACTIVENESS_TITLES[needed - 1], needed]
		elif social_level(key) < needed:
			return "Needs %s %s (%d)" % [SocialStats.level_name(key, needed), SocialStats.STATS[key]["name"], needed]
	return ""


## Egenskaper som inte har trÃ¤nats pÃ¥ ett tag tappar lite XP, men aldrig en nivÃ¥.
func _decay_social() -> void:
	for stat in SocialStats.DECAY:
		var rule: Dictionary = SocialStats.DECAY[stat]
		if day - last_trained[stat] <= rule["grace_days"]:
			continue
		var floor_xp: int = SocialStats.LEVEL_XP[social_level(stat) - 1]
		if social[stat] > floor_xp:
			social[stat] = maxi(social[stat] - rule["xp"], floor_xp)
			message_posted.emit(rule["text"])
			social_changed.emit()


## Hur lÃ¥ngt en relation har kommit mot nÃ¤sta rank, 0â€“1.
func link_progress(character_id: String) -> float:
	var link: Dictionary = links[character_id]
	if link["rank"] >= LINK_MAX_RANK:
		return 1.0
	var low: int = LINK_THRESHOLDS[link["rank"]]
	var high: int = LINK_THRESHOLDS[link["rank"] + 1]
	return clampf(float(link["points"] - low) / float(high - low), 0.0, 1.0)


# --- Pengar -----------------------------------------------------------------------

const LEDGER_MAX := 60


## Vad en handling kostar just nu (0 om ett abonnemang gÃ¶r den gratis).
func action_cost(action: Dictionary) -> int:
	var waived: String = action.get("waived_by", "")
	if waived != "":
		for subscription in subscriptions:
			if Economy.SUBSCRIPTIONS[subscription]["waives"] == waived:
				return 0
	return action.get("cost", 0)


## Vad en handling ger, med earn_scale utrÃ¤knat efter mammans nivÃ¥er.
func action_earnings(action: Dictionary) -> int:
	var levels := {}
	for stat in social:
		levels[stat] = social_level(stat)
	var amount := Economy.scaled(action.get("earn", 0), action.get("earn_scale", {}), levels)
	if attractiveness_tier() >= SocialStats.EARNINGS_BONUS_TIER:
		amount = roundi(amount * SocialStats.EARNINGS_BONUS)
	return amount


## Pengar in. income Ã¤r sidoinkomsten de rÃ¤knas till ("" fÃ¶r lÃ¶n och annat).
func earn(amount: int, label: String, income := "") -> void:
	if income != "":
		income_earned[income] = income_earned.get(income, 0) + amount
	_book(amount, label)


## Ett kÃ¶p spelaren sjÃ¤lv vÃ¤ljer. Blir inget om pengarna inte rÃ¤cker.
func spend(amount: int, label: String) -> bool:
	if amount > money:
		return false
	_book(-amount, label)
	return true


## En rÃ¤kning dras alltid, Ã¤ven om kontot hamnar pÃ¥ minus.
func pay_bill(amount: int, label: String) -> void:
	_book(-amount, label)


func _book(amount: int, label: String) -> void:
	money += amount
	ledger.append({"day": day, "label": label, "amount": amount})
	if ledger.size() > LEDGER_MAX:
		ledger.pop_front()
	money_changed.emit()


## Om ett utseende gÃ¥r att vÃ¤lja: det Ã¤r inte till salu, eller hon har kÃ¶pt det.
func owns_look(category: String, option_id: String) -> bool:
	var key := "%s:%s" % [category, option_id]
	return not Economy.LOOKS.has(key) or key in owned


## Hur mycket mindre en mÃ¤tare sjunker varje natt tack vare saker hon har kÃ¶pt.
func decay_reduction(stat: String) -> int:
	var total := 0
	for id in owned:
		total += Economy.PURCHASES.get(id, {}).get("decay", {}).get(stat, 0)
	return total


func days_until_payday() -> int:
	return posmod(Economy.PAYDAY - Economy.day_of_month(day), Economy.MONTH_DAYS)


## Dagar tills rÃ¤kningarna dras. Den allra fÃ¶rsta dagen dras inga, sÃ¥ dÃ¥ Ã¤r det en mÃ¥nad.
func days_until_bills() -> int:
	var days := posmod(Economy.BILL_DAY - Economy.day_of_month(day), Economy.MONTH_DAYS)
	return Economy.MONTH_DAYS if days == 0 and day == 1 else days


## Pengadelen av en handling: inkomst, saker, kÃ¶p, fÃ¶rsÃ¤ljningar och abonnemang.
## Returnerar texterna fÃ¶r Ã¥terkopplingen.
func _apply_money_action(action: Dictionary) -> Array[String]:
	var changes: Array[String] = []
	if action.has("earn"):
		var amount := action_earnings(action)
		earn(amount, action.get("ledger_label", action["label"]), action.get("income", ""))
		changes.append("+" + Economy.format(amount))
	var used: String = action.get("needs_item", "")
	if used != "":
		inventory[used] = inventory.get(used, 0) - 1
	var item: String = action.get("gives_item", "")
	if item != "":
		var info: Dictionary = Economy.ITEMS[item]
		if inventory.get(item, 0) < info["max"]:
			inventory[item] = inventory.get(item, 0) + 1
			changes.append("+1 %s (%d)" % [info["name"], inventory[item]])
	if action.get("buys", "") != "":
		owned.append(action["buys"])
		if action["buys"] in Economy.PURCHASES and Economy.PURCHASES[action["buys"]].has("decay"):
			changes.append("slows the nightly slip")
	if action.get("sells", "") != "":
		sold.append(action["sells"])
	if action.get("subscribe", "") != "":
		subscriptions.append(action["subscribe"])
	if action.get("unsubscribe", "") != "":
		subscriptions.erase(action["unsubscribe"])
	if action.get("groceries", false):
		last_groceries = day
	return changes


## Allt som hÃ¤nder med pengarna nÃ¤r en ny dag bÃ¶rjar: lÃ¶n, rÃ¤kningar, hÃ¤mtmat,
## ovÃ¤ntade rÃ¤kningar och oro om kontot Ã¤r pÃ¥ minus. Returnerar texter till dagens
## meddelande; detaljerna kommer som sms frÃ¥n banken.
func _money_new_day() -> Array[String]:
	var notes: Array[String] = []
	var day_of_month := Economy.day_of_month(day)
	var month := Economy.month_of(day)
	var billed := false
	if day_of_month == Economy.PAYDAY:
		notes.append(_payday())
	if day_of_month == Economy.BILL_DAY and month > 1:
		var total := 0
		for id in Economy.MONTHLY_BILLS:
			pay_bill(Economy.MONTHLY_BILLS[id]["amount"], Economy.MONTHLY_BILLS[id]["name"])
			total += Economy.MONTHLY_BILLS[id]["amount"]
		for subscription in subscriptions:
			pay_bill(Economy.SUBSCRIPTIONS[subscription]["amount"], Economy.SUBSCRIPTIONS[subscription]["name"])
			total += Economy.SUBSCRIPTIONS[subscription]["amount"]
		billed = true
		notes.append("The monthly bills came out: %s." % Economy.format(total))
		receive_message("bank", "Monthly bills paid: %s. Balance: %s." % [Economy.format(total), Economy.format(money)])
	for id in Economy.WEEKLY_BILLS:
		var bill: Dictionary = Economy.WEEKLY_BILLS[id]
		if (day - 1) % WEEKDAYS.size() == bill["weekday"]:
			pay_bill(bill["amount"], bill["name"])
			billed = true
	var surprise := Economy.surprise_for_month(month)
	if not surprise.is_empty() and surprise["day"] == day_of_month:
		var bill: Dictionary = Economy.SURPRISE_BILLS[surprise["id"]]
		pay_bill(bill["amount"], bill["name"])
		billed = true
		notes.append(bill["text"])
	if day - last_groceries > Economy.GROCERY_GRACE_DAYS:
		pay_bill(Economy.TAKEOUT["amount"], "Takeout")
		for key in Economy.TAKEOUT["effects"]:
			stats[key] = clampi(stats[key] + Economy.TAKEOUT["effects"][key], 0, STAT_MAX)
		# NÃ¤sta hÃ¤mtmat om tre dagar, om ingen handlar innan dess.
		last_groceries = day - Economy.GROCERY_GRACE_DAYS + 2
		notes.append(Economy.TAKEOUT["text"])
	if billed and money < 0:
		pay_bill(Economy.LATE_FEE, "Late fee")
	if money < 0:
		for key in Economy.DEBT_STRESS:
			stats[key] = clampi(stats[key] + Economy.DEBT_STRESS[key], 0, STAT_MAX)
		notes.append(Economy.DEBT_TEXT)
	return notes


## LÃ¶nen: grundlÃ¶n och lÃ¶neÃ¶kningar, plus bonus efter hur Work har skÃ¶tts.
func _payday() -> String:
	var salary := Economy.salary(flags)
	earn(salary, "Salary â€“ %s" % Economy.SALARY["employer"])
	var average := float(work_log["sum"]) / maxi(work_log["days"], 1)
	var bonus := Economy.merit_bonus(average)
	var bonus_text := ""
	if not bonus.is_empty():
		earn(bonus["amount"], bonus["text"])
		bonus_text = " + %s bonus" % Economy.format(bonus["amount"])
	work_log = {"sum": 0, "days": 0}
	receive_message("bank", "Salary deposited: %s%s from %s. Balance: %s." % [Economy.format(salary), bonus_text, Economy.SALARY["employer"], Economy.format(money)])
	return "Payday! %s%s landed in your account." % [Economy.format(salary), bonus_text]


# --- FÃ¶rfrÃ¥gningar ------------------------------------------------------------------

func _change_meter(character_id: String, delta: float) -> void:
	if not meters.has(character_id) or delta == 0:
		return
	meters[character_id] = clampf(meters[character_id] + delta, 0.0, 100.0)
	requests_changed.emit()


## Det som fÃ¥r mamman att varva ner (relief i handlingar och scener) sÃ¤nker hennes egen
## mÃ¤tare med amount Ã— Requests.MOM_EFFECTS["relief_scale"]. Kan anropas frÃ¥n dialog:
## $> GameState.relieve_mom(10)
func relieve_mom(amount: float) -> void:
	if amount > 0:
		_change_meter("mom", -amount * Requests.MOM_EFFECTS["relief_scale"])


## Det apply() och do_room_action() anropar; rÃ¤knar via relieve_mom().
func _relieve_mom(relief: int) -> void:
	relieve_mom(relief)


## Hur fort en persons mÃ¤tare vÃ¤xer just nu, utÃ¶ver kurvan (se Requests).
func _meter_multiplier(character_id: String) -> float:
	if character_id == "mom":
		return 1.0
	if not Requests.is_desire(character_id):
		return Requests.WEEKEND_WANTS_BONUS if (day - 1) % WEEKDAYS.size() >= 5 else 1.0
	var mult := 1.0 + Requests.DESIRE_PER_ATTRACTIVENESS * (attractiveness_tier() - 1)
	mult *= 1.0 + Requests.DESIRE_PER_RANK * (links.get(character_id, {}).get("rank", 1) - 1)
	if appearance.get("outfit", "") == "date":
		mult *= Requests.DATE_OUTFIT_BONUS
	if meters.get("mom", 0.0) >= Requests.MOM_SIGNAL["min"]:
		mult *= Requests.MOM_SIGNAL["bonus"]
	return mult


## Varje ny tidszon: mÃ¤tarna vÃ¤xer, och under de spelbara kan en fÃ¶rfrÃ¥gan komma.
func _tick_requests() -> void:
	for character_id in meters:
		if not is_introduced(character_id):
			continue
		meters[character_id] = minf(meters[character_id] + Requests.growth(character_id, meters[character_id], _meter_multiplier(character_id)), 100.0)
	if get_time_of_day() in PLAYABLE_PERIODS:
		for character_id in Requests.requesters():
			_maybe_request(character_id)
	requests_changed.emit()


func _maybe_request(character_id: String) -> void:
	var info := Requests.meter_info(character_id)
	if requests.has(character_id) or not is_introduced(character_id) or is_busy(character_id) or get_character_room(character_id) == "":
		return
	if day - last_request.get(character_id, -99) <= info.get("cooldown", 0):
		return
	var period_name := get_time_of_day()
	if Requests.roll(character_id, day, period_name, "trigger") >= Requests.trigger_chance(character_id, meters[character_id]):
		return
	var t := Requests.pick_type(character_id, links.get(character_id, {}).get("rank", 1), Requests.roll(character_id, day, period_name, "type"))
	if t.is_empty():
		return
	requests[character_id] = {"type": t["id"], "day": day}
	if get_character_room(character_id) == current_room:
		message_posted.emit("%s: \"%s\"" % [character_name(character_id), t["ask"]])
	else:
		receive_message(character_id, t["ask"])


## FÃ¶rfrÃ¥gningsdelen av en handling: gjord, nej tack eller en delegerad syssla.
## Returnerar texterna fÃ¶r Ã¥terkopplingen.
func _apply_request_action(action: Dictionary) -> Array[String]:
	var changes: Array[String] = []
	var who: String = action.get("fulfills", "")
	if who != "" and requests.has(who):
		var t := Requests.find_type(requests[who]["type"])
		var owes: int = t.get("owes", 0)
		if owes > 0:
			owed[who] = mini(owed.get(who, 0) + owes, Requests.MAX_OWED)
			changes.append("%s owes you %d chore%s" % [character_name(who), owed[who], "" if owed[who] == 1 else "s"])
		_close_request(who, Requests.meter_info(who).get("after", 0))
	who = action.get("declines", "")
	if who != "" and requests.has(who):
		changes.append(add_link_points(who, Requests.LINK_PENALTY["declined"]))
		_close_request(who, lerpf(meters[who], Requests.meter_info(who).get("after", 0), Requests.DECLINE_RELIEF))
	who = action.get("delegates", "")
	if who != "" and owed.get(who, 0) > 0:
		owed[who] -= 1
		changes.append("free time Â· %s owes %d" % [character_name(who), owed[who]])
		requests_changed.emit()
	return changes


func _close_request(character_id: String, meter_value: float) -> void:
	requests.erase(character_id)
	meters[character_id] = meter_value
	last_request[character_id] = day
	requests_changed.emit()


## En ny dag: fÃ¶rfrÃ¥gningar som har vÃ¤ntat fÃ¶r lÃ¤nge fÃ¶rsvinner.
func _expire_requests() -> void:
	for character_id in requests.keys():
		var t := Requests.find_type(requests[character_id]["type"])
		if day - requests[character_id]["day"] <= t.get("expires", Requests.EXPIRES):
			continue
		add_link_points(character_id, Requests.LINK_PENALTY["expired"])
		message_posted.emit("%s stopped waiting for an answer." % character_name(character_id))
		_close_request(character_id, lerpf(meters[character_id], Requests.meter_info(character_id).get("after", 0), Requests.DECLINE_RELIEF))


# --- Platser och resor ------------------------------------------------------------

func set_flag(flag: String, value := true) -> void:
	if flags.get(flag, false) == value:
		return
	flags[flag] = value
	locations_changed.emit()
	var income_id := Economy.income_for_flag(flag)
	if value and income_id != "":
		message_posted.emit("New way to earn money: %s." % Economy.SIDE_INCOME[income_id]["name"])
	if value:
		for character_id in CHARACTERS:
			if CHARACTERS[character_id].get("introduced_by", "") == flag:
				_introduce(character_id)
	refresh_schedules()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


## Platsen mamman Ã¤r pÃ¥, eller tom strÃ¤ng om hon Ã¤r hemma.
func current_location() -> String:
	return Locations.location_of_room(current_room)


## VarfÃ¶r en plats Ã¤r stÃ¤ngd just nu, eller tom strÃ¤ng om man kan Ã¥ka dit.
func location_block_reason(location_id: String) -> String:
	var location: Dictionary = Locations.LOCATIONS[location_id]
	var flag: String = location.get("flag", "")
	if flag != "" and not has_flag(flag):
		return location.get("flag_hint", "Not available yet")
	if day < location.get("min_day", 1):
		return "Opens on day %d" % location["min_day"]
	var quest: String = location.get("quest", "")
	if quest != "" and not quests.has(quest):
		return "Not available yet"
	var quest_done: String = location.get("quest_done", "")
	if quest_done != "" and quests.get(quest_done, "") != "completed":
		return "Not available yet"
	var weekdays: Array = location.get("weekdays", [])
	if not weekdays.is_empty() and not ((day - 1) % WEEKDAYS.size()) in weekdays:
		return "Closed on %ss" % get_weekday()
	var periods: Array = location.get("periods", [])
	if not periods.is_empty() and not get_time_of_day() in periods:
		var open := " and ".join(Array(periods).map(func(p: String) -> String: return PERIOD_NAMES[p].to_lower()))
		return "Only open in the %s" % open
	return ""


## Reser till en plats i grannskapet. Att resa tar ingen tid, som att gÃ¥ mellan rum.
func travel_to_location(location_id: String) -> bool:
	if not is_playable() or location_block_reason(location_id) != "":
		return false
	var location: Dictionary = Locations.LOCATIONS[location_id]
	message_posted.emit(location.get("arrive", "You head to the %s." % location["name"]))
	go_to_room(location["room"])
	return true


## Ã…ker hem igen (till hallen, innanfÃ¶r ytterdÃ¶rren).
func return_home(text := "You head back home.") -> void:
	if current_location() == "":
		return
	message_posted.emit(text)
	go_to_room(Locations.HOME["room"])


## Om platsen mamman Ã¤r pÃ¥ har stÃ¤ngt (t.ex. skolan pÃ¥ kvÃ¤llen) Ã¥ker hon hem.
func _leave_closed_location() -> void:
	var location_id := current_location()
	if location_id == "" or not is_playable() or location_block_reason(location_id) == "":
		return
	return_home(Locations.LOCATIONS[location_id].get("closed_text", "It's closing time. You head home."))


func set_appearance(category: String, option_id: String) -> void:
	if appearance.get(category, "") == option_id or not AppearanceData.OPTIONS[category].has(option_id):
		return
	if not owns_look(category, option_id):
		return
	appearance[category] = option_id
	appearance_changed.emit()


# --- Telefonen ----------------------------------------------------------------

## LÃ¤gger till en kontakt man har hittat.
func add_contact(contact_id: String) -> void:
	if contact_id in known_contacts or not PhoneData.CONTACTS.has(contact_id):
		return
	known_contacts.append(contact_id)
	phone_changed.emit()


## Mamman skickar ett sms.
func send_message(contact_id: String, text: String) -> void:
	messages.get_or_add(contact_id, []).append(["me", text])
	phone_changed.emit()


## Ett sms kommer in (markeras som olÃ¤st).
func receive_message(contact_id: String, text: String) -> void:
	add_contact(contact_id)
	messages.get_or_add(contact_id, []).append(["them", text])
	if not contact_id in unread:
		unread.append(contact_id)
	phone_changed.emit()


func mark_read(contact_id: String) -> void:
	if contact_id in unread:
		unread.erase(contact_id)
		phone_changed.emit()


## LÃ¤gger till ett minne. source skriver Ã¶ver PhoneData:s text om varifrÃ¥n det kom,
## t.ex. "Sent by Best Friend". Scenminnen lÃ¤ggs till av sig sjÃ¤lva nÃ¤r scenen Ã¤r slut.
func add_memory(memory_id: String, source := "") -> void:
	if memories.has(memory_id) or not PhoneData.MEMORIES.has(memory_id):
		return
	_record_memory(memory_id, source)
	message_posted.emit("New memory: %s" % PhoneData.MEMORIES[memory_id]["title"])
	phone_changed.emit()


func _record_memory(memory_id: String, source: String) -> void:
	var memory: Dictionary = PhoneData.MEMORIES[memory_id]
	var record := {"day": day, "period": get_time_of_day(), "room": current_room, "source": source, "seen": false}
	if memory["type"] == "scene":
		var scene_flags: Dictionary = _scene_flags if playing_scene == memory["scene"] else flags
		record["replay"] = {"scene": memory["scene"], "flags": scene_flags.duplicate()}
	memories[memory_id] = record


func mark_memory_seen(memory_id: String) -> void:
	if memories.has(memory_id) and not memories[memory_id]["seen"]:
		memories[memory_id]["seen"] = true
		phone_changed.emit()


## Byter telefonens bakgrund pÃ¥ en plats (se PhoneData.WALLPAPER_SLOTS).
func set_wallpaper(slot: String, value: String) -> void:
	if PhoneData.WALLPAPER_SLOTS.has(slot) and phone_wallpapers.get(slot) != value:
		phone_wallpapers[slot] = value
		phone_changed.emit()


func unseen_memory_count() -> int:
	return memories.values().filter(func(record: Dictionary) -> bool: return not record["seen"]).size()


## Spelar ett scenminne igen. Inget i spelet Ã¤ndras av att se det.
func replay_memory(memory_id: String) -> void:
	if replaying_memory != "" or playing_scene != "" or not memories.get(memory_id, {}).has("replay"):
		return
	replaying_memory = memory_id
	memory_replay_requested.emit(memory_id)


func finish_replay() -> void:
	var memory_id := replaying_memory
	replaying_memory = ""
	memory_replay_finished.emit(memory_id)


func start_quest(quest_id: String) -> void:
	if quests.has(quest_id) or not PhoneData.QUESTS.has(quest_id):
		return
	quests[quest_id] = "active"
	message_posted.emit("Quest started: %s" % PhoneData.QUESTS[quest_id]["title"])
	phone_changed.emit()
	refresh_schedules()


func complete_quest(quest_id: String) -> void:
	if quests.get(quest_id, "") != "active":
		return
	quests[quest_id] = "completed"
	message_posted.emit("Quest completed: %s" % PhoneData.QUESTS[quest_id]["title"])
	phone_changed.emit()
	refresh_schedules()


func is_day_over() -> bool:
	return period >= TIME_PERIODS.size()


## Om spelaren har kontroll: eftermiddag eller kvÃ¤ll, och ingen scen spelas.
func is_playable() -> bool:
	return not is_day_over() and playing_scene == "" and replaying_memory == "" and get_time_of_day() in PLAYABLE_PERIODS


## UtfÃ¶r en handling: Ã¤ndrar mÃ¤tarna och meddelar HUD:en. Aktiviteter som tar tid
## (advances) flyttar dygnet till nÃ¤sta tidszon.
func perform_action(action_text: String, effects: Dictionary, advances: Variant = true) -> void:
	if not is_playable():
		return

	var changes: Array[String] = []
	for key in effects:
		var delta: int = effects[key]
		if delta == 0:
			continue
		stats[key] = clampi(stats[key] + delta, 0, STAT_MAX)
		changes.append("%s %+d" % [STAT_NAMES[key], delta])

	action_performed.emit(action_text, ", ".join(changes))
	stats_changed.emit()
	if advances:
		advance_period()


## Flyttar spelaren till ett annat rum (gamla rumsvyn). Att gÃ¥ tar ingen tid.
func go_to_room(room_id: String, _travel_minutes: int = 0) -> void:
	if is_day_over():
		return
	if not ROOMS.has(room_id):
		push_error("OkÃ¤nt rum: %s" % room_id)
		return
	current_room = room_id
	room_changed.emit(room_id)


## GÃ¥r till ett rum via kartan. Restiden Ã¤r den kortaste vÃ¤gen genom husets dÃ¶rrar.
func travel_to(room_id: String) -> void:
	set_map_open(false)
	if room_id == current_room:
		return
	var travel := get_travel_minutes(current_room, room_id)
	if travel < 0:
		push_error("Ingen vÃ¤g frÃ¥n %s till %s" % [current_room, room_id])
		return
	go_to_room(room_id, travel)


## Rummets dÃ¶rrar: {mÃ¥lrum: restid}.
func get_exits(room_id: String) -> Dictionary:
	return _exits.get(room_id, {})


## Kortaste restiden mellan tvÃ¥ rum lÃ¤ngs dÃ¶rrarna, eller -1 om det inte finns nÃ¥gon vÃ¤g.
func get_travel_minutes(from_room: String, to_room: String) -> int:
	var best := {from_room: 0}
	var unvisited := [from_room]
	while not unvisited.is_empty():
		var current: String = unvisited[0]
		for candidate in unvisited:
			if best[candidate] < best[current]:
				current = candidate
		unvisited.erase(current)
		if current == to_room:
			return best[current]
		for target in _exits.get(current, {}):
			var cost: int = best[current] + _exits[current][target]
			if not best.has(target) or cost < best[target]:
				if not best.has(target):
					unvisited.append(target)
				best[target] = cost
	return -1


## SÃ¤tter vilket rum spelaren stÃ¥r i utan att nÃ¥gon restid rÃ¤knas (spelaren gÃ¥r sjÃ¤lv).
func set_current_room(room_id: String) -> void:
	if room_id == current_room or not ROOMS.has(room_id):
		return
	current_room = room_id
	room_changed.emit(room_id)


func set_map_open(is_open: bool) -> void:
	if map_open == is_open:
		return
	map_open = is_open
	map_toggled.emit(is_open)


# --- Scheman: var alla Ã¤r ------------------------------------------------------

## RÃ¤knar om var alla Ã¤r fÃ¶r dagens tidszon och meddelar vÃ¤rlden om nÃ¥got har Ã¤ndrats.
## Anropas nÃ¤r tidszonen byts och nÃ¤r storyn Ã¤ndras (hÃ¤ndelser, quests, rank,
## storyÃ¶verstyrningar), sÃ¥ att svaren alltid stÃ¤mmer mitt i en tidszon.
func refresh_schedules() -> void:
	var changed := false
	for character_id in CHARACTERS:
		if character_id == "mom":
			continue
		var slot := Schedules.resolve(character_id, day, get_time_of_day())
		var old: Dictionary = whereabouts.get(character_id, {})
		whereabouts[character_id] = slot
		if old.get("room", "") != slot["room"]:
			character_moved.emit(character_id, old.get("room", ""), slot["room"])
		if old.get("room", "") != slot["room"] or old.get("activity", "") != slot["activity"] or old.get("stranger", false) != slot["stranger"]:
			changed = true
	if changed:
		schedules_changed.emit()


## Var en person Ã¤r och vad den gÃ¶r just nu: {"room", "activity", "source", "stranger"}
## (se Schedules.resolve). room Ã¤r "" om personen Ã¤r borta.
func where_is(character_id: String) -> Dictionary:
	if character_id == "mom":
		return {"room": current_room, "activity": "", "source": "", "stranger": false}
	return whereabouts.get(character_id, {"room": "", "activity": "", "source": "", "stranger": false})


## Svaret pÃ¥ "var Ã¤r X?" fÃ¶r spelaren, t.ex. "Kitchen Â· Having breakfast" eller
## "At football practice". Personer man inte har trÃ¤ffat Ã¤r okÃ¤nda.
func where_text(character_id: String) -> String:
	if not is_introduced(character_id):
		return "Unknown"
	return Schedules.describe(where_is(character_id))


## Rummet dÃ¤r en person Ã¤r just nu, eller tom strÃ¤ng om personen Ã¤r borta.
func get_character_room(character_id: String) -> String:
	return where_is(character_id)["room"]


func get_characters_in(room_id: String) -> Array[String]:
	var present: Array[String] = []
	for character_id in CHARACTERS:
		if get_character_room(character_id) == room_id:
			present.append(character_id)
	return present


## Om personen gÃ¶r nÃ¥got som inte gÃ¥r att avbryta (t.ex. sover).
func is_busy(character_id: String) -> bool:
	return Schedules.is_busy(where_is(character_id))


## Om en framtida NPC har fÃ¶rts in i vÃ¤rlden. Familjen Ã¤r alltid introducerad.
func is_introduced(character_id: String) -> bool:
	var flag: String = CHARACTERS[character_id].get("introduced_by", "")
	return flag == "" or has_flag(flag)


## Namnet spelaren ser: stranger_name tills en framtida NPC Ã¤r introducerad.
func character_name(character_id: String) -> String:
	var info: Dictionary = CHARACTERS[character_id]
	return info["name"] if is_introduced(character_id) else info.get("stranger_name", "???")


func character_initials(character_id: String) -> String:
	return CHARACTERS[character_id]["initials"] if is_introduced(character_id) else "?"


## Storyn Ã¤ndrar en persons schema, t.ex. en tjÃ¤nsteresa eller att nÃ¥gon flyttar in hos
## grannen. GÃ¥r fÃ¶re regler och rutiner. to_day -1 betyder tills vidare; periods []
## betyder hela dygnet. Samma id ersÃ¤tter en tidigare Ã¶verstyrning.
func set_schedule_override(override_id: String, character_id: String, room: String, activity: String,
		from_day: int, to_day := -1, periods: Array = []) -> void:
	schedule_overrides[override_id] = {"character": character_id, "room": room, "activity": activity,
			"from_day": from_day, "to_day": to_day, "periods": periods}
	refresh_schedules()


func clear_schedule_override(override_id: String) -> void:
	if schedule_overrides.erase(override_id):
		refresh_schedules()


## En framtida NPC kliver in i vÃ¤rlden: fÃ¥r en social link och hamnar i telefonen.
func _introduce(character_id: String) -> void:
	if not links.has(character_id):
		links[character_id] = {"rank": 1, "points": 0, "lust": 0.0}
		link_changed.emit(character_id)
	add_contact(character_id)
	character_introduced.emit(character_id)


## FrÃ¥gar Dispatcher om personen har en rankscen klar just nu och startar den i sÃ¥ fall
## genom Dialogue Manager. Annars platshÃ¥llartexten. Returnerar true om en scen startade.
func talk_to(character_id: String) -> bool:
	var scene_id := Dispatcher.resolve_slot(period, character_id)
	if scene_id == "":
		message_posted.emit("You talk to %s. (Dialogue comes later.)" % character_name(character_id))
		return false
	var path := Dispatcher.dialogue_path(scene_id)
	if not ResourceLoader.exists(path):
		push_error("Dialogfilen fÃ¶r %s saknas: %s" % [scene_id, path])
		return false
	var manager: Node = Engine.get_singleton("DialogueManager")
	if not manager.dialogue_ended.is_connected(_on_dialogue_ended):
		manager.dialogue_ended.connect(_on_dialogue_ended)
	manager.show_dialogue_balloon_scene(STORY_BALLOON, load(path), Dispatcher.cue(scene_id))
	_rank_scene_started = true
	return true


func _on_dialogue_ended(_resource: Resource) -> void:
	var stage := get_node_or_null(STAGE_NAME) as StoryStage
	if stage:
		stage.clear()
	if _rank_scene_started:
		_rank_scene_started = false
		advance_period()


## Dialogrutorna som Ã¤r Ã¶ppna just nu (nodens instans-id). BÃ¥de husets dialogruta och
## storyns balloon anmÃ¤ler sig hÃ¤r, sÃ¥ att telefonen vet nÃ¤r den ska hÃ¥lla sig undan.
var _open_dialogues := {}


func set_dialogue_open(source: Object, is_open: bool) -> void:
	var was_active := in_dialogue()
	if is_open:
		_open_dialogues[source.get_instance_id()] = true
	else:
		_open_dialogues.erase(source.get_instance_id())
	if in_dialogue() != was_active:
		dialogue_changed.emit(in_dialogue())


func in_dialogue() -> bool:
	return not _open_dialogues.is_empty()


func start_next_day() -> void:
	# KvÃ¤llens Work rÃ¤knas till lÃ¶nebonusen innan natten tÃ¤r pÃ¥ mÃ¤tarna.
	work_log["sum"] += stats["work"]
	work_log["days"] += 1
	day += 1
	used_today.clear()
	for key in stats:
		stats[key] = clampi(stats[key] - maxi(NIGHTLY_DECAY - decay_reduction(key), 0), 0, STAT_MAX)
	_expire_requests()
	var notes := _money_new_day()
	notes.push_front("A new day begins. Things slipped a little overnight.")
	message_posted.emit(" ".join(notes))
	_decay_social()
	current_room = START_ROOM
	room_changed.emit(current_room)
	begin_day()


## Startar dagen pÃ¥ morgonen: spelar dagens morgonscen om det finns en, annars gÃ¥r
## dygnet direkt till eftermiddagen. Anropas nÃ¤r spelet startar och varje ny dag.
func begin_day() -> void:
	_set_period(0)
	_play_scene_or_continue()


## Den pÃ¥gÃ¥ende scenen Ã¤r slut; dygnet fortsÃ¤tter.
func finish_scene() -> void:
	add_memory(PhoneData.memory_for_scene(playing_scene))
	playing_scene = ""
	scene_finished.emit()
	_continue_after_scene()


func _play_scene_or_continue() -> void:
	var scene_id := StoryScenes.find(day, get_time_of_day())
	if scene_id != "":
		playing_scene = scene_id
		_scene_flags = flags.duplicate()
		scene_requested.emit(scene_id)
	else:
		_continue_after_scene()


## Efter morgonen kommer eftermiddagen; efter natten Ã¤r dagen slut.
func _continue_after_scene() -> void:
	match get_time_of_day():
		"morning":
			_set_period(1)
		"night":
			_end_day()


func _set_period(index: int) -> void:
	period = index
	# FÃ¶re signalerna, sÃ¥ att den som lyssnar ser vem som Ã¤r var i den nya tidszonen.
	refresh_schedules()
	_tick_requests()
	stats_changed.emit()
	time_of_day_changed.emit(get_time_of_day())


func _end_day() -> void:
	period = TIME_PERIODS.size()
	set_map_open(false)
	stats_changed.emit()
	day_ended.emit()


func get_room_scene_path(room_id: String) -> String:
	return "res://scenes/rooms/%s.tscn" % room_id


func get_time_of_day() -> String:
	return TIME_PERIODS[mini(period, TIME_PERIODS.size() - 1)]


## GÃ¥r vidare efter en aktivitet: frÃ¥n eftermiddagen till kvÃ¤llen, och frÃ¥n kvÃ¤llen
## till natten (med nattscen om dagen har en) och sedan dagens slut.
func advance_period() -> void:
	if not is_playable():
		return
	_set_period(period + 1)
	if get_time_of_day() == "night":
		_play_scene_or_continue()
	else:
		_leave_closed_location()


func show_hint(text: String) -> void:
	hint_changed.emit(text)


func get_weekday() -> String:
	return weekday_of(day)


static func weekday_of(for_day: int) -> String:
	return WEEKDAYS[(for_day - 1) % WEEKDAYS.size()]


func get_clock_text() -> String:
	return "%s  %s" % [get_weekday(), PERIOD_NAMES[get_time_of_day()]]


static func format_duration(total_minutes: int) -> String:
	var h := total_minutes / 60
	var m := total_minutes % 60
	if h > 0 and m > 0:
		return "%d h %d min" % [h, m]
	if h > 0:
		return "%d h" % h
	return "%d min" % m


# --- Dialogfunktioner (CONTRACT.md, avsnitt 2) ------------------------------------
# Anropas frÃ¥n dialogfilerna.

## Dialogrutan rankscenerna spelas i.
const STORY_BALLOON := "res://scenes/balloon/balloon.tscn"
## Namnet pÃ¥ StoryStage-noden (figurer och rank-kort) under GameState.
const STAGE_NAME := "StoryStage"


## Slutet pÃ¥ en rankscen: lÃ¤gger pÃ¥ Balance.EFFECTS[scene_id], sÃ¤tter scenens flaggor
## och markerar scenen som spelad. En _bonus-scen utan egen rad fÃ¥r grundscenens effekter.
func apply(scene_id: String, tone := 0) -> void:
	var base := Dispatcher.base_id(scene_id)
	if not Balance.GATES.has(base):
		push_error("apply(): %s saknas i Balance.GATES" % scene_id)
		return
	var effects: Dictionary = Balance.EFFECTS.get(scene_id, Balance.EFFECTS.get(base, {}))
	var char_id: String = Balance.GATES[base]["char"]
	var notes: Array[String] = []
	if effects.has("link_points"):
		notes.append(add_link_points(char_id, effects["link_points"]))
	if effects.has("lust"):
		var mult := 2.0 if tone >= 1 else 1.0
		links[char_id]["lust"] = clampf(links[char_id]["lust"] + effects["lust"] * mult, 0.0, Balance.LUST_MAX)
		link_changed.emit(char_id)
	for key in effects.get("stats", {}):
		var delta: int = effects["stats"][key]
		stats[key] = clampi(stats[key] + delta, 0, STAT_MAX)
		notes.append("%s %+d" % [STAT_NAMES[key], delta])
	_relieve_mom(effects.get("relief", 0))
	for flag in effects.get("flags", []):
		set_flag(flag)
	set_flag(Dispatcher.DONE_FLAG + base)
	stats_changed.emit()
	if not notes.is_empty():
		message_posted.emit(" Â· ".join(notes))


## Platskort nÃ¤r en scen byter plats.
func location(text: String) -> void:
	_stage().show_location(text)


## Rank-upp-kort. Kommer sist i scenen.
func rank_card(char_id: String, rank: int) -> void:
	if not CHARACTERS.has(char_id):
		push_error("rank_card(): okÃ¤nd person %s" % char_id)
		return
	_stage().show_rank_card(char_id, rank)


## Visar en figur eller byter dess pose. Saknas bilden blir det en platshÃ¥llare.
func sprite(char_id: String, pose: String) -> void:
	if not CHARACTERS.has(char_id):
		push_error("sprite(): okÃ¤nd person %s" % char_id)
		return
	_stage().show_sprite(char_id, pose)


## StoryStage skapas fÃ¶rsta gÃ¥ngen den behÃ¶vs.
func _stage() -> StoryStage:
	var stage := get_node_or_null(STAGE_NAME) as StoryStage
	if stage == null:
		stage = StoryStage.new()
		stage.name = STAGE_NAME
		add_child(stage)
	return stage


## Byter ansiktsuttryck pÃ¥ en figur. StÃ¥r figuren inte pÃ¥ scenen Ã¤n sparas uttrycket
## tills sprite() stÃ¤ller fram den.
func mood(char_id: String, mood_id: String) -> void:
	if not CHARACTERS.has(char_id):
		push_error("mood(): okÃ¤nd person %s" % char_id)
		return
	_stage().show_mood(char_id, mood_id)


