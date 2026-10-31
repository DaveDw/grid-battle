Author: Claude
Status: accepted and built (Codex: rules + 26 cards; Claude: 14 board cards + AI plans), 2026-10-30
Touches: cards | balance | UI

# Card set 2: 40 new cards and game-wide card rules

10 new cards per faction, each split 4 Common / 3 Uncommon / 2 Rare / 1 Legendary, so no
faction or rarity is favoured. Revised with David's notes (2026-10-30).

## Game-wide rules (also change existing cards)

| Rule | How it works | Existing cards it changes |
| --- | --- | --- |
| Lasting board cards are numbered | A card that changes the board until it is played again carries a mark per copy: MK I, MK II, MK III... Each copy's effect stays until that copy is played again (which moves it). The mark shows on the card and on the board. | Deploy Drone: lasts until that copy is replayed; one drone per copy. **Cost 30 -> 40** (David). |
| Moving your own unit breaks locks | Cards that move your own unit free it from Containment, Firewall, roots, Event Horizon, Razor Wire and mud, and ignore them for the move. | Flash Forward; new Wave Rider, Phase Shift. |
| Pure draw cards speed the draw timer | A card that only draws also makes draws come 50% faster for 6 s. | Requisition, Recompile; new Spare Parts. |
| Alternate fire cooldown | A lone leader's alternate shot (E / R1) has a 1.5 s cooldown, shown on the button. | Every lone-leader alternate weapon. |
| Blocked pushes hurt | A unit pushed or pulled with nowhere to go takes 8 damage and is stunned 0.5 s (no moving or shooting). | Undertow, Undertow Surge, Riptide, Flood, Claim and Stake Claim push-backs. |

## Terran Partition Authority

| Rarity | Card | Cost | Target | Effect |
| --- | --- | --- | --- | --- |
| Common | Quick March | 12 | none | Your squad refills 2 stamina chunks. |
| Common | Field Repairs | 14 | unit | Heals 15 HP, plus 10 more if it hasn't moved for 2 s. |
| Common | Spotter Flare | 10 | tile | The enemy on the tile takes +25% damage for 4 s. |
| Common | Razor Wire | 14 | tile | Wire for 8 s: an enemy entering takes 10 and loses a stamina chunk. |
| Uncommon | Creeping Barrage | 26 | tile | Shells walk down the tile's column, one tile every 0.3 s, 10 each. |
| Uncommon | Overwatch | 18 | unit | 5 s: a free shot at each enemy that steps into its row (max 3). |
| Uncommon | Smoke Screen | 16 | unit | 4 s: enemy shots in the unit's row deal 50% less. |
| Rare | Volley Fire | 26 | none | Every living ally fires its primary at once, free. |
| Rare | Annex (MK) | 28 | tile | Claim an enemy tile touching your ground until this copy is played again (which moves it). Reverts if cut off. |
| Legendary | Orbital Strike | 40 | tile | After a 1.5 s marked warning: 45 to the tile, 15 to each neighbour. |

## Ascendancy League

| Rarity | Card | Cost | Target | Effect |
| --- | --- | --- | --- | --- |
| Common | Calibrate | 10 | unit | The unit's next 3 shots deal +3. |
| Common | Efficiency Pass | 10 | none | Each ally's next shot costs nothing. |
| Common | Pulse Mine | 12 | tile | Mine for 10 s: 15 to the first enemy that steps on it. |
| Common | Holo Decoy | 12 | your tile | A decoy for 6 s: blocks one enemy shot in its row and draws AI fire. |
| Uncommon | Signal Jam | 16 | none | The enemy can't play cards for 5 s. |
| Uncommon | Mirror Shield | 20 | unit | 5 s: the next shot that hits it is reflected back down the row. |
| Uncommon | Phase Shift | 14 | unit | Swaps the unit with, in priority: your active Holo Decoy, your least recently moved drone, the ally you last controlled. Breaks locks. |
| Rare | Neural Link | 22 | unit | 6 s: every hit from the unit lands a full mark. |
| Rare | Quarantine | 28 | tile | Containment on a 2x2 enemy area for 3 s. |
| Legendary | Perfect Model | 36 | none | 6 s: your squad's shots curve into the nearest enemy row and deal +4. |

## Manyworlds Resistance

| Rarity | Card | Cost | Target | Effect |
| --- | --- | --- | --- | --- |
| Common | Wave Rider | 8 | unit | Moves up to 2 rows up or down, free. Breaks locks and ignores them for the move. |
| Common | Brine Splash | 12 | unit | Pushes the first enemy in the row up or down a row (forced; blocked-push penalty). |
| Common | Thornvine | 14 | tile | Thorns for 6 s: 4 damage per second to an enemy standing there. |
| Common | Sap Poultice | 10 | unit | Heals 12 HP over 3 s and clears fire or spores from its tile. |
| Uncommon | Maelstrom | 24 | tile | Whirlpool for 4 s: each second, every enemy next to it is pulled one tile closer (forced). |
| Uncommon | Pollen Cloud | 18 | tile | The tile and those above and below: enemies there deal 30% less, 5 s. |
| Uncommon | Barnacle Shell | 18 | unit | A 10 HP barrier that grows 3 per second for 5 s. |
| Rare | Tsunami | 32 | none | Every enemy is pushed back a column (blocked-push penalty if it can't move). |
| Rare | Overgrowth | 28 | tile | A spore patch whose starting tiles also root enemies for 2 s. |
| Legendary | Worldshaper | 40 | none | 8 s: the enemy's back column floods; anyone on it is pushed forward (forced; blocked-push penalty). |

## The Long Tomorrow

| Rarity | Card | Cost | Target | Effect |
| --- | --- | --- | --- | --- |
| Common | Spare Parts | 0 | unit | The unit pays 10 HP: draw a card; draws come 50% faster for 6 s. |
| Common | Slow Burn | 12 | tile | Sets an enemy tile on fire for 6 s. |
| Common | Afterglow | 10 | unit | 6 s: the unit heals 3 HP for every shot it fires. |
| Common | Lifeline | 10 | unit | 6 s: no single hit can deal the unit more than 15. |
| Uncommon | Red Shift | 18 | unit | 6 s: the unit's shots fly 50% faster and deal +3. |
| Uncommon | Cinder Trail | 20 | unit | 6 s: every enemy the unit hits has its tile set on fire. |
| Uncommon | Event Horizon | 22 | tile | 4 s: the enemy on the tile can't move; any enemy that steps next to it is caught too until it ends. |
| Rare | Second Wind | 0 | unit | A unit under 30% HP heals to 50%; it can't be healed again for 15 s. |
| Rare | Time Debt | 20 | none | 4 s: stamina and energy refill twice as fast, then 3 s of no refill. |
| Legendary | Heat Death | 36 | none | Every unit on the board loses 20% of its current HP; your squad gains energy equal to half the damage dealt to enemies. |

## Open
- Ascendancy and Manyworlds have one fewer existing draftable card than Terran and Long Tomorrow; add one each if the whole set goes in.
