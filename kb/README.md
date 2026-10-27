# Grid Battle knowledge base

A shared notebook for the three agents on this project and the human who directs them.

| Agent | Where it runs | Role here |
|---|---|---|
| **Claude** (Claude Code) | this repo | Lead: writes the game code, reviews every proposal, decides what gets built, keeps `decisions.md`. |
| **Codex** | Codex app, local project on this folder | Art: sprite frames into `art_incoming/` (see `briefs/`). Doesn't edit code. |
| **Gemma** (Hermes) | Hermes agent | Ideas: brainstorms, writes proposals and briefs. Doesn't edit code or art. |

The human has the final say over everything.

## Files

- `roster.md` lists every unit, kit and card, generated from the game's data. Read it first and treat it as the truth. Don't edit it.
- `briefs/` holds work orders, one per job. Each brief says who it's for, what done looks like, and where the output goes.
- `proposals/` holds ideas: one file per idea, named `<agent>-<short-topic>.md` (e.g. `gemma-terran-cards.md`).
- `decisions.md` is the log of what was accepted, rejected or changed, and why. Only Claude writes here.

## Writing a proposal

Start the file with this header:

```
Author: <agent>
Status: open        (Claude changes this to accepted / rejected / revised)
Touches: <cards | units | AI | balance | UI | art | sound | story>
```

Then:
1. **The idea**, in plain words.
2. **Why it's fun**, and what decision it creates for the player.
3. **Exact numbers**, using the game's real units: energy cost (a full bar is 100), seconds, damage (a shot does 5-10), HP (light 90, leader 140, heavy 180), tiles (6 columns x 9 rows, 3 columns per side).
4. **How it fits the faction:**
   - Terran: holds and claims ground.
   - Ascendancy: marks, drones and protocols.
   - Manyworlds: water, mud and spores.
   - Long Tomorrow: trades HP and time for power.
5. **Risks:** could it be too strong, confusing, or a copy of an existing card?

## Deliberating

Reply inside a proposal under a `## Response from <agent>` heading. Never rewrite someone else's text. Keep critiques concrete: "this costs 10 but does what Sandbags does for 12" beats "seems strong". Claude records the outcome in `decisions.md`.
