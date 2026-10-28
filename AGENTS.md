\# Agent entry point



Read, in order, before every session:

1\. CLAUDE.md — ownership and process. Binding.

2\. CONTRACT.md — the frozen surface. Binding.

3\. dialogue/STYLE.md — prose rules.



\## Hard boundaries

\- `dialogue/\*\*` and `story/\*\*` are READ ONLY. Never edit prose.

\- Frozen vars, never rename: `links`, `stats`, `social`, `flags`, `period`, `day`, `current\_room`.

\- All balance numbers live in `scripts/balance.gd`. No inline magic numbers.

\- Note: the art manifest is `Assets/manifest.json`, not `art/manifest.json`.



\## Godot 4.7.2 syntax — the repo is 4.7, never 3

\- CharacterBody2D/3D, Area2D/3D, Sprite2D, Node3D. Not KinematicBody\*, Spatial, Sprite.

\- `btn.pressed.connect(on\_pressed)`. Not `.connect("pressed", self, "on\_pressed")`.

\- `SCENE.instantiate()`. Not `instance()`.

\- `await get\_tree().create\_timer(1.0).timeout`. Not `yield`.

\- `@export var x: int`. Static types on all params and returns.

\- `class\_name` on every Resource.



\## Working style

\- One task per session. Define done. Touch only what the task needs.

\- Don't restructure, rename or reorganise existing files unless asked.

\- Don't run git commands unless asked.

