class_name SocialStats
## Mammans egenskaper (social stats) i Persona-anda: Charm, Fitness och Knowledge.
## Varje egenskap har XP som ger en nivå 1–5 med ett namn. Man får XP genom handlingar
## i världen ("social" i RoomActions). Nivåerna låser upp val ("requires"), och
## tillsammans ger de Attractiveness, som låser upp mer. Vad spelaren har finns i
## GameState.social; det här är bara data. All text spelaren ser är på engelska.

## Egenskaperna. levels är namnen på nivå 1–5.
const STATS := {
	"charm": {"name": "Charm", "color": Color(0.92, 0.4, 0.55),
		"levels": ["Reserved", "Friendly", "Charismatic", "Captivating", "Irresistible"]},
	"knowledge": {"name": "Knowledge", "color": Color(0.35, 0.5, 0.9),
		"levels": ["Curious", "Well-Read", "Knowledgeable", "Learned", "Brilliant"]},
	"fitness": {"name": "Fitness", "color": Color(0.3, 0.72, 0.45),
		"levels": ["Untrained", "Active", "Fit", "Athletic", "Peak Condition"]},
}
## XP som krävs för varje nivå (index 0 = nivå 1). En aktivitet som tar tid ger
## 3–5 XP och en snabb 1–2, så nivå 5 tar ungefär 25 aktiviteter.
const LEVEL_XP := [0, 10, 30, 60, 100]
const MAX_LEVEL := 5

## Egenskaper som tappar XP om man inte håller i dem: efter grace_days dagar utan att
## träna tappas xp varje natt. Man tappar aldrig en nivå man har nått, bara vägen mot
## nästa. Bara Fitness – kroppen glömmer, men det man har lärt sig och sin charm har man kvar.
const DECAY := {
	"fitness": {"grace_days": 2, "xp": 2, "text": "You skipped your workouts. Your fitness slipped a little."},
}

## Attractiveness = medelvärdet av de tre nivåerna (inte XP), 1.0–5.0. Namnet kommer
## från medelvärdet avrundat nedåt.
const ATTRACTIVENESS_TITLES := ["Unassuming", "Appealing", "Attractive", "Magnetic", "Mesmerizing"]
## Vad hög Attractiveness låser upp, per nivå (avrundat nedåt). Effekterna finns i
## GameState; val som kräver en nivå har "requires": {"attractiveness": n} i RoomActions.
const ATTRACTIVENESS_UNLOCKS := {
	3: "People warm up to you: +1 ♥ on every relationship action",
	4: "Magnetic options: people make offers they wouldn't make anyone else",
	5: "Your Romance meter no longer slips overnight",
}
## Nivåerna där effekterna ovan börjar gälla.
const LINK_BONUS_TIER := 3
const NO_ROMANCE_DECAY_TIER := 5


static func level_for_xp(xp: int) -> int:
	var level := 1
	while level < MAX_LEVEL and xp >= LEVEL_XP[level]:
		level += 1
	return level


static func level_name(stat: String, level: int) -> String:
	return STATS[stat]["levels"][level - 1]


static func attractiveness_title(rating: float) -> String:
	return ATTRACTIVENESS_TITLES[floori(rating) - 1]
