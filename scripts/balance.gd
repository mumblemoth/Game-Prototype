class_name Balance
## Alla balanssiffror för storyn. Varje scen_id får en rad i GATES (vad som krävs för att
## scenen ska kunna spelas) och en i EFFECTS (vad GameState.apply() lägger på efteråt).
## Inga siffror i logiken – de bor här.
##
## En ny rankscen kräver ingen kod: en rad i GATES, en i EFFECTS och dialogfilen på
## res://dialogue/<char>/<scen_id>.dialogue (se Dispatcher).

## Taket för links[char]["lust"] (CONTRACT.md, avsnitt 2).
const LUST_MAX := 100.0

## scen_id -> villkor för att scenen ska kunna spelas:
##   char   – id i GameState.CHARACTERS (och nyckel i links)
##   rank   – scenens rank; kräver links[char].points >= GameState.LINK_THRESHOLDS[rank]
##            och att föregående ranks scen för samma person är spelad, om den finns
##   period – tidszonen (namn i GameState.TIME_PERIODS)
##   room   – rummet mamman måste vara i (valfri)
##   lust   – kräver links[char].lust >= lust
##   attr   – kräver GameState.attractiveness_tier() >= attr
const GATES := {
	"eric_r1": {"char": "husband", "rank": 1, "period": "evening", "room": "living_room", "lust": 0.0, "attr": 1},
}

## scen_id -> effekter som GameState.apply() lägger på (alla nycklar valfria):
##   link_points – poäng i relationen till GATES[scen_id].char
##   lust        – läggs på links[char].lust, hålls inom 0–LUST_MAX
##   stats       – {home/work/romance: förändring}
##   flags       – händelser som sätts i GameState.flags
## En _bonus-scen utan egen rad får grundscenens effekter.
const EFFECTS := {
	"eric_r1": {"link_points": 2, "lust": 2.0, "stats": {"romance": 5}, "flags": []},
}
