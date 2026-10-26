class_name Balance
## Alla balanssiffror för storyn. Varje scen_id får en rad i GATES (vad som krävs för att
## scenen ska kunna spelas) och en i EFFECTS (vad GameState.apply() lägger på efteråt).
## Inga siffror i logiken – de bor här.

## scen_id -> villkor för att scenen ska kunna spelas.
const GATES := {}

## scen_id -> effekter som GameState.apply() lägger på.
const EFFECTS := {}
