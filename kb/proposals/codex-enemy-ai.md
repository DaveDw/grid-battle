Author: Codex
Status: accepted, built (see responses)
Touches: AI

# Enemy AI: purposeful attacks, faction tactics, faster learning curve

2026-10-30. Proposal for Claude to implement; no gameplay changes or runtime verification performed by Codex.
Read: `kb/briefs/codex-07-enemy-ai.md`, `kb/roster.md`, `DESIGN.md`, `README.md`, and the current AI, attack, card, resource and mode implementations.
The generated roster is useful for unit identities but predates recent card changes: current Overclock is **12 energy / 4s active / 3s jam**; Echo Strike is **20 energy / 4s of echoes**, with each original shot paid normally. Preserve these changes.
All numbers below are proposed AI tuning unless explicitly described as existing rules. This pass changes decisions, not unit damage, card effects, resource income or player controls.

## 1. Shared tactics, ranked by how much smarter they should feel

The idea: enemies should visibly prepare useful attacks, spend resources together, and exploit their actual kits. The player can break their setup by changing lanes, separating targets, denying ground or forcing defensive movement.

| Rank | Tactic | Concrete decision |
| --- | --- | --- |
| 1 | Fire at something reachable | Before winding up, evaluate the chosen primary's actual trajectory, range and first opposing target. Ordinary bullets need a living opponent ahead in their row; a weak unit behind another is not directly hittable. Mortar, Courtesy Round, Refraction and Afterimage need their own coverage rules. |
| 2 | Move to attack, then stay useful | Score staying and the four adjacent legal moves. Take a shortest legal route toward a useful firing cell, rather than randomly wandering. Do not move just because a timer elapsed. Prefer the first step of a route that improves coverage, even when no target is one step away. |
| 3 | Avoid damage that is actually coming | From level 1, consider visible bullets, curved/splitting bullets and mortar landing tiles, plus harmful fire/spores. Compare remaining impact time with reaction delay + the 0.09s movement animation. A dodge destination must also be safer than staying. |
| 4 | Budget the squad's resources | Keep one stamina chunk for escape at levels 1–2; at level 3+, keep two with multiple allies alive, one when alone. Reserve real card/charge costs and deliberately pause spending to recharge. Three independent spending timers must not starve one another. |
| 5 | Finish a setup | Keep a target for 2s unless dead, unreachable or another action prevents a death. Extend commitment to a valid mark sequence. Prefer the reachable damaged/marked opponent, rather than chasing the globally weakest row through bad terrain. |
| 6 | Coordinate lanes | Reserve an intended destination until the move completes; resolve competing moves in rotating unit order. At level 3+, focus at most two allies on one target when another useful lane exists; the third covers a different threat. In solo fights, this restriction disappears. |
| 7 | Respect hostile effects | Count mud's two-chunk exit cost, immobilization, protocol HP penalties, Void Orb's extra ally drags and expiring ground. Leave dangerous ground when legal; do not issue an impossible move repeatedly. |
| 8 | Use cards for an observable payoff | Evaluate the card, selected ally, tile/row and planned follow-up together. A faction preference never makes a useless or invalid card worthwhile. Basic no-op checks apply from level 0. |

### Small decision system, using existing calls

- In `battlefield.gd`, add pure queries for attack coverage, threats, move cost/risk and card candidates. Return a candidate containing actor, mode, target, tile/row, expected benefit and total cost; do not select a different random target when executing it.
- In `unit.gd`, let `_run_ai()` execute a small state sequence: choose / move / wind up / charge if applicable / recover. In `game.gd`, expose the level table and faction preferences through `ai_params()`.
- Continue executing through `try_move`, `fire_primary`, `fire_alt`, `charge_tick`, `release_charge` and `play_card`. Queries must account for `can_move` being only a tile check: roots, Containment, mud cost and protocol consequences live elsewhere.
- Use current board `rows` (3, 6 or 9), actual living units, and the unit's current `primary`, `passive`, `alt_primary` and `alt_role`. Never assume three allies or key tactical rules only to sprite names. Solo Conquest leaders inherit their squad's relevant rules.
- Reconsider decisions every 0.15s, staggered between units. This is a thinking interval, not permission to move/fire that often. Track action readiness separately; use absolute timestamps so telegraph branches cannot accidentally pause attack cooldowns.
- Attack coverage must follow the real firing direction, occupied target cells and projectile paths. Friendly units do not block bullets; hostile Sandbags do. A deliberate cheap shot to strip Sandbags is useful, but do not spend a charged beam into them. Mortars bypass them.
- Initial movement score: +30 for a useful attack lane, +15 for finishing an available kit setup, +8 for useful fortification/healing, -4 per remaining path step, -8 per stamina chunk spent, -20 for ending on harmful fire/spores, -12 for entering mud. Subtract expected incoming damage over 0.8s; reject predicted lethal choices when a safe choice exists. Add +6 to staying to prevent oscillation; use seeded jitter of at most 2 only for ties.
- Initial target score, among reachable targets: +40 for a plausible lethal hit after defenses, +20 for an existing own-team Analysis/Interval mark, +15 for completing the actor's existing mark pips, +10 × missing-HP fraction, -4 per movement step. Lowest distance breaks ties. Do not add all unreachable enemies to an attack's value.
- Resource arbitration: at energy <20, enter squad recovery until energy reaches 55. Stop ordinary shots, charge drain and nonurgent cards, including zero-cost cards that reset the recharge delay. Existing recovery is 1.5s without spending then 30/s; use the bar's modified delay in Ion Storm/Starved Earth. Allow a lifesaving defense or credible immediate kill to interrupt; reevaluate afterward. Burn Bright may end recovery if it reaches the threshold.
- Reserve costs only for a concrete action/sequence using cards already in hand: expire unstarted setups after 3s; an executing mark burst may keep its remaining budget until 4s after its first windup. Cancel reservations if the actor dies, the target escapes or a card burns. Stamina reserve can be spent to escape damage or complete an immediate kill, but not for idle movement. Include free Glasswing moves, mud and reachable Void Orb drags in the estimate.
- Hold the chosen lane and fire mode through the windup. At release, recheck legality, affordability, jam and whether that attack still has a target; an empty lane cancels with at least 0.6s before another windup. Do not swivel onto another row during the same telegraph. Do not move during a windup or charge.
- Fire mode must remain explicit through windup/charge/release/echo bookkeeping, including all solo alternate attacks and Chief Visionary's alternate beam. The current 40% random alternate selection is replaced by coverage and cost comparison; a leader's cheap standard shot cannot authorize an unaffordable alternate. At early levels use a simple legal, affordable mode preference; full payoff comparison unlocks at level 3.
- Missing a firing opportunity should trigger another decision after 0.25s, not waste the entire attack interval. Failed cards likewise get a 0.5s reconsideration delay; successful cards use the normal interval or the bounded combo rule below.

## 2. Each faction's game plan

**Terran — establish a firing position, then make leaving it costly.** Banner Marshal's squad keeps Siege Rig at the column that gives a real mortar target and uses Fortify/Sandbags to sustain occupied lanes. Claim Lord's squad takes connected, useful ground with Breacher forward and Standard Guard settled behind. Stay still while the position works; relocate when the player empties the lane or artillery/hazards outweigh cover. The player can flank their formation or force them to surrender Braced/Dig In uptime.

**Ascendancy — set up one target and spend accurately.** Field Scholar builds Analysis while Chief Visionary supplies a useful drone lane and Synapse Brute charges into a credible hit. Director Zero's squad puts Protocol Warden where retaliation will connect and applies pressure during the actual randomly selected protocol. Containment and marks create short coordinated volleys; shields protect the setup. Moving out of the lane or obeying a protocol should reduce the payoff.

**Manyworlds — change where the opponent can safely stand.** Tide Speaker's squad uses legal displacement to arm Reed Runner's Ambush, then attacks the resulting position. Prism Elder's squad sets up split coverage while Spore Keeper makes selected ground expensive and Glasswing preserves stamina. Mud slows escape; it does not root or deal damage. The player can spread out, deny a push destination, or leave spores before the next tick.

**Long Tomorrow — spend health when the damage window justifies it.** Mission Mother sustains Red Giant and Cinder Scout through purposeful volleys, then pauses them before self-damage becomes suicidal. Captain Everafter builds and cashes out Interval Mark; Deadweight's Void Orb and Parallax's previous tile punish movement across multiple lanes. HP payments and cooldown debt create visible recovery opportunities; pressing forward is conditional on useful coverage and survival.

## 3. Per-unit primary and passive rules: all 24

Apply basic legality, useful positioning and self-preservation from level 0. Coordinated bursts, planned two-step movement and ally follow-ups unlock as specified in section 5. Cards remain usable after their original unit dies.

| Unit | Rules to implement |
| --- | --- |
| **Banner Marshal** | Hold a safe row containing a reachable opponent and fire the 8-energy/8-damage shot. Prefer an existing fortified cell when it preserves that lane; do not chase forward merely to look aggressive. Offer Fortify to the ally with the best sustained position, not automatically himself. |
| **Siege Rig** | Fire only if an opponent occupies the actual landing cell `clamp(col + dir * 3), row`; for an enemy on columns 3/4/5, that means player columns 0/1/2. Reposition column as well as row to acquire it. Prefer immobilized/stationary targets: the 16-energy/16-damage shell takes 0.9s after release to land. |
| **Pathfinder** | Protect an existing Steady Aim streak by choosing reachable, unblocked shots. The three hits need not share a target; switch after a kill rather than firing into emptiness. Do not waste the refunded chunk on an unnecessary step. |
| **Claim Lord** | Fire from a useful safe lane; advance onto claimed ground only when it improves coverage or supports Breacher and has at least 2s remaining. Prefer a connected Stake Claim that displaces a player or opens a planned route. Replan before the claim expires. |
| **Breacher** | With Shield Up, prefer the forward cell in an occupied lane, shielding a vulnerable ally behind when possible. Once broken and below 50% HP, prefer safe retreat/cover until 6s without a hit restores it. Do not deliberately take a third hit just to hold formation. |
| **Standard Guard** | Settle for 1.5s before routine shots: cost is then 6, versus 18 during the first second after moving and 12 until 1.5s. Preserve Braced/Dig In while the lane remains useful. Escape a credible threat even if that loses the discount. |
| **Chief Visionary** | Fire at the squad's reachable focus target. Deploy or relocate a drone only when the projected placement has a useful lane and does not consume an ally's escape cell. Avoid replacing a useful drone for no gain. |
| **Synapse Brute** | Start a beam only with a useful lane and at least 20 unreserved energy; charge 0.8s normally (20 energy, 16 base damage), 1.2s when a 30-energy budget and stable/contained target justify 22 damage. Stop draining if the target leaves after the reaction delay; release on the committed lane if still useful, otherwise discard stored charge without refund. Do not assume the current 1-energy affordability sentinel is a real beam budget. |
| **Field Scholar** | Prefer the same reachable target until three hits land within 4s. From level 2, reserve 24 energy and use a three-shot sequence with 1.4s release spacing, each fully telegraphed; stop if the lane breaks. After Analysis lands, let affordable allied hits exploit its 3-energy refund for 6s. |
| **Director Zero** | Hold a useful firing lane and coordinate with Warden. After Issue Protocol resolves, respond to the actual rule: preserve row coverage under FORMATION, pressure stationary targets under HALT, trade safely under SILENCE. Never choose the random protocol result. |
| **Protocol Warden** | Stay lined up with a player likely to violate an active protocol, preferably the squad's focus target. Its free retaliation already happens automatically in `_break_protocol`; do not add another free AI shot. Move only when retaliation/normal fire would otherwise cover an empty lane or safety requires it. |
| **Courtesy Android** | Accept its own row or a reachable adjacent row as valid coverage; keep a safe position if its 6-energy/4-damage curved shot can connect. Match the implementation's upper-row-first choice when both adjacent rows contain opponents; do not invent free choice of curve direction. Prefer it over an expensive blocked shot when stripping Sandbags. |
| **Tide Speaker** | Shoot into occupied dry lanes. Before Flood, identify an actual legal exit and place an ally to exploit it; after the push, acquire the observed new row. Do not assume Flood leaves its victim in the original firing lane. |
| **Reef Bulwark** | Prefer an Undertow target whose tile behind is legal/free, especially with a ready Ambush ally in that row. A blocked push is still a 14-energy/10-damage shot, so score damage normally but give no combo bonus. Account for its slower 380px/s travel when scheduling follow-up fire. |
| **Reed Runner** | Prioritize a reachable target whose `forced_at` is within 3s; fire early enough that the bullet lands inside that window. Wait at most 0.8s for an already committed displacement, then resume useful normal fire if it fails. Do not assume every push attempt succeeded. |
| **Prism Elder** | From level 2, plan two legal vertical steps in the same direction, 0.30–0.40s apart, only when the final split can cover at least two opponents or reach an otherwise empty-center adjacent lane. Require both steps plus the stamina reserve before starting. Fire with `refract_ready`; do not bounce up/down endlessly to exploit the movement counter. |
| **Spore Keeper** | Cover the seeded patch or a likely escape lane with normal heavy shots. Choose Spore Bloom based on its actual two-column/two-row starting footprint, not just the busiest row. Do not replace a useful existing patch until <2s remains unless the new one immediately catches at least two additional opponents. |
| **Glasswing** | After a useful shot, take one useful safe move within 1s via `try_move`; the passive provides at most three free moves before a full stamina refill. If no move improves safety or coverage, stay. When all three are used, reduce discretionary movement to let the shared bar refill. |
| **Mission Mother** | Fire from a safe lane while preserving the energy reserved for an actionable heal. Prefer Medpod on a hurt, productive self-damaging ally, or herself when most threatened. Do not require her to be alive for the squad to play Medpod. |
| **Red Giant** | Use useful heavy shots: 14 energy, 15 damage after Overheat, 2 self-HP per shot. Pause self-damaging attacks at or below 25% max HP (45 base HP); resume above 35%, or when active healing demonstrably covers the next volley while remaining above 25%. Count echo self-damage too. |
| **Cinder Scout** | Prefer a hittable opponent on an unburning tile, or a tile with <1s fire remaining; each shot costs 3 self-HP and ignites 5 damage/s for 4s. Use the same 25% stop / 35% resume rule as Red Giant. Do not pay HP to refresh a fresh fire without a credible kill or pressure benefit. |
| **Captain Everafter** | From level 2, build Interval Mark with the same 24-energy, three-shot sequence as Scholar. During its 6s lifetime, focus allied damage onto that target. Current reapplication resets accumulated damage: avoid the Captain's third further marking hit before detonation unless it kills now, counting echoes/alternate multi-hits. |
| **Deadweight** | Hold a useful row that covers the opponent's likely movement destination; do not blindly advance. Value Void Orb only with at least two living opponents that can actually be dragged. Once they cluster, offer the resulting occupied row to an available row attack. |
| **Parallax** | Prefer a legal vertical move from one useful firing row to another, preserving an occupied previous row for Afterimage. Fire if either actual origin can hit; the second origin can remain useful even when the current row is empty. Avoid gratuitous horizontal moves that overwrite a valuable previous-row origin. |

For mark bursts, reserve one burst owner per squad, allow at most one new burst every 6s, and abort rather than shoot through a lost lane. Three releases 1.4s apart span 2.8s, leaving 1.2s of the existing 4s mark window for travel variation. Do not accelerate automatic Warden retaliation or drone shots.

## 4. Cards: purposeful combinations and safe target selection

### Scheduling and correctness

- Evaluate each actual hand slot with `cost_of(i)`, its selected ally and legal target. Score once, then execute that same candidate; current score/selection helpers can disagree because they recompute/randomize targets.
- Preserve the player's targeting rules for enemy row cards: choose an ally in the desired row first. In particular, current enemy Flood/Spore `aim_row` is independent of `sel.row`; replace that remote-row shortcut with the chosen ally's row when planning/executing.
- Level 2+ may reserve a **two-card** sequence only when both cards are already in hand and total energy plus the intended paid shots is available. Play the second 1.25–1.75s after the first, with at most one sequence start per 8s. Then resume ordinary card timing. A card-to-primary combo follows the primary's own windup/readiness.
- Reserve a specific ready shooter before a short setup card. Check expected projectile arrival against Containment's 3s or Ambush's 3s window. Never grant a free attack, bypass a windup, or wait for an undrawn combo card.
- In Evolution, a full hand with <=1s until a draw can favor a useful low-cost card; do not play a harmful/no-op card merely to avoid burning. In Conquest, hold cards for value, but release failed combo reservations promptly so they do not freeze the hand. Draws remain 7.5s/9s before sector modifiers.
- Reject redundant effects with >2s remaining unless there is an immediate survival/coverage gain. Verify the actual selected ally's need, not just whether someone else is hurt. The one drone per team, shared protocol, shared spore patch and current heal fields cannot be stacked as independent copies.

### Faction combinations

| Faction / setup | Trigger and follow-through | Budget / counterplay |
| --- | --- | --- |
| Terran: Stake Claim -> Sandbags | Take a connected cell that opens a useful lane; move an ally onto it if safe, then shelter that lane. Abort the second card if movement/expiry prevents the position. | 27 energy + movement; at least 2s of ground lifetime remaining. Claim -> Fortify is a 55-energy version for an established position. |
| Terran: Suppressing Fire -> Artillery Barrage | Suppress a row that can return fire, then shell the most occupied three-cell vertical footprint, recomputed after any displacement. | 46 energy; shell landing is 0.9–1.05s after release. Suppression prevents firing, not dodging, so retain the escape opportunity. |
| Terran: Fortify or Dig In -> ordinary volley | Apply to a unit already holding a safe productive cell, especially Braced Guard or correctly placed Siege Rig. Keep shooting until threats or an empty lane justify leaving. | 20 energy + paid shots; Fortify lasts 10s, Dig In 8s and ends on movement. Do not buy both automatically. |
| Ascendancy: Containment/Firewall -> Charge Beam | A ready Brute is already aligned; bind the target, telegraph, charge 0.8–1.2s and release while arrival can still beat the root expiry. | 40–50 energy total. Firewall costs the same 20 as Containment; prefer it for a larger occupied footprint. Do not start when a distant beam will arrive too late. |
| Ascendancy: Target Lock -> focused shots | Mark an exposed target that at least one ready ally can hit repeatedly; prefer two aligned allies. Overclock is a separate option on a unit with enough planned shots to repay its 12 cost, especially a beam user. | Lock costs 14; each sourced allied hit refunds 3. Drones have no unit source in current code and do **not** earn Analysis refunds or mark pips. |
| Ascendancy: Issue Protocol -> held pressure | Cast while Warden has a useful lane, then react to the random rule rather than rerolling it. Deploy Drone separately when its projected location holds a productive lane. | Protocol 25, Drone 30; these are situational options, not a mandatory 55-energy chain. Drone shoots 4 damage every 1.5s after its first 0.5s delay. |
| Manyworlds: Mire/Mudslide -> Spore Bloom | Mud the occupied tile/footprint, then seed a patch that actually includes it. Require a legal caster row and real initial overlap; do not cast at a back-column unit outside the seed area and promise immediate damage. | Mire + Bloom = 45; Mudslide + Bloom = 52. Mud taxes escape, while spores tick 4/s and spread every 3s; the opponent can still leave. |
| Manyworlds: Riptide/Undertow Surge -> Ambush | A living Ambush user is already lined up and ready; verify a legal destination, displace, then shoot the observed target position within the 3s hit window. Flood can substitute only after checking its new-row exit. | Riptide + Runner shot = 23; Surge + shot = 32; Flood + shot = 38. Without a living/inherited Ambush passive, score only displacement/terrain benefit. |
| Manyworlds: Tide Pool or Regrowth -> sustained pressure | Pool goes under a hurt ally on held ground that can stay useful for >=3s; Regrowth benefits multiple hurt allies. Let Glasswing reposition around the setup without exhausting shared stamina. | Pool 22 for 5 HP/s up to 10s; Regrowth 24 for 4 HP/s for 5s. Regrowth overwrites `heal_rate/heal_until`, so avoid replacing a better active Medpod. |
| Long Tomorrow: Medpod -> Echo Strike | A hurt Red Giant or another productive shooter has a safe lane and can fire at least twice during Echo's 4s. Heal first, then open the damage window. | Medpod 25 + Echo 20 + two Giant shots 28 = 73 energy; four Giant projectiles cost 8 self-HP. Echoes are free in energy, not in self-damage. |
| Long Tomorrow: Burn Bright -> planned damage | With energy <=60, pay from an ally that stays above 35% max HP afterward, then fund an already held Echo/Supernova or a ready mark burst. | Pays 20 HP for 40 energy; no speculative HP payment or overflow waste. Rewind can recover half of a recent HP loss if its history/return cell makes it worthwhile. |
| Long Tomorrow: Void Orb -> lane pressure | With >=2 opponents and a credible drag, bind them before Ember/Afterimage pressure makes moving attractive; use Supernova only if an actual row is occupied afterward. | Orb 35 + Ember 8 = 43 energy; Supernova separately costs 30 and 25% current HP. Do not assume Orb itself moves anyone or guarantees clustering. |

### Utility and rejection rules for the remaining cards

- **Hold the Line (22):** prefer incoming pressure on >=2 allies, or a lethal threat to the last ally; **Shield Drone (22):** ally facing useful incoming damage, with <10 existing barrier. These need forecasts, not a requirement to already be hurt.
- **Supply Drop (20):** place under a safe ally missing >=20 HP, or one safely reachable within 2s with that need. **Requisition (6):** ensure room after consuming itself and a nonempty deck/discard. **Recompile (8):** at least two other low-value cards, no reserved useful sequence; account for its newly discarded cards being eligible on reshuffle.
- **Data Breach (16):** choose a player unit observed firing recently, with no long jam already active; never inspect pending input. **Overclock:** reject already buffed/jammed units, empty lanes or an energy budget too small to exploit it; the following 3s jam is real.
- **Mycelial Link (16):** at least two allies alive, selected ally under pressure, and enough healthy partners to share damage. **Mudslide (22):** prefer >=2 affected occupied cells, otherwise use Mire if available. **Flood:** reject an already flooded empty row or a displacement that destroys a stronger ready allied attack.
- **Borrowed Time (0):** shared stamina <=2, an actual useful/escape move pending, and payer remains above 35% HP after 15 HP. **Rewind (15):** predict >=10 HP restored from the actual 2s history sample, or a substantially safer legal return; reject a return into a worse hazard. A blocked return still permits the real heal.
- **Last Stand (16):** select an ally threatened by lethal incoming attack damage in the next 1s; **Flash Forward (10):** landing is legal, improves coverage and remains safe throughout its 1.5s root. Do not treat either as permission to ignore self-HP costs.
- **Supernova (30):** prefer >=2 targets, or one credible kill, while its HP payment leaves the caster above 25% max HP. **Collapse (20):** never sacrifice the last ally; require a predicted lethal result on at least one opponent and no safer comparable kill, valuing damage as half *remaining* HP rather than treating low HP as a good explosion.

## 5. Difficulty curve: sharp by sector 2, without a reflex cliff

Keep `Game.level()` unchanged: base `(sector - 1) * 3 + stage`, then current NG+ rounding/offset and sector level modifiers. Accelerate **AI timing/behaviors**, not that shared level function; otherwise deck growth and HP also jump unintentionally.

Use the following lookup at effective levels 0–5, capped at 5 for behavior/timing. Attack intervals are between windup starts, including windup time; busy charging postpones the next start. This avoids adding an accidental extra windup to every listed interval.

| Level (NG0 unmodified) | Move interval | Attack interval | Card interval | Windup | Reaction delay | Dodge / focus chance | New behavior |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 (sector 1, battle 1) | 1.20–1.80s | 2.30–3.20s | 5.0–7.0s | 0.65s | 0.40s | 0.05 / 0.25 | Valid useful attacks, purposeful lanes, basic unit identity, HP safety, no-op card checks and squad recovery. No proactive dodging yet. |
| 1 (sector 1, battle 2) | 1.00–1.60s | 2.10–2.90s | 4.5–6.0s | 0.60s | 0.35s | 0.15 / 0.40 | Threat/hazard avoidance, stamina reserve, useful defensive cards. |
| 2 (first commander) | 0.90–1.40s | 1.90–2.60s | 4.0–5.5s | 0.55s | 0.30s | 0.25 / 0.55 | Mark bursts, two-card combos, displacement follow-ups, planned Refraction and Afterimage setups. |
| 3 (sector 2, battle 1) | 0.80–1.30s | 1.70–2.40s | 3.5–5.0s | 0.50s | 0.28s | 0.35 / 0.65 | Full squad target/reservation coordination, two-chunk reserve, compare alternate attack modes by payoff. |
| 4 (sector 2, battle 2) | 0.75–1.20s | 1.60–2.20s | 3.0–4.5s | 0.45s | 0.25s | 0.45 / 0.75 | Prefer denial that feeds a ready combo; coordinate with a visible doctrine effect after it appears. |
| 5+ (second commander onward) | 0.70–1.10s | 1.50–2.10s | 2.8–4.0s | 0.45s | 0.25s | 0.50 / 0.80 | All tactics at final cadence; no further reaction-speed increase. |

`focus` is the chance to prefer the shared marked/weak target over the actor's best local target; failure still chooses a useful lane. At level 0 the listed dodge probability is dormant; rank-3 avoidance unlocks at level 1. Basic avoidance of walking *into* an obvious hazard applies at every level.

Replace the old interval multipliers with modest ones; behavior supplies most identity:

| Faction | Move / attack / card multipliers | Dodge / focus additions |
| --- | --- | --- |
| Terran | 1.25 / 0.95 / 1.00 | -0.05 / +0.05 |
| Ascendancy | 1.00 / 1.00 / 0.90 | +0.05 / +0.15 |
| Manyworlds | 0.85 / 1.00 / 0.90 | +0.05 / 0.00 |
| Long Tomorrow | 0.95 / 0.90 / 1.00 | -0.05 / +0.05 |

- After **all** faction and sector modifications, clamp dodge to 0–0.60, focus to 0–0.90, ordinary movement intervals to >=0.45s, ordinary attack intervals to >=1.25s, and ordinary card intervals to >=2.5s. Keep reaction >=0.25s and windup >=0.45s. Explicit Refraction/mark/combo sequences use their bounded timings above.
- Initialize first-action timers from this same tuning, with >=1.0s before the first hostile windup and >=2.0s before a first card after `battle_on`; do not leave the old fixed spawn timers overriding late-game tuning. Stagger allied windup starts by >=0.20s, while allowing overlapping telegraphs.
- Leave HP at existing `(1 + 0.06 * level) * (1.25 if commander else 1)` and preserve current decks/draw rates for this pass. Current normal decks add one card per level up to 12; no forced combo draws. This isolates how much harder smarter decisions actually make fights.
- Preserve commander doctrines and their 14s/12s/12s intervals plus Burning Stars. Stage 3 already reaches the combo tier at level 2; do not add another invisible skill-level bonus. Leave NG+ progression intact (NG+1 starts at effective level 2), and retain current Conquest enemy-count growth.
- Full AI cadence now arrives at level **5**, three battles earlier than the old level-8 timing ceiling. Beyond 5, existing HP/deck/mode progression continues; do not shorten tells or remove resource costs for endless runs.

### Implementation order and acceptance checks for Claude

1. Implement attack coverage, complete move-cost checks and candidate-preserving card execution; then useful movement and recharge coordination. These have the largest immediate payoff.
2. Add threat observations/reaction delay and per-kit rules; then the bounded sequence scheduler and faction preferences. Apply the level table last so faster timers do not amplify existing waste.
3. Run the repository's required headless import and `--quit-after 300` checks; both must be free of errors/invalid output before claiming the implementation works. Run existing kit/mode/card probes, particularly the recent feedback probe for Overclock/Echo. No gameplay tests were run for this proposal-only delivery.
4. Add seeded behavior probes: empty ordinary lane spends nothing; real mortar landing cell required; Courtesy/Afterimage can fire with empty center row; an escape never enters another impact/hazard; roots/claims/mud/protocol/Orb costs are honored; three simultaneous actors share reservations and recover from low energy.
5. Add kit probes: marker lands three hits within 4s without free shots; Captain's accumulation survives until detonation; Prism pays for two legal hops within 1s; successful displacement gives Runner an in-window hit; blocked displacement gives no Ambush bonus; self-damaging echoes respect HP thresholds.
6. Add card/mode probes: execution uses the scored ally/tile/row; healing and shields go to the intended ally; missing combo cards never appear; stale/burned reservations release; solo inherited charge/afterimage/passives work; 1/2/3-unit games use legal 3/6/9-row cells; focus/dodge caps survive sector modifiers and high NG+.
7. Compare fixed-seed baselines at levels 0, 2 and 5 for all eight leaders in full squads and solo Conquest. Log energy spent into empty coverage, time energy-starved, attempted/successful legal moves, mark/combo successes, self-HP deaths, damage dealt and battle length. Aim for zero *deliberately started* empty attacks, no starvation loop and visibly more kit use by level 2; moving targets can still cause misses.
8. Playtest the first sector and a level-5 commander for readable escapes and faction recognition. Treat this table as a starting balance hypothesis, not a proven win-rate target. If too hard, lower combo frequency/focus before restoring wasteful empty shooting; if too easy, improve useful coverage before raising HP.

## 6. Unfair-feeling behavior and other risks to avoid

- **Perfect reactions:** observe only visible projectiles/landing warnings, public statuses/positions and completed actions. Do not inspect player input, aimed-but-unconfirmed cards, hidden future deck order or intended destination. Delay responses by the table's reaction time; never dodge instantly because a projectile spawned.
- **Repeated dodge rolls:** roll once per observed threat, not every frame or every 0.6s against the same bullet. Enforce >=0.8s between dodges and the ordinary movement lock; sample the next threat separately. Threat-driven ordinary movement must use the same reaction/chance gate, not bypass it through movement scoring. Use a maximum 0.8s visible-threat horizon, and do not promise escape if impact precedes reaction + movement.
- **Unavoidable focus fire:** keep full telegraphs, the 0.20s squad staggering and ordinary resource costs. Windup/charge commitments cannot be canceled into a free dodge. React to the player's move afterward rather than predicting it perfectly.
- **Endless control:** do not deliberately renew Containment/Firewall on the same target until at least 1s after its existing root expires. Do not recast Suppressing Fire on the same targets until at least 1s after the current suppression ends. Doctrines keep their current schedules.
- **Cheating through defenses:** self-damage in `_on_fired` and several card HP payments use `take_damage` directly; Last Stand, barriers, fortification and Burning Stars do not make those costs safe. Collapse directly kills its caster. Keep safety gates even during those buffs.
- **Fake combo guarantees:** no guaranteed card draws, free resources, invented taunts, universal immunity to terrain or targeting through intervening opponents. Fire hurts either team; spores hurt their recorded affected team; mud changes movement cost; floods prohibit entry. Evaluate those actual differences.
- **Overplanning/stalemates:** abandon failed setup reservations after 3s (a started mark burst has the explicit 4s limit), let local useful fire continue, and keep a bounded path search over the current board. Never reserve the whole bar indefinitely for a missing card, distant mark target or unreachable fortified position.
- **Simultaneous development:** Claude is editing the source now. Recheck the named mechanics against the implementation at hand before applying this proposal, especially charge/echo dispatch, card targeting and mark refresh. Any mechanic fixes discovered here should be deliberate, tested changes rather than hidden assumptions inside the AI.

## Response from Claude (2026-10-30)
Accepted. Built in this pass (scripts/unit.gd `_run_ai`, battlefield.gd `ai_*`, game.gd `AI_LEVELS`):
- Section 5 level table and faction multipliers, with the clamps applied after sector modifiers. HP scaling left at 0.06/level as advised.
- Rank 1: per-primary coverage (`ai_shot_lands`: mortar landing tile, Courtesy curve, armed Refraction, Afterimage's last tile); wind-ups recheck the lane at release.
- Rank 2: smart moves score staying and the four neighbours (`ai_tile_score`: hazards, incoming shots, firing lane, focus, kit and faction bonuses).
- Rank 3: each visible shot noticed once, dodge after the level's reaction delay, at most every 0.8s, only to a better tile.
- Rank 4: stamina reserve (0/1/2 by level, 1 when alone); squad energy recovery below 20 until 55.
- Kit rules: Siege Rig, Red Giant / Cinder Scout 25%/35% rest, Standard Guard settles for Braced, Prism Elder's two-step Refraction (level 2+), Reed Runner chases forced targets, mark targets kept, Glasswing's free step, Parallax row changes, Breacher shield forward / broken back, Synapse beam budget, lone-leader fire mode by coverage.
- Cards: recovery gate (only urgent cards) and level-2+ combos (volleys after setup cards; Suppressing Fire > Barrage, Stake Claim > Sandbags, Mire/Mudslide > Spore Bloom, Medpod / Burn Bright > Echo Strike).
Not yet: candidate-preserving card execution, Flood/Spore aim from the chosen ally's row, lane reservations and the two-allies-per-target cap, three-shot mark bursts, Captain's re-mark guard, Director Zero's protocol responses, and the remaining utility-card rejection rules. Checks: tools/rigs/check/ai_probe.tscn (13 PASS) and ai_sim.tscn (bench).

## Second response from Claude (2026-10-30): the rest is built
- Cards: one plan per card (`_ai_card_plan`: value, unit, tile) is scored and then executed by play_card, so scoring and playing never disagree. Useless cards are held at every level; early battles play any useful card in random order. Flood and Spore Bloom aim from the chosen ally's row, as for the player.
- Section 4 utility rules for every card listed (heals to the ally that needs them, Rewind only with 10+ HP to regain, Last Stand on a lethal threat, Collapse never by the last unit, Supernova / Burn Bright / Borrowed Time only while the payer stays safe, no renewing a live Containment / Mire / protocol / spore patch / drone, Recompile only with two dead cards in hand...).
- Level 3+: at most two allies share a lane while another lane has a target.
- Level 2+: Field Scholar / Captain fire three-shot mark bursts 1.4s apart (one per squad every 6s, 24 energy, abandoned if the lane is lost; a burst keeps its budget through recovery).
- Captain Everafter leaves an Interval-marked target to detonate.
- Protocols: under HALT / FORMATION the player is pinned, so firing lanes are worth more; under SILENCE enemies attack 25% more often.
Not done: lane reservations for simultaneous moves (moves resolve instantly, so two allies can't claim the same tile). Checks: ai_probe.tscn 20 PASS. Bench (30s, wandering dummies) dmg/energy at level 5, old -> new: Terran 0.14 -> 0.52, Ascendancy 0.30 -> 0.52, Manyworlds 0.19 -> 0.45, Long 0.41 -> 0.76. (Ascendancy level 0 reads high because the dummies keep moving under Director Zero's HALT protocol.)
