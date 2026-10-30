# Brief: smarter enemies that play to their faction (Codex / Astra)

Status: open
Output: `kb/proposals/codex-enemy-ai.md` (a plan, no code edits)
Owner of the code: Claude implements the plan in `scripts/unit.gd`, `scripts/battlefield.gd`
and `scripts/game.gd`. Please **don't edit any .gd files**: Claude is changing the same
files at the same time, and two writers would collide.

## Goal (from the human)
"Make the enemies smarter. Make the difficulty scale faster and have the different factions
play to their strengths."

## How the AI works today (read these to confirm)
- `scripts/unit.gd` `_run_ai()`: every enemy unit moves on a random timer (random direction,
  with a chance to step toward the weakest player row, or toward the border for Long Tomorrow)
  and fires on a random timer **whether or not anyone is in its row**. It sidesteps an incoming
  shot with a `dodge` chance.
- `scripts/game.gd` `ai_params()` and `AI_STYLES`: per-level timings and chances, multiplied
  by a faction style (Terran DUG IN, Ascendancy METHODICAL, Manyworlds RESTLESS, Long Tomorrow
  RECKLESS). Today a style only scales timings and chances; it doesn't change what the units *do*.
- `scripts/battlefield.gd`: enemy cards (`_update_enemy_cards`, `_ai_card_score`,
  `_ai_card_need`, `_ai_tile`, `_ai_card_unit`, `_ai_aim_row`), commander doctrines
  (`_update_doctrine`), helpers (`incoming_shot`, `weakest_player_row`, `_foes_in_row`).
- Difficulty: `Game.level()` = (sector - 1) × 3 + stage (+ NG+). `ai_params` reaches its
  fastest timings at level 8 (sector 3, stage 3).
- The rules for every unit's primary, passive and card are in `DESIGN.md` and `README.md`.

## What we need from you
A written plan Claude can implement directly. Be concrete: name the unit, the situation and
the action, with numbers where it matters.

1. **Shared tactics every enemy should have** (on top of today's dodge/focus), for example:
   only fire when a shot can actually land, step into a target's row before firing, get out of
   a row that's about to be hit, don't stand on hazards (fire, spores, mud), keep stamina for
   dodging. Rank them by how much smarter they'd make the enemy feel.
2. **Each faction's game plan**, in a short paragraph, built on what its kits are good at:
   - Terran: ground, fortified tiles, artillery, holding the line.
   - Ascendancy: marks (Analysis), drones, protocols, precision on the weakest unit.
   - Manyworlds: terrain (flood, mud, spores), forced movement + Ambush, angles (Refraction).
   - Long Tomorrow: trading HP for power, burn, gravity (Void Orb), burst (Interval Mark).
3. **Per unit (all 24)**: one to three rules for how the AI should use that unit's primary
   and passive. For example: Siege Rig fires the mortar when a player unit stands 3 columns
   ahead; Prism Elder moves 2 rows quickly before firing to arm Refraction; Reed Runner shoots
   right after an Undertow or Riptide pushes someone; Red Giant stops firing below 25% HP.
4. **Cards**: which cards each faction should combo, and when (e.g. Undertow Surge then Ambush;
   Mire on the tile the player is standing on, then Spore Bloom on that row).
5. **Difficulty curve**: how fast should it ramp? Today level 8 is the ceiling. Suggest the
   level at which each new behaviour switches on (e.g. combos from level 2, threat-avoidance
   from level 1), so early battles stay learnable and later ones feel sharp.
6. **Anything that would feel unfair**, so we avoid it (e.g. perfect dodging, reacting faster
   than a human could).

## Format
Follow `kb/README.md` ("Writing a proposal"): header with `Author: Codex`, `Status: open`,
`Touches: AI`. Use the numbered sections above. Keep it under about 250 lines.
Reply in the chat with a short summary when done.
