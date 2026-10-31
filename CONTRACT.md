# CONTRACT

Shared surface between writer and engineer. Append only.
Section 1 is FROZEN — it already exists and must not change.

## 1. Frozen state (in scripts/game_state.gd)

Autoload: `GameState`

| var | type | notes |
|---|---|---|
| day | int | 1-based |
| period | int | index into TIME_PERIODS |
| stats | Dictionary | {home, work}, 0-100 |
| links | Dictionary | {son_1, son_2, husband} -> {rank 1-10, points} |
| social | Dictionary | {charm, knowledge, fitness} xp |
| flags | Dictionary | bool by key |
| current_room | String | |

Character ids: `mom`, `husband`, `son_1` (nerd, gaming), `son_2` (jock, football),
`dog`, `neighbor`, `principal`, `best_friend`.
Speaker name used for the mother in dialogue files: `Mom`.

## 2. To be added by the engineer

### State
| var | type | notes |
|---|---|---|
| lust | float | per character, 0-100, stored as `links[char]["lust"]` |
| tone | int | per-scene. Reset to 0 by the scene. tone >= 1 doubles the lust the scene pays. |
| suspicion | float | 0-100, global. See story/spine.md. |

### Functions the writer calls
| signature | purpose |
|---|---|
| GameState.apply(scene_id: String, tone := 0) | applies EFFECTS[scene_id], sets its flags |
| GameState.location(text: String) | location card |
| GameState.rank_card(char: String, rank: int) | rank-up card, fires last |
| GameState.sprite(char: String, pose: String) | show or swap a sprite |
| GameState.mood(char: String, mood: String) | expression swap |
| GameState.suspect(amount: float) | raises suspicion, clamped 0-100 |

### Tags
- `mood` : neutral, soft, strain, flushed, surprised, averted
- `pose` : see Assets/pose_list.md
- `sfx`  : filename without extension
- `action` : un-prefixed beat line. Render italic, muted, no name box.

### Setup
- Register `GameState` in Project Settings -> Dialogue Manager -> global state shortcuts.
- Start from `addons/dialogue_manager/example_balloon/` and modify it. Do not build a balloon from scratch.

## 3. Scene ids

Format `<char>_r<rank>` — e.g. `son_2_r4`. One file per rank.
There are no `_bonus` twins. The leftover `_bonus` rows in `Balance.EFFECTS` are dead
and can be deleted. `tone` doubles the lust the base scene pays instead.

`apply()` sets `Dispatcher.DONE_FLAG + base_id`. Schedules key appointments off it.

## 4. Appointments — a gate is not done until it is reachable

Scenes are gated to a room and a period. Character locations come from
`Schedules.RULES` and `Schedules.ROUTINES`. These are written separately, so a gate
is only real if the character is provably in that room at that period.

Before a gate goes into `GATES`, add a `RULES` entry for that character, above the
routine rules, conditioned on the previous scene being done and this one not:

    {"id": "appt_<char>_r<n>",
     "flags": ["scene_done_<char>_r<n-1>", "!scene_done_<char>_r<n>"],
     "periods": ["<period>"], "room": "<room>", "activity": "<activity>"}

Rules are first-match-wins, and the flag pair makes the appointment disable itself
once the scene is played. No gate may use `night` until night is a playable period.

## 5. Meters vs lust

Two separate numbers. Do not use one in place of the other.

- `GameState.meters[char]` (curves in `Requests`) = how much THEY want her / want things
  from her. Drives requests. For the sons this is the `wants` track only.
- `links[char]["lust"]` = how physically charged the relationship is. Drives scene gates.

## Change note — Romance meter removed (2026-10-26)

`stats` keeps its name but now holds only `{home, work}`, 0-100. The `romance` key and
its HUD meter are gone. Anything that used to give Romance now carries `"relief": N`,
which lowers Mom's own desire meter. Scene EFFECTS in `scripts/balance.gd` use the same
`relief` key instead of `stats.romance`. No dialogue file referenced `stats.romance`.

## Change note — contract reconciled with code (2026-10-31)

Section 2 now documents `apply(scene_id, tone := 0)` and adds `suspect()`.
Section 3 records that bonus scenes were dropped. Section 4 is new and binding:
every gate needs a reachability appointment. 23 of 40 planned ladder gates were
unreachable before this note.
