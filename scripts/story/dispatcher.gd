class_name Dispatcher
## Väljer vilken scen som spelas i en tidszon. Varje scen_id måste registreras här.

## scen_id -> registrerad scen.
const SCENES := {}


## Scenen som ska spelas i tidszonen (index i GameState.TIME_PERIODS), eller "" om ingen.
static func resolve_slot(_period: int) -> String:
	return ""
