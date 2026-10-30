# Grid Battle — design

Status: **built (first pass, numbers untuned).** Lines marked **\[you\]** are your calls; lines marked **\[proposal\]** are mine and need a yes/no. Numbers are first-pass placeholders for tuning.

## Universal rules

- **Three ability types**
    - **Primary fire**: what Z does while that unit is selected. Most units use the standard shot; a few have their own.
    - **Passive**: always on while that unit is alive.
    - **Card**: drawn from the deck and played. It acts on the currently selected unit, or on the tile(s) it targets.
- **Each squad gets** 1–2 passives and 1–2 special cards, plus up to one unique primary fire. **\[you\]**
- **Cards outlive their unit.** Picking a leader puts all three units' cards into the deck. If a unit dies, its cards stay in the deck and can still be drawn and played. So a squad never loses an ability outright; the passive and primary fire are what die with the unit. **\[you\]**
- **Marks and tags: three hits within 4 seconds.** Every mark or tag is applied the same way: the marking unit lands 3 hits on the same target within 4 s. What the mark does depends on who applied it. Marks last 6 s. **\[you, window and duration are proposals\]**
- **Marks show a 3-pip counter** over the target as the hits land. **\[you\]**
- **Standard shot by role.** Units without a unique primary fire shoot standard bullets. Lights and leaders pay less per shot; leaders and heavies hit harder. **\[you; numbers are proposals\]**

  | Role | Energy per shot | Damage |
  | --- | --- | --- |
  | Light | 8 | 5 |
  | Leader | 8 | 8 |
  | Heavy | 14 | 10 |
- **Enemies play by the same rules.** Enemy squads should spend stamina and energy like the player does. Otherwise effects like Void Orb, which cost the enemy stamina, do nothing against AI squads. **\[proposal\]**

---

## Terran Partition Authority

### Banner Marshal + Siege Rig + Pathfinder — "Hold the Line"

| Unit | Type | Ability |
| --- | --- | --- |
| Banner Marshal | **Card** | **Fortify**: the selected unit's tile is fortified for 10 s; any unit standing on it takes half damage. **\[you\]** |
| Siege Rig | **Primary fire** | **Mortar**: shells are lobbed up off the top of the screen and come down 3 columns ahead, so from your back row they land on the enemy's front row. They don't travel in a straight line, so they're hard to track. A faint shadow appears on the target tile just before impact. **\[you; shadow is a proposal\]** |
| Pathfinder | **Passive** | **Steady Aim**: 3 hits in a row without a miss refunds 1 stamina chunk. **\[you suggested energy or stamina; I'd pick stamina, since it suits a scout who repositions\]** |

### Claim Lord + Breacher + Standard Guard — "Take the Ground"

| Unit | Type | Ability |
| --- | --- | --- |
| Claim Lord | **Card** | **Claim**: for 10 s you take the enemy's front column and can move onto it. Enemy units standing there are pushed back to the nearest free tile. **\[you; the push-back is a proposal\]** |
| Breacher | **Passive** | **Shield Up**: the first 2 hits each take half damage. Taking more than 2 hits within 3 s drops the shield, and every hit is full damage until the shield comes back after 6 s with no hits. **\[you; the 3 s and 6 s are proposals\]** |
| Standard Guard | **Passive** (modifies primary fire) | **Braced**: shots cost less energy after standing still for 1.5 s (6 instead of 12), and more if he moved in the last 2 s (18). **\[you\]** |

## Ascendancy League

### Chief Visionary + Synapse Brute + Field Scholar — "Run the Experiment"

| Unit | Type | Ability |
| --- | --- | --- |
| Chief Visionary | **Card** | **Deploy Drone**: places one drone on a free tile on your side. It fires down its row every 1.5 s. Only one drone at a time; playing the card again moves it. **\[you\]** |
| Field Scholar | **Passive** | **Analysis**: marks a target using the three-hit rule. Your squad's hits on a marked target refund 3 energy each. **\[you for the mark; the energy-refund effect is a proposal, since Captain Everafter's mark already does burst damage\]** |
| Synapse Brute | **Primary fire** | **Charge Beam**: hold Z to pour in energy (25/s). Releasing fires one large projectile whose damage and size scale with the energy spent. **\[you\]** |

### Director Zero + Protocol Warden + Courtesy Android — "Execute Protocol"  *(needs your input)*

**\[proposal — you: "interesting but complicated, we can test it out"\]** Identity: **rules the enemy has to choose to obey or break.** Director Zero imposes a rule. Breaking it is allowed, but it's punished, so the opponent has to play around it.

| Unit | Type | Ability |
| --- | --- | --- |
| Director Zero | **Card** | **Issue Protocol**: imposes one rule on the enemy squad for 6 s, chosen at random: **HALT** (each move costs them 10 HP), **SILENCE** (each shot costs them 10 HP), or **FORMATION** (they can't change rows). |
| Protocol Warden | **Passive** | **Enforcer**: whenever an enemy breaks a protocol, the Warden fires a free automatic retaliation shot down its row, even if it isn't the selected unit. **\[you\]** |
| Courtesy Android | **Primary fire** | **Courtesy Round**: cheap (6 energy) and low damage, and the shot curves into an adjacent row if there's no target in its own row. It's reliable chip damage. |

## Manyworlds Resistance

### Tide Speaker + Reef Bulwark + Reed Runner — "Call the Tide" (controls where enemies can stand)

| Unit | Type | Ability |
| --- | --- | --- |
| Tide Speaker | **Card** | **Flood**: floods one enemy row for 6 s. Enemies in it are pushed out to the nearest dry row and can't enter it while it's flooded. **\[you: leader ability as a card\]** |
| Reef Bulwark | **Primary fire** | **Undertow**: a slow, heavy shot that knocks the enemy it hits back one column, if the tile behind it is free. The enemy can walk straight back, but that costs them stamina, and the knockback counts as forced movement, which sets up Reed Runner's Ambush. **\[proposal, replaces Coral Shot, which you found too strong\]** |
| Reed Runner | **Passive** | **Ambush**: +50% damage against enemies that were moved by force in the last 3 s. **\[proposal\]** |

### Prism Elder + Spore Keeper + Glasswing — "Refract the Fight"

| Unit | Type | Ability |
| --- | --- | --- |
| Prism Elder | **Primary fire** | **Refraction**: after travelling up or down 2 or more rows in 1 second, the next shot splits in three: one keeps going straight and two angle off diagonally into the neighbouring rows. **\[proposal\]** |
| Spore Keeper | **Card** | **Spore Bloom**: seeds a 2×2 enemy area. Units standing in it take damage every second, and the patch spreads one tile every 3 s for 9 s. **\[proposal\]** |
| Glasswing | **Passive** | **Hit and Run**: the first move within 1 s of firing costs no stamina up to 3 times per complete stamina refill **\[proposal\]** |

## The Long Tomorrow

### Mission Mother + Red Giant + Cinder Scout — "Keep Them Alive"

| Unit | Type | Ability |
| --- | --- | --- |
| Mission Mother | **Card** | **Medpod Tether**: tethers a medpod to the selected unit, healing it 6 HP/s for 8 s. It stays in the deck after she dies, so the self-damaging crew can still be healed. **\[you: card survives her death; heal numbers are proposals\]** |
| Red Giant | **Passive** | **Overheat**: deals +50% damage, but takes 2 damage for every shot it fires. **\[proposal\]** |
| Cinder Scout | **Primary fire** | **Ember Shot**: sets the tile under an enemy it hits on fire for 4 s, damaging anyone standing there. Costs the Scout 3 HP per shot. **\[proposal; reworked from "burning tiles behind him", which would only ever burn your own side\]** |

### Captain Everafter + Deadweight + Parallax — "Never Turn Back"

| Unit | Type | Ability |
| --- | --- | --- |
| Deadweight | **Card** | **Void Orb**: for 8 s the enemy squad is gravity-bound. When they move one unit, the others are dragged along to stay adjacent to it, and every dragged unit costs them a stamina chunk. A bad move can cost three stamina instead of one. **\[you\]** |
| Captain Everafter | **Passive** | **Interval Mark**: marks a target using the three-hit rule. When the mark runs out, it detonates for 50% of all the damage the target took while marked. No slow. **\[proposal\]** |
| Parallax | **Primary fire** | **Afterimage**: each shot fires from Parallax's current tile and also from the tile it last stood on, covering two rows at once. **\[proposal\]** |

---

## Count per squad

| Squad | Passives | Cards | Unique primary fire |
| --- | --- | --- | --- |
| Banner Marshal | 1 | 1 | 1 |
| Claim Lord | 2 | 1 | 0 (Standard Guard's passive changes his shot cost) |
| Chief Visionary | 1 | 1 | 1 |
| Director Zero | 1 | 1 | 1 |
| Tide Speaker | 1 | 1 | 1 |
| Prism Elder | 1 | 1 | 1 |
| Mission Mother | 1 | 1 | 1 |
| Captain Everafter | 1 | 1 | 1 |

## Open questions

1. Director Zero's whole kit (above is a proposal). Looks interesting but complicated, we can test it out.
2. ~~Should marks show a visible 3-pip counter?~~ Decided: yes (see Universal rules).
3. ~~Which units keep the standard shot?~~ Decided: every unit without a unique primary fire, with cost and damage by role (see Universal rules).
4. Reef Bulwark's replacement primary fire (Undertow, above) needs your yes/no.

---

## Build notes (first pass)

Everything above is implemented. Where the build had to pick a number or rule that wasn't specified:

- **Deck and hand:** each squad card ×4 in the deck. Hand of 3, one card drawn every 4 s while the hand has room; used cards reshuffle into the deck when it runs out. Keys 1/2/3 play a card on the controlled unit. The enemy has its own deck and hand and plays a card every 7–11 s.
- **Card energy costs:** Fortify 20, Claim 35, Deploy Drone 30, Issue Protocol 25, Flood 30, Spore Bloom 30, Medpod Tether 25, Void Orb 35.
- **Card targeting:** Flood and Spore Bloom aim at the controlled unit's row. Deploy Drone goes on the tile in front of the controlled unit (or the nearest free tile). Fortify and Medpod act on the controlled unit.
- **Braced (Standard Guard):** 18 energy within 1 s of moving, 12 between 1 and 1.5 s, 6 after 1.5 s standing still.
- **FORMATION** is breakable like the other protocols: changing rows costs 10 HP, and the Warden retaliates.
- **Refraction:** the split happens one tile after leaving the muzzle; each split shot does 6.
- **Drone:** 4 damage every 1.5 s; one per team; it blocks its tile.
- **Fire tiles:** 5 damage per second for 4 s. **Spores:** 4 per second, spreading every 3 s for 9 s.
- **Void Orb drag:** each ally takes the shortest legal path to a tile next to the moved unit; each dragged ally costs one stamina chunk.
- **Enemies play by the same rules:** the enemy squad has its own energy, stamina, deck and hand (not shown on screen).

---

# Next phase — plan (steps 1-4 built)

## Starter decks (7 cards)
Each faction has 2 starter cards, ×3 each, plus 1 copy of the leader's unique card (Fortify, Claim, Deploy Drone, Issue Protocol, Flood, Spore Bloom, Medpod Tether, Void Orb). Enemy squads use the same starter decks.

| Faction | Card | Cost | Effect |
| --- | --- | --- | --- |
| Terran | **Stake Claim** ×3 | 15 | Claim one targeted enemy tile for 6–8 s; an enemy standing there is pushed back. |
| Terran | **Sandbags** ×3 | 12 | Barricade on the tile in front of the selected unit for 8 s; absorbs the next 2 enemy shots in that row. |
| Ascendancy | **Overclock** ×3 | 12 | Selected unit's primary costs half for 4 s, then can't fire for 3 s. **[tester feedback 2026-10-29: was 10 / 5 s / 2 s]** |
| Ascendancy | **Containment Field** ×3 | 20 | An enemy on a targeted tile can't leave it for 3 s. |
| Manyworlds | **Riptide** ×3 | 15 | Pull the first enemy in the selected unit's row one column toward you (forced movement). |
| Manyworlds | **Mire** ×3 | 15 | Targeted tile becomes mud for 8 s; leaving it costs double stamina. |
| Long Tomorrow | **Borrowed Time** ×3 | 0 | Selected unit pays 15 HP to refill 2 stamina chunks. |
| Long Tomorrow | **Rewind** ×3 | 15 | Selected unit snaps back to where it stood 2 s ago and regains half the HP it lost in that time. |

## Temporary ground (Stake Claim, Claim, future cards)
- A claimed tile can only be stepped onto if it touches ground you already hold; other claimed tiles count, so claims can chain.
- When temporary ground reverts with a unit on it, that unit is pushed back to the nearest tile it can stand on.
- If a chain breaks, a unit already standing on the cut-off tile stays put, but nobody can step onto it until it reconnects or expires. **[proposal]**

## Draw pressure
- Hand of 3. When the deck is empty, the discard pile is shuffled into a new deck.
- **Evolution:** the draw timer never stops. When it fills, a card is drawn; if the hand is full, a random card in hand is discarded to make room. The draw bar flashes red as it nears full while the hand is full. Draw interval 7.5 s (was 4.5 s; slowed so it can be read).
- **Conquest:** cards stay in hand until played. The timer runs only while a slot is empty, and draws a card each time it fills, until the hand is full. Draw interval 9 s.

## Game modes (2026-10-27)
- **Conquest** (default): pick a leader, then how many units to control (1-3).
  - At 2 units you pick the lackey (heavy or light).
  - Alone, the leader takes its squad's first unique primary as an alternate fire on the right swap button (E / R1), else the heavy's shot. It also takes the squad's first passive if it has none of its own.
  - The enemy fields the same count (random lackey at 2, the same solo kit at 1) through sector 3. After that it adds one unit per sector, up to all three.
  - The board drops its top 3 rows per unit the bigger squad is short of three: 9, 6 or 3 rows.
  - Before each battle the enemy's positions are rolled and shown, the player places their units, then a 3-2-1 countdown starts the fight.
- **Evolution:** the original game. Three units a side, a full board, it starts at once, and the burning hand.

## Controls
| Action | Mouse + keyboard | Controller | Touch (e.g. Steam Deck screen) |
| --- | --- | --- | --- |
| Move | WASD | D-pad | — |
| Swap unit | Q / E | L1 / R1 (LB / RB) | tap a unit's health bar |
| Shoot (hold for Charge Beam) | Space or right-click | **A / Cross** (tap or hold) | — |
| Play card | 1 / 2 / 3, or left-click the card | X / Y / B (Square / Triangle / Circle) | tap the card |
| Aim a tile card | left-click the tile | right stick moves the reticle (snaps tile by tile) | tap the tile |
| Confirm aimed card | (the click above) | R2 / RT, or tap the same card button again | (the tap above) |
| Cancel aiming | right-click or Esc | L2 / LT | tap outside the grid |
| Pause | Esc | Start / Options | — |

- **Controller card flow: tap to arm, aim, confirm.** Tapping a card with no target plays it immediately. A tile card arms and shows a reticle on a sensible default tile (e.g. nearest enemy). The right stick aims, and R2 confirms, so the right thumb never has to hold a face button while steering. The D-pad keeps moving the unit, and the battle keeps running. Tapping a different card switches to it.
- Devices with both a controller and a touchscreen use the controller layout, and screen taps act as mouse clicks.

## Deck viewer
- **Leader select:** list the leader's 7-card starter deck (names + costs) under the squad. Passives and unique primaries are not explained anywhere; players learn them by playing.
- **Pause menu:** a Deck button showing the hand, draw pile (sorted, order hidden) and discard pile.

## Deck growth
- After each battle win: choose 1 of 2 offered cards (must take one).
- Deck cap **12**. At the cap, taking a card means dropping one. The leader's unique card can't be dropped.

## Run structure
- A **sector** is 3 stages: one battle against each of the other three factions.
- Enemy decks and AI improve every stage (better cards, dodging telegraphs, focusing weak units, contextual card play). Each new sector starts slightly harder.
- **World map:** claim sectors. After each sector, choose the next from 2–3 neighbours, each with a small modifier. **[proposal]**
- **Win the run** by claiming enough sectors: **3** on a fresh run, **+2 per NG+ level, capped at 9** (3, 5, 7, 9).
- **Lose** and the run is over with no reward. The next run starts both sides on starter decks.
- **Infinity and Beyond:** on winning a run, the player chooses **Complete Run** (take the reward now) or **Infinity and Beyond** (keep claiming sectors indefinitely, for no extra reward). Difficulty keeps rising each sector. When an Infinity and Beyond run is eventually lost, it counts as a won run and NG+ unlocks as for a normal win. The collection card is drawn from the deck **as it stood when the standard run was won** (the snapshot taken at the Complete Run / Infinity and Beyond choice), not the deck at the loss. Otherwise endless play would let a strong player keep reshaping the deck until it held exactly the cards they want. **[you]**
  - The profile records the most sectors claimed in a single run, so endless runs have a number to beat. **[proposal]**

## Meta-progression
- **Win a run:** one random card from your final deck that wasn't in your starter deck joins your **collection**.
- **New Game+:** before a run, swap starter-deck cards for collection cards. Each NG+ level starts harder and ramps faster (and adds sectors, as above).
- Needs a **profile save**, separate from run saves: collection + highest NG+ level.

## Build order
1. ~~Controls (keyboard + mouse, controller, touch), tile targeting, the 8 starter cards, draw pressure, deck viewer.~~ **Built.**
2. ~~Battle loop: 3-stage sectors, card drafting, deck cap, enemy scaling.~~ **Built.**
3. ~~World map and winning a run.~~ **Built.**
4. ~~Collection, NG+ levels, starting-deck sculpting.~~ **Built.**

### Step 1 build notes
- **Numbers used:** Stake Claim lasts 7 s; the draw timer is 4.5 s and flashes red for the last 1.2 s when a burn is coming; Sandbags sits at the front edge of the selected unit's tile.
- **Borrowed Time** never takes a unit below 1 HP.
- **Rewind** returns to the position from 2 s ago if that tile is free and standable; otherwise the unit stays put but still gets the heal.
- **Pushes go backwards:** any forced move (lost ground, Stake Claim, Claim) prefers moving straight back, then sideways, and forward only as a last resort.
- **Containment** blocks voluntary moves only; pushes and drags still move a contained unit.
- **Controller:** a card button arms a tile card; tapping the same button again also confirms. Right-click or Esc cancels aiming with the mouse. Tapping a player health bar swaps to that unit.
- **AI tile cards:** Stake Claim targets a player tile touching enemy ground; Containment and Mire target a player unit's tile.

### Step 2 build notes
- **Sector order:** each sector shuffles the three other factions. Each stage's enemy is a random leader of that faction.
- **Draft pool:** your faction's 4 cards (2 starters + both leaders' cards) plus the 4 cards of the faction you just beat; 2 distinct cards offered. The offer is saved, so quitting at the draft can't re-roll it. **[you]**
- **HP between battles:** damage carries across the 3 battles of a sector; clearing a sector fully heals the squad; a unit that fell returns at 25% HP for the next battle. The draft screen shows what HP each unit carries into the next fight. **[you]**
- **Sectors keep going for now:** there's no run win yet; that arrives with the world map in step 3.
- **Difficulty level** = (sector − 1) × 3 + stage, starting at 0. It carries across sectors (NG+ will add to it later).
  - **Enemy deck:** its starter deck plus one random card per level, up to the 12-card cap.
  - **Enemy HP:** ×(1 + 0.06 × level).
  - **Enemy AI speed** ramps over the first 9 stages: moves, attacks and card plays come faster, and the wind-up shortens from 0.6 s to 0.4 s.
  - **Dodging:** chance to sidestep a shot about to hit = 12% per level, up to 75%.
  - **Focus:** chance to step toward the weakest player unit's row = 15% per level after the first, up to 80%.
  - **Smart cards** from level 3: heals and Fortify are held until a unit is below half HP, Borrowed Time is saved for when stamina is low, and so on.

### Step 3 build notes
- **Sector map:** each sector is a column of 2–3 choices, each with a modifier; you pick one per sector and it starts that sector's first battle. The whole route to the winning sector is shown from the start, marked "★ CLAIM TO WIN", with one column of look-ahead beyond it. Runs start on the map. **[proposal: the modifiers]**
- **Modifiers:**
  - **Uncharted:** none.
  - **Supply Cache:** drafts offer 3 cards.
  - **Fortified Foes:** enemies +20% HP; drafts offer 3.
  - **Veteran Foes:** enemies 2 levels tougher; drafts offer 3.
  - **Field Hospital:** squad heals 30% of max HP after each battle; fallen units stay fallen.
  - **Low Gravity:** stamina refills 30% faster, both sides.
  - **Ion Storm:** energy waits 50% longer to recharge, both sides.
- **Winning:** claiming `sectors_to_win()` sectors (3, +2 per NG+ level, up to 9) snapshots the deck, then offers Complete Run or Infinity and Beyond.
- **Complete Run:** one random non-starter card from the snapshot joins the **collection** in `user://profile.json`. The profile also records runs won, best sectors in one run and the NG+ level unlocked (`ng_unlocked`, used in step 4). If the deck has no non-starter cards, the win still counts but there's no card.
- **Infinity and Beyond:** endless sectors with difficulty still rising. Its eventual loss shows "THE END OF INFINITY" and completes the run with the reward drawn from the snapshot.
- **Profile save added early:** the plan had it in step 4, but completing a run needs somewhere to keep the reward.

### Step 4 build notes
- **Collection screen** (title screen → Collection): every collected card with copy counts, plus runs won, best run and the NG+ level unlocked.
- **Choosing New Game+:** leader select shows a picker (Standard, NG+1 … up to the highest unlocked) once NG+ is unlocked. Each won run unlocks the next level.
- **NG+ difficulty:** every stage is 2 levels tougher per NG+ level, and difficulty climbs 25% faster per NG+ level (on top of +2 sectors per level, up to 9). **[proposal: the numbers]**
- **Sculpting** (leader select → Deck), on NG+ runs with a non-empty collection:
  - pick a card in the 7-card starting deck, then a collected card to put in its place;
  - the leader card is locked, and each collected card can be used as many times as you own it;
  - Reset restores the starter deck.
  The Deck screen is read-only (with the reason) on Standard runs or with an empty collection, and switching back to Standard resets the deck. **[proposal: the size stays 7; the 6 faction cards are swappable]**
- **Collected cards aren't used up:** the collection is a library to build from, not a stock that runs spend.
- NG+ shows in the battle header, the map subtitle and Load Run.

---

# Content pass: draft cards, faction AI, commanders (built)

## 12 draftable faction cards (never in starter decks; offered in drafts)
| Faction | Card | Cost | Effect |
| --- | --- | --- | --- |
| Terran | Artillery Barrage | 28 | Tile card: shells land on the tile and the tiles above and below, 14 each (staggered). |
| Terran | Hold the Line | 22 | Your squad takes 30% less damage for 5 s. |
| Terran | Requisition | 6 | Draw a card now. |
| Ascendancy | Target Lock | 14 | Tile card: the enemy there is Analyzed at once (hits on it refund energy). |
| Ascendancy | Shield Drone | 22 | Selected unit gets a 30 HP barrier for 10 s. |
| Ascendancy | Recompile | 8 | Discard your hand and draw 3. |
| Manyworlds | Undertow Surge | 24 | Push every enemy in your row back one column (forced movement). |
| Manyworlds | Regrowth | 24 | Your squad heals 4 HP/s for 5 s. |
| Manyworlds | Mudslide | 22 | Tile card: Mire on the tile and the tiles above and below, 8 s. |
| Long Tomorrow | Last Stand | 16 | Selected unit can't drop below 1 HP for 4 s. |
| Long Tomorrow | Burn Bright | 0 | Selected unit pays 20 HP: gain 40 energy. |
| Long Tomorrow | Echo Strike | 20 | For 4 s, each of the selected unit's shots is echoed by a free second shot. **[tester feedback 2026-10-29: was 2 free shots for 18]** |

Each faction's draft pool is now 7 cards: 2 starters, its 2 leaders' cards and these 3. Enemy decks grow from their own faction's pool, so each faction's enemies keep their identity as they scale.

**Balance reasoning:**
- A standard shot gives about 0.6–1 damage per energy (light 5 for 8, leader 8 for 8, heavy 10 for 14). A full energy bar is worth about 80–100 damage.
- Cards are priced against that:
  - Echo Strike: doubles shot damage for 4 s (you still pay for the first shot of each pair) for 20.
  - Barrage: 14 damage per tile hit, up to 42, for 28.
  - Burn Bright: trades 20 HP for 40 energy, which is about 30 damage of shots.
  - Hold the Line: worth about 6 damage per incoming hit for 5 s.

## Faction AI styles (how each faction fights as the enemy)
Each style applies multipliers on top of the level's tuning, and is announced at battle start.

| Faction | Style | Moves | Attacks | Cards | Dodge | Focus | Other |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Terran | DUG IN | ×1.5 less often | ×0.85 more often | — | −5% | +15% | holds position and trades fire |
| Ascendancy | METHODICAL | — | — | ×0.85 more often | +10% | +30% | lines up on your weakest unit |
| Manyworlds | RESTLESS | ×0.65 more often | ×1.1 less often | ×0.75 more often | +15% | — | never stops moving |
| Long Tomorrow | RECKLESS | ×0.9 | ×0.75 more often | — | −10% | +10% | 50% of moves step toward the border |

## Sector commanders
Stage 3 of every sector is a **commander battle**:
- the enemy squad has +25% HP on top of the level scaling;
- it always plays smart cards;
- the header reads "COMMANDER", and "SECTOR COMMANDER" is announced at the start.

## Commander doctrines and AI targeting (Alpha 0.0.1)
Each faction's stage-3 commander adds one signature rule (`Game.DOCTRINES`), announced at battle start:
- Terran, Artillery Doctrine: 3 shells (12 each) arc onto your most crowded column every 14s. They can be dodged.
- Ascendancy, Total Surveillance: your weakest unit is Analyzed every 12s (enemy hits on it refund their energy).
- Manyworlds, Tidecaller: mud on your active unit's tile and the tiles above/below every 12s.
- Long Tomorrow, Burning Stars: each enemy unit survives its first killing blow at 1 HP with 2s of Last Stand.

New cards: Suppressing Fire 18 (jam enemies in your row 3s, cancels their wind-up), Firewall 20 (3-tile Containment, 3s),
Mycelial Link 16 (6s: hits on the unit split evenly across the living squad; shared damage can't kill a squadmate),
Supernova 30 (pay 25% current HP, 30 to every enemy in the row).

## Run structure additions (Alpha 0.0.1, rebuild 2)
- **Events between battles:** after a mid-sector draft there's a 50% chance (`event_chance` per modifier) of an event: a short scene with 2-3 choices built from a fixed effect set (`Game.EVENTS`, `apply_effects`):
  - heal, hurt;
  - add (own / enemy / any / a named faction's pool), remove, discount;
  - next battle {enemy_hp, barrier, enemy_cards};
  - draft_bonus.

  An event isn't repeated within a run.
- **Sector modifiers are data:** `SECTOR_MODS[id].fx` levers: draft, levels, enemy_hp, heal_after, event_chance, stamina/recharge/draw per side, barrier, enemy_cards, start tiles (mire/fire/fortify) and ai offsets. There are 13 modifiers, 6 of them from Gemma.
- **Commander voices:** each leader taunts at the start of a commander battle and has a defeat line (`COMMANDER_LINES`).
- **Card costs** go through `Game.card_cost(id, team)`, so events can discount the player's cards.
- **New cards (from the knowledge base):** Supply Drop, Dig In, Data Breach, Tide Pool, Flash Forward, Collapse.

## Card rarity (2026-10-30)
Common (blue) < Uncommon (green) < Rare (purple) < Legendary (yellow). Starter cards are Common and leader cards Rare **[you]**; draftable cards are rated by strength **[proposal]**. A card's chance in a draft, event reward or enemy deck is its weight against the rest of the pool: Common 100, Uncommon 55, Rare 25, Legendary 8 (`Game.CARD_RARITY`, `RARITY_WEIGHT`).

| Rarity | Cards |
| --- | --- |
| Common | the 8 starters · Requisition · Supply Drop · Target Lock · Recompile · Data Breach · Mudslide · Flash Forward |
| Uncommon | Artillery Barrage · Hold the Line · Suppressing Fire · Shield Drone · Firewall · Undertow Surge · Mycelial Link · Tide Pool · Collapse |
| Rare | the 8 leader cards · Dig In · Regrowth · Last Stand · Burn Bright · Echo Strike |
| Legendary | Supernova (up to 90 damage for 30 energy) |
