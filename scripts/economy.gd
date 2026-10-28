class_name Economy
## Mammans ekonomi: en stor lön i månaden, sidoinkomster som spelaren själv måste hitta,
## och utgifter som håller pengarna knappa. Det här är bara data och uträkningar;
## saldot, kvittona och vad hon äger finns i GameState. All text spelaren ser är på engelska.
##
## Balansen, per månad (28 dagar = 4 veckor):
##   Lön                    3 200  (+100–250 i bonus om Work har hållits uppe)
##   Fasta räkningar       −2 080  (dag 1 i månaden)
##   Veckohandling           −600  (4 × 150, "Do the weekly shopping")
##   Fickpengar              −160  (4 × 40, söndagar)
##   Oväntad räkning         ~−200  (ungefär två månader av tre)
##   ------------------------------
##   Kvar                  ~150–400  – räcker till en dejt och ett gympass, inte mer.
## Allt större (kläder, presenter, hemmet, semestern) kräver sidoinkomster, och de tar
## tid från hem, jobb och romantik. Det är spelets ekonomiska avvägning: tid mot pengar.

const CURRENCY := "$"
const START_MONEY := 900

## En månad är fyra veckor, så att månadens dagar alltid är samma veckodagar.
const MONTH_DAYS := 28
## Lönen kommer den 25:e (en torsdag), räkningarna den 1:a. Spelaren får tre dagar med
## pengar på kontot innan räkningarna drar – svenskt löneupplägg.
const PAYDAY := 25
const BILL_DAY := 1

# --- Lönen ----------------------------------------------------------------------

const SALARY := {"amount": 3200, "employer": "Maple Grove Middle School"}
## Bonus efter hur väl Work har skötts sedan förra lönen (snittet av Work varje kväll).
## Den första raden som uppfylls gäller.
const MERIT_BONUS := [
	{"min_work": 75, "amount": 250, "text": "Merit bonus – the principal noticed your hard work"},
	{"min_work": 55, "amount": 100, "text": "Small performance bonus"},
]
## Löneökningar som storyn låser upp med en händelse (GameState.flags). Varje gäller
## från nästa lön och ligger kvar.
const RAISES := {
	"lead_teacher": {"amount": 300, "text": "Lead teacher raise"},
	"department_head": {"amount": 500, "text": "Department head raise"},
}

# --- Utgifter ---------------------------------------------------------------------

## Fasta räkningar som dras den 1:a varje månad (inte dag 1 i spelet).
const MONTHLY_BILLS := {
	"mortgage": {"name": "Mortgage", "amount": 1350},
	"utilities": {"name": "Electricity & water", "amount": 240},
	"car": {"name": "Car payment", "amount": 220},
	"insurance": {"name": "Insurance", "amount": 160},
	"phone": {"name": "Phones & internet", "amount": 110},
}
## Räkningar varje vecka. weekday: index i GameState.WEEKDAYS (6 = söndag).
const WEEKLY_BILLS := {
	"allowance": {"name": "The boys' allowance", "amount": 40, "weekday": 6},
}
## Abonnemang spelaren själv väljer att teckna. Första månaden betalas direkt, sedan
## dras de med räkningarna. waives: vad abonnemanget gör gratis ("waived_by" i handlingar).
const SUBSCRIPTIONS := {
	"gym_pass": {"name": "Gym membership", "amount": 45, "waives": "gym_visit"},
}
## Den som inte handlar på en vecka får beställa hämtmat i stället: dyrare och Home sjunker.
const GROCERY_GRACE_DAYS := 8
const TAKEOUT := {"amount": 60, "effects": {"home": -5}, "text": "The fridge is empty, so you order takeout again. Expensive, and nobody's happy about it."}

## Saldot får gå minus till räkningar, men inte till köp. Står kontot på minus när en
## räkning dras kommer en avgift, och varje natt på minus ger oro i mätarna.
const LATE_FEE := 35
const DEBT_STRESS := {"home": -3}
const DEBT_TEXT := "Your account is in the red. Money worries keep you up at night."

## Oväntade räkningar, som mest en i månaden (aldrig den första). Vilken och vilken dag
## räknas fram ur månadens nummer, så att det blir samma efter att man har laddat ett spel.
## weight: hur ofta jämfört med de andra; "none" är en månad utan överraskning.
const SURPRISE_BILLS := {
	"none": {"weight": 4},
	"car_repair": {"weight": 2, "name": "Car repair", "amount": 380, "text": "The car starts making a horrible grinding noise. The mechanic's bill: $380."},
	"dentist": {"weight": 2, "name": "Dentist", "amount": 220, "text": "Son 1 has a cavity. Too many energy drinks."},
	"school_trip": {"weight": 2, "name": "School trip", "amount": 95, "text": "Son 2 hands you a crumpled permission slip. The class trip is next week, and it isn't free."},
	"vet": {"weight": 1, "name": "Vet", "amount": 160, "text": "The dog ate a sock. The vet gets it out. The vet also gets paid."},
	"washer": {"weight": 1, "name": "Washer repair", "amount": 290, "text": "The washing machine floods the laundry room."},
}

# --- Sidoinkomster ------------------------------------------------------------------

## Sätten att tjäna extra. De är dolda tills spelaren har hittat dem i världen (flag);
## då kommer ett meddelande. hint är en vag ledtråd för telefonen ("4 more ways to earn …")
## som aldrig säger var. Handlingarna som ger pengarna finns i RoomActions ("earn",
## "income") och i SELLABLES nedan. Fler sätt (tjänster via sms, storyn) läggs till här
## och betalas med GameState.earn().
const SIDE_INCOME := {
	"tutoring": {"name": "Private Tutoring", "flag": "found_tutoring",
		"hint": "Parents at school are always looking for help."},
	"house_sitting": {"name": "House-Sitting", "flag": "found_house_sitting",
		"hint": "Neighbors sometimes need a hand."},
	"coaching": {"name": "Fill-in Coach", "flag": "found_coaching",
		"hint": "Strong people get asked to step in."},
	"modeling": {"name": "Shop Window Model", "flag": "found_modeling",
		"hint": "Some shops pay for a pretty face."},
	"marketplace": {"name": "Selling Old Things", "flag": "found_marketplace",
		"hint": "The house is full of things nobody uses."},
	"art_market": {"name": "Weekend Art Market", "flag": "found_art_market",
		"hint": "Your paintings might be worth something."},
}

## Saker i huset som kan säljas, en gång var. Visas som val i rummet när marknaden är
## hittad (reveal_flag). link_points < 0: någon blir sur över att saken såldes.
const SELLABLES := {
	"old_tent": {"room": "storage", "object": "boxes", "label": "Sell the old tent online", "price": 60,
		"text": "A college student picks up the tent within the hour."},
	"baby_clothes": {"room": "attic", "object": "boxes", "label": "Sell the baby clothes", "price": 45,
		"text": "A young couple buys the whole box. You keep one tiny sweater."},
	"old_console": {"room": "storage", "object": "boxes", "label": "Sell Son 1's old console", "price": 110,
		"text": "It sells fast. Son 1 finds out even faster.", "link": "son_1", "link_points": -3},
	"exercise_bike": {"room": "hobby_room", "object": "", "label": "Sell the exercise bike", "price": 140,
		"text": "Your husband's New Year's resolution finds a new home.", "link": "husband", "link_points": -1},
}

## Saker hon kan ha flera av (GameState.inventory). Målningar kommer från staffliet och
## säljs på helgmarknaden i parken.
const ITEMS := {
	"painting": {"name": "Painting", "max": 3,
		"desc": "Your own work from the easel. Sells at the weekend art market in the park."},
}

# --- Köp --------------------------------------------------------------------------

## Sånt man köper en gång och har kvar. Säljs i rummet "room" (genereras som val där).
##   name   – vad saken heter i pausmenyns Items
##   decay  – minskar hur mycket en mätare sjunker varje natt
##   effects/relief/link/link_points/sets_flag – som i RoomActions, sker när man köper
const PURCHASES := {
	# Hemmet – beställs på datorn i hemmakontoret.
	"dishwasher": {"name": "Dishwasher", "room": "home_office", "object": "desk", "label": "Order a new dishwasher", "price": 650,
		"text": "The old one finally gets replaced. Fewer dishes, fewer arguments.", "decay": {"home": 2}},
	"robot_vacuum": {"name": "Robot Vacuum", "room": "home_office", "object": "desk", "label": "Order a robot vacuum", "price": 350,
		"text": "The dog declares war on it immediately.", "decay": {"home": 1}},
	"new_mattress": {"name": "New Mattress", "room": "home_office", "object": "desk", "label": "Order a new mattress", "price": 900,
		"text": "Your back thanks you. So does your husband.", "relief": 10},
	"family_trip": {"name": "Beach Weekend", "room": "home_office", "object": "desk", "label": "Book a family beach weekend", "price": 2400,
		"text": "You book the trip. The boys pretend not to be excited.", "effects": {"home": 15}, "relief": 15,
		"sets_flag": "family_trip_booked"},
	# Presenter.
	"gift_cleats": {"name": "Football Cleats", "room": "home_office", "object": "desk", "label": "Buy Son 2 new football cleats", "price": 120,
		"text": "He wears them around the house all evening.", "link": "son_2", "link_points": 4},
	"gift_game": {"name": "Video Game", "room": "home_office", "object": "desk", "label": "Buy Son 1 the game he wants", "price": 70,
		"text": "He actually hugs you. Then disappears for three days.", "link": "son_1", "link_points": 4},
	"gift_watch": {"name": "Wristwatch", "room": "boutique", "object": "display_case", "label": "Buy your husband a watch", "price": 250,
		"text": "You wrap it and hide it in the closet for the right moment.", "link": "husband", "link_points": 4, "relief": 10},
	"gift_artbook": {"room": "bookstore", "object": "display_table", "label": "Buy Son 1 the art book for his game", "price": 45,
		"text": "Concept art, maps and lore. He'll pretend it's no big deal and read it cover to cover.", "link": "son_1", "link_points": 3},
}
## Utseenden som måste köpas innan de går att välja i garderoben och vid sminkbordet.
## Nyckel: "kategori:val" i AppearanceData.OPTIONS. Allt annat har hon redan. "object"
## är saken i rummet som köpet hör till (annars klädställningen eller butikshyllan).
## Frisyr och hårfärg köps inte här, de görs i frisörsalongen (SALON).
const LOOKS := {
	"outfit:date": {"room": "boutique", "price": 180},
	"makeup:glam": {"room": "boutique", "price": 45},
	"accessory:necklace": {"room": "boutique", "price": 120, "object": "display_case"},
}

# --- Frisörsalongen -----------------------------------------------------------------

## Vad salongen tar för att ändra en sak i håret (AppearanceData-kategorierna med
## station "salon"). Byter hon både frisyr och färg betalar hon båda. "premium" är val
## som kostar mer (blekning till blont). Ett besök tar tid och ger lite Charm.
const SALON := {
	"hairstyle": {"service": "Cut & style", "price": 45},
	"hair_color": {"service": "Color", "price": 70, "premium": {"blonde": 95}},
}
const SALON_CHARM := 2


## Vad salongen tar för att ändra en kategori till ett visst val.
static func salon_price(category: String, option_id: String) -> int:
	var service: Dictionary = SALON[category]
	return service.get("premium", {}).get(option_id, service["price"])


## Det billigaste salongen gör (för "from $45" i rummets meny).
static func salon_min_price() -> int:
	var lowest := -1
	for category in SALON:
		lowest = SALON[category]["price"] if lowest < 0 else mini(lowest, SALON[category]["price"])
	return lowest


## Ett belopp som spelaren ser det, t.ex. "$1,240" eller "−$85".
static func format(amount: int) -> String:
	var digits := str(absi(amount))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return "%s%s%s" % ["−" if amount < 0 else "", CURRENCY, digits + grouped]


## Vilken månad en dag hör till (1, 2, …) och vilken dag i månaden den är (1–28).
static func month_of(day: int) -> int:
	return (day - 1) / MONTH_DAYS + 1


static func day_of_month(day: int) -> int:
	return (day - 1) % MONTH_DAYS + 1


static func monthly_bills_total() -> int:
	var total := 0
	for bill in MONTHLY_BILLS.values():
		total += bill["amount"]
	return total


## Grundlönen plus de löneökningar storyn har låst upp.
static func salary(flags: Dictionary) -> int:
	var total: int = SALARY["amount"]
	for flag in RAISES:
		if flags.get(flag, false):
			total += RAISES[flag]["amount"]
	return total


## Bonusen för ett snitt av Work, {"amount", "text"}, eller {} om det inte blir någon.
static func merit_bonus(average_work: float) -> Dictionary:
	for tier in MERIT_BONUS:
		if average_work >= tier["min_work"]:
			return tier
	return {}


## Månadens oväntade räkning: {"id", "day"} eller {} om månaden är lugn. Samma svar
## varje gång för samma månad.
static func surprise_for_month(month: int) -> Dictionary:
	if month <= 1:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = month * 7919 + 13
	var total := 0
	for entry in SURPRISE_BILLS.values():
		total += entry["weight"]
	var roll := rng.randi_range(1, total)
	for id in SURPRISE_BILLS:
		roll -= SURPRISE_BILLS[id]["weight"]
		if roll <= 0:
			return {} if id == "none" else {"id": id, "day": rng.randi_range(3, PAYDAY - 2)}
	return {}


## Sidoinkomsten som en händelse låser upp, eller tom sträng.
static func income_for_flag(flag: String) -> String:
	for income_id in SIDE_INCOME:
		if SIDE_INCOME[income_id]["flag"] == flag:
			return income_id
	return ""


## Ett pris med uträkning efter nivå: base + per_level × (nivå − 1) för varje egenskap
## i scale, t.ex. {"knowledge": 10}. levels: egenskap -> nivå.
static func scaled(base: int, scale: Dictionary, levels: Dictionary) -> int:
	var total := base
	for stat in scale:
		total += scale[stat] * (levels.get(stat, 1) - 1)
	return total


## Val som genereras för ett rum: köp, utseenden, abonnemang och saker att sälja. De har
## samma form som handlingarna i RoomActions.
static func actions_for_room(room_id: String) -> Array:
	var result := []
	for id in PURCHASES:
		var item: Dictionary = PURCHASES[id]
		if item["room"] != room_id:
			continue
		var action := item.duplicate()
		action.erase("room")
		action.erase("price")
		action.erase("decay")
		action.merge({"id": "buy_" + id, "cost": item["price"], "buys": id, "label": "%s (%s)" % [item["label"], format(item["price"])],
			"ledger_label": item["label"]}, true)
		result.append(action)
	for key in LOOKS:
		if LOOKS[key]["room"] != room_id:
			continue
		var parts: PackedStringArray = key.split(":")
		var look_name := AppearanceData.option_name(parts[0], parts[1])
		var title: String = AppearanceData.CATEGORIES[parts[0]]["title"]
		result.append({"id": "buy_" + key.replace(":", "_"), "object": LOOKS[key].get("object", "clothes_rack" if room_id == "boutique" else "store_shelf"),
			"label": "Buy %s – %s (%s)" % [title.to_lower(), look_name, format(LOOKS[key]["price"])],
			"text": "You buy it. %s is now in your collection." % look_name, "cost": LOOKS[key]["price"], "buys": key,
			"ledger_label": "%s (%s)" % [look_name, title.to_lower()]})
	if room_id == "gym":
		var pass_price: int = SUBSCRIPTIONS["gym_pass"]["amount"]
		result.append({"id": "gym_subscribe", "object": "front_desk", "label": "Get a monthly membership (%s/month)" % format(pass_price),
			"text": "The front desk prints you a member card. No more paying at the door.", "cost": pass_price, "subscribe": "gym_pass",
			"ledger_label": SUBSCRIPTIONS["gym_pass"]["name"]})
		result.append({"id": "gym_unsubscribe", "object": "front_desk", "label": "Cancel your membership",
			"text": "You cancel the membership. The front desk looks disappointed.", "unsubscribe": "gym_pass"})
	for id in SELLABLES:
		var sale: Dictionary = SELLABLES[id]
		if sale["room"] != room_id:
			continue
		var action := sale.duplicate()
		action.erase("room")
		action.erase("price")
		action.merge({"id": "sell_" + id, "earn": sale["price"], "income": "marketplace", "sells": id,
			"reveal_flag": SIDE_INCOME["marketplace"]["flag"]})
		result.append(action)
	return result
