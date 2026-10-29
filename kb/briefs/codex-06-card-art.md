For: Codex
From: Claude
Output: art_incoming/cards/<card_id>.png (one per card), log in art_incoming/cards/progress.txt

# Brief: simple pixel art for every card (38 cards)

The user wants a pixel-art picture on every card, and wants it **pretty simple**: an icon you read in half a second, not an illustration.

## Format
- Draw on a **32x32 pixel canvas**, then export scaled up 4x with nearest-neighbour to **128x128 PNG**. Every art pixel becomes an exact 4x4 block: no smoothing, no in-between sizes.
- **Transparent background.** The card frame and faction colour come from the game.
- File name is the card id exactly: `art_incoming/cards/stake_claim.png`.

## Style rules (keep it simple)
- **One subject**, centred, filling about 70% of the canvas: a sandbag wall, a flag on a tile, a drone, a wave, a clock, a skull, and so on. No scenes, no characters' faces, no text or numbers.
- **4-6 colours plus a dark outline.** A 1 px dark outline (#14161f or a dark shade of the main colour) around the subject so it reads on any card background.
- Light from the top-left: one highlight shade and one shadow shade per colour, no gradients or dithering.
- **Faction accents** so a hand of cards reads at a glance:
  - Terran: orange #e8742a + gunmetal grey.
  - Ascendancy: cyan #38d6e8 + white/silver.
  - Manyworlds: teal-green #3fbf8a + purple #8a5cd6.
  - Long Tomorrow: red-orange #e04a3a + gold #e8b84a, a touch of void purple.
- Same weight and outline style across all 38 so they look like one set.
- Check each one at 32x32 (actual size): if the subject isn't obvious, simplify.

## Work order
Do one faction at a time (about 10 cards), then stop for review, the same way as the idle pairs. Order: terran, ascendancy, manyworlds, long. After each faction, append `cards <faction> done` to `art_incoming/cards/progress.txt` and reply `cards done: <faction>`.

Also save a contact sheet per faction at `art_incoming/cards/review_<faction>.png`: every card of that faction at 1x (32 px) and at 4x, with its id under it.

## The cards
Format: `id` | name | faction | cost | what it does (use this for the subject).

- `fortify` | Fortify | terran | 20 energy | Selected unit's tile takes half damage, 10s.
- `claim` | Claim | terran | 35 energy | Take the enemy front column for 10s.
- `deploy_drone` | Deploy Drone | ascendancy | 30 energy | Drone in front of the unit; fires down its row.
- `issue_protocol` | Issue Protocol | ascendancy | 25 energy | Enemy rule for 6s: HALT, SILENCE or FORMATION.
- `flood` | Flood | manyworlds | 30 energy | Flood your row on the enemy side for 6s.
- `spore_bloom` | Spore Bloom | manyworlds | 30 energy | Spreading spores on the enemy side, 9s.
- `medpod` | Medpod Tether | long | 25 energy | Selected unit heals 6 HP/s for 8s.
- `void_orb` | Void Orb | long | 35 energy | Enemies drag each other on every move, 8s.
- `stake_claim` | Stake Claim | terran | 15 energy | Take an enemy tile for 7s; walkable if it joins your ground.
- `sandbags` | Sandbags | terran | 12 energy | Barricade in front of the unit stops 2 shots, 8s.
- `overclock` | Overclock | ascendancy | 10 energy | Half-cost shots for 5s, then jammed for 2s.
- `containment` | Containment Field | ascendancy | 20 energy | An enemy on the tile can't move for 3s.
- `riptide` | Riptide | manyworlds | 15 energy | Pull the nearest enemy in your row 1 column closer.
- `mire` | Mire | manyworlds | 15 energy | Mud tile for 8s: leaving it costs 2 stamina.
- `borrowed_time` | Borrowed Time | long | 0 energy | Selected unit pays 15 HP to refill 2 stamina.
- `rewind` | Rewind | long | 15 energy | Snap back 2s in time and regain half the HP lost.
- `barrage` | Artillery Barrage | terran | 28 energy | Shells hit the tile and the tiles above and below: 14 each.
- `hold_the_line` | Hold the Line | terran | 22 energy | Your squad takes 30% less damage for 5s.
- `requisition` | Requisition | terran | 6 energy | Draw a card now.
- `target_lock` | Target Lock | ascendancy | 14 energy | Analyze the enemy on the tile (hits on it refund energy).
- `shield_drone` | Shield Drone | ascendancy | 22 energy | Selected unit gets a 30 HP barrier for 10s.
- `recompile` | Recompile | ascendancy | 8 energy | Discard your hand and draw 3 fresh cards.
- `undertow_surge` | Undertow Surge | manyworlds | 24 energy | Push every enemy in your row back one column.
- `regrowth` | Regrowth | manyworlds | 24 energy | Your squad heals 4 HP/s for 5s.
- `mudslide` | Mudslide | manyworlds | 22 energy | Mud on the tile and the tiles above and below, 8s.
- `last_stand` | Last Stand | long | 16 energy | Selected unit can't drop below 1 HP for 4s.
- `burn_bright` | Burn Bright | long | 0 energy | Selected unit pays 20 HP: gain 40 energy.
- `echo_strike` | Echo Strike | long | 18 energy | Selected unit fires its primary twice, free.
- `suppressing_fire` | Suppressing Fire | terran | 18 energy | Enemies in the selected unit's row can't fire for 3s.
- `firewall` | Firewall | ascendancy | 20 energy | Containment on the tile and the tiles above and below, 3s.
- `mycelial_link` | Mycelial Link | manyworlds | 16 energy | For 6s, damage to the selected unit is split across your squad.
- `supernova` | Supernova | long | 30 energy | Selected unit pays 25% of its HP: 30 damage to every enemy in its row.
- `supply_drop` | Supply Drop | terran | 20 energy | Crate on your ground, 10s. First ally to reach it: +20 HP, +15 energy.
- `dig_in` | Dig In | terran | 20 energy | 8s: takes 40% less damage, deals 25% more. Moving ends it.
- `data_breach` | Data Breach | ascendancy | 16 energy | The enemy on the tile pays double energy for its shots, 6s.
- `tide_pool` | Tide Pool | manyworlds | 22 energy | Pool on your ground, 10s: your units standing in it heal 5 HP/s.
- `flash_forward` | Flash Forward | long | 10 energy | Leap up to 2 tiles forward, free. Then the unit can't move for 1.5s.
- `collapse` | Collapse | long | 20 energy | The unit falls; every enemy in its row takes half its remaining HP.

## Subject ideas (suggestions only, simpler is better)
- stake_claim: a small flag planted in a square tile. claim: a flag over a column of tiles. fortify: a shield on a tile. sandbags: a stacked sandbag wall. barrage: three falling shells. hold_the_line: a row of shields. requisition: a supply crate with an arrow. suppressing_fire: bullet streaks. supply_drop: a crate on a parachute. dig_in: a shovel in dirt.
- overclock: a gauge needle in the red. containment: a cyan cage/hex field. deploy_drone: a small drone. issue_protocol: a stamped document/command chevron. target_lock: crosshair. shield_drone: a drone with a shield arc. recompile: a circular arrow over cards. firewall: a wall of cyan hexes. data_breach: a broken padlock.
- riptide: a curling wave with an arrow. mire: a mud puddle with bubbles. flood: rising water lines. spore_bloom: a puffball releasing spores. undertow_surge: wave pushing right. regrowth: a sprouting leaf. mudslide: mud pouring. mycelial_link: three nodes linked by roots. tide_pool: a small pool with ripples.
- borrowed_time: an hourglass with a heart. rewind: a clock with a back arrow. medpod: a med capsule with a cross. void_orb: a dark purple orb. last_stand: a cracked shield still standing. burn_bright: a flame. echo_strike: a doubled bolt. supernova: a bursting star. flash_forward: a clock with a forward arrow. collapse: a falling star/imploding ring.

## Status (2026-10-29)
Done by Claude instead: the user preferred Claude's flat icons. All 38 cards are drawn with art_incoming/claude/cards/ (cardkit.py + build_terran/ascendancy/manyworlds/long.py) and imported to assets/cards/. Codex's Terran and Ascendancy originals stay in art_incoming/cards/ as a backup.
