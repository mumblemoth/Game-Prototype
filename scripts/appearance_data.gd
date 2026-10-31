class_name AppearanceData
## Vad mamman kan ha på sig och hur hon kan se ut: kläder (garderoben), smink,
## accessoarer och håret uppsatt eller inte (sminkbordet), och frisyr och hårfärg
## (frisörsalongen i köpcentret, som kostar pengar och tid, se Economy.SALON).
## Valen sparas i GameState.appearance.
## En bild för ett val läggs i res://Assets/characters/<kategori>/<id>.png och visas i
## förhandsvisningen; saknas den visas basbilden. All text spelaren ser är på engelska.

const BASE_IMAGE := "res://Assets/portraits/mom_casual_full.png"

## Kategorier i den ordning de visas, med rubrik och var de ändras ("station").
const CATEGORIES := {
	"outfit": {"title": "Outfit", "station": "wardrobe"},
	"makeup": {"title": "Makeup", "station": "vanity"},
	"accessory": {"title": "Accessories", "station": "vanity"},
	# Hemma kan hon bara sätta upp håret i en knut (till jobbet) eller släppa ut det.
	"hair_up": {"title": "Hair", "station": "vanity"},
	"hairstyle": {"title": "Hairstyle", "station": "salon"},
	"hair_color": {"title": "Hair Color", "station": "salon"},
}

## Alternativ per kategori: id -> {name, desc, och för hårfärg en färgruta (swatch)}.
const OPTIONS := {
	"outfit": {
		"casual": {"name": "Casual", "desc": "Cream blouse, belt and high-waisted trousers."},
		"work": {"name": "Teacher", "desc": "White shirt, pencil skirt and heels for school."},
		"workout": {"name": "Workout", "desc": "Sports bra and leggings for the gym."},
		"cozy": {"name": "Cozy", "desc": "Oversized sweater and soft pants for a night in."},
		"date": {"name": "Date Night", "desc": "A fitted dress for an evening out."},
		"sleepwear": {"name": "Sleepwear", "desc": "A silky nightgown."},
	},
	"makeup": {
		"natural": {"name": "Natural", "desc": "Light and fresh."},
		"office": {"name": "Polished", "desc": "Neat eyeliner and a soft lip."},
		"glam": {"name": "Glam", "desc": "Smoky eyes and a bold red lip."},
		"none": {"name": "Bare", "desc": "No makeup at all."},
	},
	"accessory": {
		"none": {"name": "None", "desc": "Nothing extra."},
		"glasses": {"name": "Reading Glasses", "desc": "For grading papers."},
		"earrings": {"name": "Gold Earrings", "desc": "Small hoops, a gift from her husband."},
		"necklace": {"name": "Pendant Necklace", "desc": "A delicate silver chain."},
	},
	"hair_up": {
		"down": {"name": "Worn Down", "desc": "Your salon style, the way the stylist left it. For a new cut or color, visit the hair salon at the mall."},
		"bun": {"name": "Teacher Bun", "desc": "Pinned up for work, a few curls left loose."},
	},
	"hairstyle": {
		"down": {"name": "Long Waves", "desc": "Soft waves over the shoulders."},
		"straight": {"name": "Sleek & Straight", "desc": "Blow-dried glossy and straight."},
		"layers": {"name": "Long Layers", "desc": "Face-framing layers with lots of movement."},
		"bangs": {"name": "Curtain Bangs", "desc": "Long hair with soft bangs parted in the middle."},
		"bob": {"name": "Shoulder Bob", "desc": "A bold cut to just above the shoulders."},
	},
	"hair_color": {
		"auburn": {"name": "Auburn", "desc": "Her natural red-brown.", "swatch": Color(0.55, 0.22, 0.12)},
		"copper": {"name": "Copper", "desc": "A brighter red.", "swatch": Color(0.78, 0.36, 0.16)},
		"chestnut": {"name": "Chestnut", "desc": "Warm brown.", "swatch": Color(0.4, 0.24, 0.15)},
		"black": {"name": "Black", "desc": "Deep and glossy.", "swatch": Color(0.12, 0.1, 0.1)},
		"blonde": {"name": "Honey Blonde", "desc": "Light and golden.", "swatch": Color(0.86, 0.68, 0.4)},
	},
}

const DEFAULTS := {"outfit": "casual", "makeup": "natural", "accessory": "none", "hair_up": "down", "hairstyle": "down", "hair_color": "auburn"}


static func categories_for(station: String) -> Array[String]:
	var result: Array[String] = []
	for category in CATEGORIES:
		if CATEGORIES[category]["station"] == station:
			result.append(category)
	return result


static func option_name(category: String, option_id: String) -> String:
	return OPTIONS[category].get(option_id, {}).get("name", option_id)


## Bilden för mammans nuvarande kläder, eller basbilden.
static func preview_image(appearance: Dictionary) -> Texture2D:
	var path := "res://Assets/characters/outfit/%s.png" % appearance.get("outfit", "casual")
	if ResourceLoader.exists(path):
		return load(path)
	return load(BASE_IMAGE)
