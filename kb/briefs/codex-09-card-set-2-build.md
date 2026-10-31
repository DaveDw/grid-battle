# Brief: build card set 2 into the game (Codex / Astra)

Status: open
Spec: `kb/proposals/claude-card-set-2.md` (approved by David). Build exactly that: the five
game-wide rules and the 40 cards, with the costs, targets and effects listed there.
Claude is NOT editing code while you work on this; you own the .gd files for this task.

## Already done
- Icons: all 40 are installed in `assets/cards/<id>.png` (128 px, 4x of the 32 px art). The ids
  are in `kb/briefs/codex-08-card-set-2-icons.md`. `Game.card_art(id)` finds them by id.

## Where things go (read these first)
- `scripts/game.gd`
  - `CARDS`: one entry per card: `{"name", "cost", "target": "unit"|"tile"|"none", "text"}`. Keep
    `text` short like the existing ones (it shows on 32 px hand cards).
  - `FACTION_CARDS`: add each faction's 10 new ids (draftable pool).
  - `CARD_RARITY`: the rarity from the spec (0 Common, 1 Uncommon, 2 Rare, 3 Legendary).
- `scripts/battlefield.gd`
  - `_apply_card(team, id, sel, aim_row, tile)`: the effect. `sel` is the acting unit, `tile`
    the aimed tile, `team` 0 player / 1 enemy. Both teams must be able to play every card.
  - `valid_tile(team, id, tile)` and `OWN_GROUND_CARDS` for tile cards that must target your
    own side (Holo Decoy) or an enemy unit.
  - Existing systems to reuse: `fires`, `fields` (Containment), `mires`, `spores`, `floods`,
    `fortified`, `pools`, `barricades`, `drones`, `void_orb`, `_push_to_nearest`, forced moves
    (`forced_at`), `barrier`, `heal_until`/`heal_rate`, mortar shots (`"kind": "mortar"`, with
    a negative `t` to stagger), `team_energy`, `team_stamina`, `hands[team]`.
  - Damage goes through the unit's `take_damage` / the battlefield hit code: put new damage
    modifiers (Spotter Flare, Smoke Screen, Pollen Cloud, Lifeline, Mirror Shield, Calibrate,
    Red Shift) in one place there, not scattered.
  - Enemy AI: `_ai_card_plan(id)` returns `{"value", "unit", "tile"}` (value < 0 = hold); give
    every new card a plan with a sensible target and a "don't play this uselessly" rule, and
    add combos to `AI_COMBOS` where the spec's "Combos with" makes sense.
  - Draw the new board objects (mines, wire, thorns, decoy, whirlpool, flooded column, Event
    Horizon, Annex tiles) in `_draw()` near the other `_draw_*` helpers, in the same style.
- `scripts/unit.gd`: per-unit timers live here (like `echo_until`, `overclock_until`).
- `scripts/card_hand.gd`: hand / draw timer (for the draw-speed rule) and per-copy state.

## Game-wide rules (do these first; they change existing cards too)
1. **MK copies**: a card that changes the board until it is played again (Annex, Deploy
   Drone) tracks each copy separately and shows its mark (MK I, MK II, MK III...) on the card
   and next to what it placed. Replaying that copy moves its effect. Deploy Drone: one drone
   per copy, lasting until that copy is replayed; **cost 40**.
2. **Moving your own unit breaks locks**: Flash Forward, Wave Rider, Phase Shift free the unit
   from Containment/Firewall/roots/Event Horizon/Razor Wire/mud and ignore them for the move.
3. **Pure draw cards speed the draw timer**: Requisition, Recompile, Spare Parts also make draws
   50% faster for 6 s.
4. **Alternate fire cooldown**: a lone leader's alternate shot (E / R1, `fire_alt`) has a 1.5 s
   cooldown, shown on the HUD hint.
5. **Blocked pushes hurt**: a unit pushed or pulled with nowhere to go takes 8 damage and is
   stunned 0.5 s (can't move or shoot). Applies to every forced move (Undertow, Undertow
   Surge, Riptide, Flood, Claim/Stake Claim push-backs, and the new cards).

## Order
1. Game-wide rules. 2. Cards that reuse existing systems. 3. Cards with new mechanics.
4. AI plans and combos. After each step, run the checks below and append a line to
`kb/NEXT.md` saying what's in.

## Checks (all must pass before you say a step is done)
- `godot --path . --headless --import` and `godot --path . --headless --quit-after 300`: no
  SCRIPT ERROR / Parse Error.
- Existing rigs, same output as before: `tools/rigs/check/feedback.tscn`, `shots.tscn`,
  `ai_probe.tscn` (20 PASS), `rarity.tscn`, `lane.tscn`, `lastcard.tscn`
  (run as `godot --path . res://tools/rigs/check/<name>.tscn -- <out_dir>`).
- Add `tools/rigs/check/cards2.tscn` (+ `cards2_node.gd`), following `ai_probe_node.gd`: for
  every new card, play it from each team in a staged battle and check its main effect happened
  (one PASS line per card), plus one check per game-wide rule. Use save slot 99 and delete it.

## Don't
- Don't commit or push. Don't change existing cards beyond what the rules above say.
- Don't rebalance the spec's numbers; if one is impossible or clearly broken, note it in
  `kb/proposals/claude-card-set-2.md` under "Open" and build the closest version.
