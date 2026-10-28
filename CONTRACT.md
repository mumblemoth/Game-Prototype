# CONTRACT

Shared surface between writer and engineer. Append only.
Section 1 is FROZEN â€” it already exists and must not change.

## 1. Frozen state (in scripts/game_state.gd)

Autoload: `GameState`

| var | type | notes |
|---|---|---|
| day | int | 1-based |
| period | int | index into TIME_PERIODS |
| stats | Dictionary | {home, work, romance}, 0-100 |
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
| tone | int | per-scene. Reset to 0 by the scene. Doubles lust at 1 or more. |

### Functions the writer calls
| signature | purpose |
|---|---|
| GameState.apply(scene_id: String) | applies EFFECTS[scene_id], sets its flags |
| GameState.location(text: String) | location card |
| GameState.rank_card(char: String, rank: int) | rank-up card, fires last |
| GameState.sprite(char: String, pose: String) | show or swap a sprite |
| GameState.mood(char: String, mood: String) | expression swap |

### Tags
- `mood` : neutral, soft, strain, flushed, surprised, averted
- `pose` : see art/pose_list.md
- `sfx`  : filename without extension
- `action` : un-prefixed beat line. Render italic, muted, no name box.

### Setup
- Register `GameState` in Project Settings -> Dialogue Manager -> global state shortcuts.
- Start from `addons/dialogue_manager/example_balloon/` and modify it. Do not build a balloon from scratch.

## 3. Scene ids

Format `<char>_r<rank>` â€” e.g. `son_2_r4`.
Every rank scene has a `_bonus` twin. `tone >= 2` fires the `_bonus` variant instead.

## 4. Registry

`story/registry.json` belongs to the writer. Schema:

    { "id", "type", "char", "rank", "slot", "location",
      "requires", "act", "trigger": {}, "effects", "priority", "once" }

## 5. Meters vs lust

Two separate numbers. Do not use one in place of the other.

- `GameState.meters[char]` (curves in `Requests`) = how much THEY want her / want things
  from her. Drives requests. For the sons this is the `wants` track only.
- `links[char]["lust"]` = how physically charged the relationship is. Drives scene gates.

## Change note â€” Romance meter removed (2026-10-26)

`stats` keeps its name but now holds only `{home, work}`, 0-100. The `romance` key and
its HUD meter are gone. Anything that used to give Romance now carries `"relief": N`,
which lowers Mom's own desire meter. Scene EFFECTS in `scripts/balance.gd` use the same
`relief` key instead of `stats.romance`. No dialogue file referenced `stats.romance`.

