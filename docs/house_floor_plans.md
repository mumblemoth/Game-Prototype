# House floor plans (redesigned 2026-10-26)

All measurements are in metres. North is up. The street is to the north and the garden to the south. The in-game camera looks from the south, so south walls are the cut-away "dollhouse" side. The images in `floor_plans/` are rendered from the game data by `tools/house_plan_export.tscn`. Re-run it after any layout change.

## Why it changed

The previous house was 15.6 × 10 m on every floor. Five rooms had to fill 156 m² each, so they came out unrealistically large: a 33 m² hall, a 56 m² living room and a 56 m² bedroom, plus a lot of empty floor.

The new house is a roomy two-storey family villa, **12.8 × 8.8 m (113 m² per floor)**. The room sizes follow real villa plans:

- **Ground floor:** the kitchen faces the street, as in classic Swedish villas, and the living room runs through to the garden.
- **Upstairs:** the wet rooms are stacked (bathroom over the guest WC).
- **Stair:** stays in one stacked core. It is the same 2.0 × 2.8 m U-stair, along the east wall of every hall (x 6.9–8.9).

## Ground floor: 12.8 × 8.8 m

| Room | Size | Area | Was | Notes |
|---|---|---|---|---|
| Kitchen | 5.6 × 5.4 | 30 m² | 34 m² | Still the style template: counters along the street wall, dining table in the middle, a low sideboard toward the hall. A **side door** (west) next to the dog's bed leads out to the side path and the garden. |
| Hallway | 3.4 × 6.6 | 22 m² | 33 m² | Front door N, U-stair along the east wall with the cellar door under flight 2. Shoe rack, coat stand (the family's jackets and the dog's leash), striped runner, console with keys, mail and Mom's school bag. |
| Living Room | 3.8 × 8.8 | 33 m² | 56 m² | Runs from street to garden. TV corner with sofa and Dad's armchair, a reading nook by the picture window, bookshelf, sideboard, and **French doors** to the patio. The door from the hall sits below the stair (`PlanDrawer.DOOR_POSITIONS`). |
| Home Office | 5.6 × 3.4 | 19 m² | 22 m² | Faces the garden. Desk under the west window with Mom's stacks of tests, office chair, bookshelf, reading chair with a floor lamp. |
| Guest WC | 3.4 × 2.2 | 7 m² | 11 m² | Shower, vanity basin, toilet. |

## Upstairs: 12.8 × 8.8 m

| Room | Size | Area | Was | Notes |
|---|---|---|---|---|
| Son's Room 1 | 4.4 × 4.4 | 19 m² | 27 m² | Above the kitchen. Gaming desk under the window, console and beanbag, figure shelf, narrow wardrobe. |
| Son's Room 2 | 4.4 × 4.4 | 19 m² | 29 m² | Above the office. Trophy shelf, bench press, field rug, desk under the window, football bag. |
| Upstairs Hall | 4.6 × 5.6 | 26 m² | 33 m² | The family's landing lounge: stairwell, attic ladder between the boys' doors, photo wall with a board-game shelf under it, laundry hamper by the bathroom. |
| Bathroom | 4.6 × 3.2 | 15 m² | 11 m² | Above the guest WC. Bathtub, shower, double vanity, toilet. |
| Bedroom | 3.8 × 8.8 | 33 m² | 56 m² | Above the living room. Bed under the window band, reading chair, vanity, a dressing corner with the wardrobe, white laptop desk. |

## Basement: 12.8 × 6.6 m (north part only)

| Room | Size | Notes |
|---|---|---|
| Laundry Room | 5.6 × 4.0 | Washer and dryer, white folding counter, drying rack, ironing board, steel shelf. |
| Storage | 5.6 × 2.6 | Steel shelf, boxes, the holiday decorations, an old trunk. |
| Basement Hall | 3.4 × 6.6 | Stair directly under the hall stair, steel supply shelf, the family's bikes. |
| Hobby Room | 3.8 × 6.6 | Mom's training corner (mat, treadmill, dumbbells) and a painting corner by the window (easel, paint table, art shelf). |

The south 2.2 m (under the guest WC and the garden end of the house) sits on a slab.

## Attic: 10.8 × 6.0 m usable floor

Inside the knee walls under a roof with the ridge along the house; gable windows face W and E. The hatch sits right above the ladder in the upstairs hall. It holds the trunk with the wedding album, boxes of baby clothes, the boys' old cradle and an armchair under a sheet.

## Outside: a front yard and a backyard on the real lot

The lot is 20 m wide with the house in the middle. Both yards are drawn in the house's own coordinates, so they meet the house exactly on every floor and in every view:

- **Front Yard** (20 × 7, north): driveway with the family car at the west edge, stone path from the gate to the front door, flower pots by the steps, flower beds along the facade, a tree with a bench, and a picket fence with openings for the path and driveway. The street, the sidewalk and the mailbox are beyond the fence.
- **Backyard** (20 × 7.6, south; new room): patio outside the living room's French doors with a picnic table, grill and planter. There's also a stepping-stone path along the house, clothesline, Mom's raised vegetable bed, a garden shed, sun loungers, an apple tree and a low fence at the back.
- **Sides:**
  - West: a side path runs from the driveway past the kitchen door to a garden gate.
  - East: the gable has a flower bed and a closed fence.
  - Hedges mark the lot lines, and the neighbours' houses stand beyond them.

On the Outside floor the house between the two yards is shown cut away (floors and low wall caps), so it does not hide the front yard. From inside the house, the dollhouse rule hides tall garden things in front of the camera (shed, clothesline, trees). The backyard's low things (patio, table, loungers, beds) stay visible through the cut-away south walls.

**Doors to the outside** (`PlanDrawer.FRONT_DOORS` and `PlanDrawer.GARDEN_DOORS`):

| From | Door | To |
|---|---|---|
| Hall | Front door | Front Yard |
| Kitchen | Side door | Backyard |
| Living Room | French doors | Backyard |

The Front Yard and the Backyard also connect to each other through the side path. Each door has steps down to the ground.

## Doors inside

Every room still connects to the same rooms as before. The new connections are the three doors to the backyard (`scenes/rooms/backyard.tscn`, and `ToBackyard` in the kitchen, living room and outside scenes). A door sits in the middle of the shared wall unless `PlanDrawer.DOOR_POSITIONS` moves it away from the stair.

## Furniture variety

`FloorPlanArt.FURNITURE` items take an optional fourth element, a style (`scripts/house3d/home_kit.gd`), so the same kind no longer looks identical in every room:

- **Rugs:** sage, navy stripes, runner, jute, wool, purple, blush, faded.
- **Shelves:** bookshelf, sideboard, steel shelf, board-game shelf, art shelf.
- **Armchairs and sofas:** rust, cream, mustard, blush, a dust sheet.
- **Bedding:** gamer, team, linen.
- **Chairs:** dining, office, white.
- **Desks:** a teacher's desk with tests, a white laptop desk.
- **Basins:** single, double, and no mirror against low walls. The mirror used to float above the low wall; this fixes that known leftover.
- **Others:** dryer, bike colours, holiday boxes, tall plant, flower planter.

New pieces that each tell something about the family or belong to a chore:

| Indoors | Outdoors |
|---|---|
| Coat stand with the dog's leash | Driveway |
| Console with keys and mail | Patio |
| Floor lamp | Flower bed |
| Side table and paint table | Grill |
| Ironing board | Vegetable bed |
| Cradle | Clothesline |
| | Sun lounger |
| | Shed |

Filler plants were removed.

## Code changes

- `scripts/plan_drawer.gd`:
  - New `FLOOR_PLANS` and the Outside lot.
  - `GARDEN_DOORS` and `exterior_doors()` / `exterior_door_edge()`.
  - `DOOR_POSITIONS` and `door_middle()`.
- `scripts/floor_plan_art.gd`:
  - Windows and furniture for every home room and both yards.
  - Item styles (`item_style()`).
  - `YARD_FENCES` / `yard_gaps()`.
- `scripts/house3d/home_kit.gd` (new): the new kinds, the style variants and their plan symbols.
- `scripts/house3d/furniture_kit.gd`:
  - Styles are passed through to `build()`.
  - Basins skip the mirror against low walls.
  - `furnish()` takes an optional `skip` filter.
- `scripts/house3d/style_kit.gd`:
  - Garden doors and moved doors in the walls.
  - Yard fences with gates.
  - Wall colours for the upstairs and basement rooms.
- `scripts/house3d/surroundings.gd`:
  - The yards sit on the lot at ground level.
  - Tall yard items are filtered out in front of the camera.
  - The house is shown cut away from the yards.
  - Steps and door leaves for every exterior door.
  - A new `_home()` (street, side path and gate, hedges, neighbours).
- `scripts/game_state.gd`, `scripts/room_actions.gd`, `scenes/rooms/`: the new Backyard room with three chores (weed the vegetable bed, hang laundry, relax in the sun).
- `tools/house_plan_export.gd`: the new footprint, an Outside render and more close-ups.

## Known leftovers

- The painted 2D kitchen tile in `Assets/plan_rooms/` still matches the kitchen's proportions, so the 2D plan shows it. It shows the older furniture positions. The game itself uses the 3D view.
- In the 2D plan, trees, cars and the picnic table have no symbol of their own; they draw only as a shadow box. This was the same before.
