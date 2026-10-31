# Brief: icons for card set 2 (Codex / Astra)

Status: open
Output: `art_incoming/cards/set2/` (art only; don't edit any .gd file or anything in `assets/`)

## The job
Draw a 32 px icon for each of the 40 new cards in `kb/proposals/claude-card-set-2.md`, and
deliver them as **four sheets, one per faction** (10 icons each), plus the single icons.

## Match the existing card art exactly
The current 38 icons are the standard: look at `assets/cards/*.png` and the overview
`art_incoming/claude/all_cards.png` before drawing. The rules they follow
(`art_incoming/claude/cards/cardkit.py` enforces them):

- **32 x 32 px canvas**, drawn at that size (not downscaled from a big image).
- **Simple, flat shapes.** One clear object or symbol per card that reads at 32 px. No
  scenes, no gradients, no dithering, no anti-aliased edges, **no text or numbers**.
- **5 to 7 colours in total, including a 1 px dark outline** `#14161f` around every
  shape's outer edge.
- **Alpha only 0 or 255** (fully transparent background, no soft edges).
- Lit from the top left: one highlight and one shadow tone per base colour.
- Each icon must be distinct from every existing icon. In particular, don't reuse the
  silhouettes of Barrage, Fortify, Containment, Mire, Flood, Spore Bloom, Medpod or Void Orb.

## Faction palettes (use these hex values)
- **Terran:** orange `#e8742a` / `#ffb65c` / `#a74724`; gunmetal `#66717d` / `#c4ced3` / `#39414e`
- **Ascendancy:** cyan `#38d6e8` / `#b4f6ff` / `#1b8798`; white and silver `#e8eef2` / `#9aa6b0` / `#5a6470`
- **Manyworlds:** teal-green `#3fbf8a` / `#9cf0c4` / `#217a5a`; purple `#8a5cd6` / `#c7a6ff` / `#553591`; mud `#8a6440` / `#b8935e` / `#523822`
- **Long Tomorrow:** red-orange `#e04a3a` / `#ff8f6e` / `#8c2a26`; gold `#e8b84a` / `#ffe39a` / `#9a7226`; void purple `#6e40b8` / `#a983ea` / `#3b2170`

Outline `#14161f` for all. One icon may borrow a single accent from another palette when
the card's meaning needs it (for example red for a heal cross); say which in the notes.

## Cards (ids in brackets; see the proposal for what each does)
- **Terran:** Quick March (quick_march), Field Repairs (field_repairs), Spotter Flare (spotter_flare), Razor Wire (razor_wire), Creeping Barrage (creeping_barrage), Overwatch (overwatch), Smoke Screen (smoke_screen), Volley Fire (volley_fire), Annex (annex), Orbital Strike (orbital_strike)
- **Ascendancy:** Calibrate (calibrate), Efficiency Pass (efficiency_pass), Pulse Mine (pulse_mine), Holo Decoy (holo_decoy), Signal Jam (signal_jam), Mirror Shield (mirror_shield), Phase Shift (phase_shift), Neural Link (neural_link), Quarantine (quarantine), Perfect Model (perfect_model)
- **Manyworlds:** Wave Rider (wave_rider), Brine Splash (brine_splash), Thornvine (thornvine), Sap Poultice (sap_poultice), Maelstrom (maelstrom), Pollen Cloud (pollen_cloud), Barnacle Shell (barnacle_shell), Tsunami (tsunami), Overgrowth (overgrowth), Worldshaper (worldshaper)
- **Long Tomorrow:** Spare Parts (spare_parts), Slow Burn (slow_burn), Afterglow (afterglow), Lifeline (lifeline), Red Shift (red_shift), Cinder Trail (cinder_trail), Event Horizon (event_horizon), Second Wind (second_wind), Time Debt (time_debt), Heat Death (heat_death)

## Deliverables
1. `art_incoming/cards/set2/source_32/<id>.png`: each icon at 32 x 32.
2. `art_incoming/cards/set2/<id>.png`: each icon scaled 4x (128 x 128) with nearest-neighbour.
3. `art_incoming/cards/set2/sheet_<faction>.png` (terran, ascendancy, manyworlds, long): the
   10 icons in two rows of five at 4x on a dark background `#222832`, with the card name
   under each.
4. `art_incoming/cards/set2/checks.json`: per icon, the colour count and whether alpha is
   only 0/255. Every icon must pass (5 to 7 colours, alpha 0/255).
5. `art_incoming/cards/set2/notes.md`: one line per icon saying what it shows.

## Process
Do one faction at a time in this order: Terran, Ascendancy, Manyworlds, Long Tomorrow.
After each sheet, append a line to `art_incoming/cards/set2/progress.txt`
(`<faction> done`) and post the sheet in the chat. Keep going to the next faction unless
told to stop.
