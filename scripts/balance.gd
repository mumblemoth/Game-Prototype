class_name Balance
## Alla balanssiffror fÃ¶r storyn. Varje scen_id fÃ¥r en rad i GATES (vad som krÃ¤vs fÃ¶r att
## scenen ska kunna spelas) och en i EFFECTS (vad GameState.apply() lÃ¤gger pÃ¥ efterÃ¥t).
## Inga siffror i logiken â€“ de bor hÃ¤r.
##
## En ny rankscen krÃ¤ver ingen kod: en rad i GATES, en i EFFECTS och dialogfilen pÃ¥
## res://dialogue/<char>/<scen_id>.dialogue (se Dispatcher).

## Taket fÃ¶r links[char]["lust"] (CONTRACT.md, avsnitt 2).
const LUST_MAX := 100.0

## scen_id -> villkor fÃ¶r att scenen ska kunna spelas:
##   char   â€“ id i GameState.CHARACTERS (och nyckel i links)
##   rank   â€“ scenens rank; krÃ¤ver links[char].points >= GameState.LINK_THRESHOLDS[rank]
##            och att fÃ¶regÃ¥ende ranks scen fÃ¶r samma person Ã¤r spelad, om den finns
##   period â€“ tidszonen (namn i GameState.TIME_PERIODS)
##   room   â€“ rummet mamman mÃ¥ste vara i (valfri)
##   lust   â€“ krÃ¤ver links[char].lust >= lust
##   attr   â€“ krÃ¤ver GameState.attractiveness_tier() >= attr
const GATES := {
	"eric_r1": {"char": "husband", "rank": 1, "period": "evening", "room": "living_room", "lust": 0.0, "attr": 1},
	"miles_r1": {"char": "son_1", "rank": 1, "period": "afternoon", "room": "classroom", "lust": 0.0, "attr": 1},
}

## scen_id -> effekter som GameState.apply() lÃ¤gger pÃ¥ (alla nycklar valfria):
##   link_points â€“ poÃ¤ng i relationen till GATES[scen_id].char
##   lust        â€“ lÃ¤ggs pÃ¥ links[char].lust, hÃ¥lls inom 0â€“LUST_MAX
##   stats       â€“ {home/work: fÃ¶rÃ¤ndring}
##   relief      â€“ sÃ¤nker mammans egen mÃ¤tare (se GameState._relieve_mom)
##   flags       â€“ hÃ¤ndelser som sÃ¤tts i GameState.flags
## En _bonus-scen utan egen rad fÃ¥r grundscenens effekter.
const EFFECTS := {
	"eric_r1": {"link_points": 2, "lust": 2.0, "relief": 5, "flags": []},
	"eric_r1_bonus": {"link_points": 3, "lust": 4.0, "relief": 8, "flags": []},
	"miles_r1": {"link_points": 2, "lust": 2.0, "relief": 5, "flags": []},
	"miles_r1_bonus": {"link_points": 3, "lust": 4.0, "relief": 8, "flags": []},
}
