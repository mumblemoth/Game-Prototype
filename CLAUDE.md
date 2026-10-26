\# CLAUDE.md



Read this before every session.



\## Who owns what



| Path | Owner | Rule |

|---|---|---|

| `dialogue/\*\*` | writer | READ ONLY. Never edit prose. |

| `story/\*\*` | writer | READ ONLY. |

| `art/manifest.json` | writer | READ ONLY. |

| `scripts/\*\*` | you | build freely |

| `scenes/\*\*` | you | build freely |

| `CONTRACT.md` | shared | append only, flag changes |



\## The contract



1\. Every rank scene ends with `$> GameState.apply("<scene\_id>")`.

2\. For each new scene\_id, add `GATES` and `EFFECTS` entries in `scripts/balance.gd`.

3\. Implement every `GameState.\*` function any dialogue file calls.

4\. Register every scene\_id in `scripts/story/dispatcher.gd`.

5\. Dialogue lines carry `\[#mood=...]`, `\[#pose=...]`, `\[#sfx=...]`. Implement the tag readers in the balloon.



\## Hard rules



\- Never rename an existing variable. `links`, `stats`, `social`, `flags`, `period`, `day`,

&#x20; `current\_room` are FROZEN. If a rename is unavoidable, update CONTRACT.md and say so.

\- Never edit anything under `dialogue/` or `story/`.

\- Never rewrite dialogue prose.

\- When a task is specified, build it. Don't stop to ask. Flag concerns afterwards.

\- All balance numbers live in `scripts/balance.gd`. No magic numbers inline in logic.

\- Dialogue files are English. Code comments stay Swedish, as the repo already does.



\## Finding work



grep -rho 'GameState\\.\[a-z\_]\*(' dialogue/ | sort -u

grep -rho 'apply("\[a-z0-9\_]\*")' dialogue/ | sort -u

