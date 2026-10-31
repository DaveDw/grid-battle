# Grid Battle — progress (update this file, not AGENTS.md)

## Status
- [x] Stage 1: skeleton + 6x3 grid — verified clean
- [x] Stage 2: player movement on blue side — verified clean
- [x] Stage 3: buster + enemy HP + enemy movement — verified clean
- [x] Stage 4: enemy telegraph (0.5s flash) + 3s fire cycle, no movement while telegraphing; player HP label top-left bound to hp_changed — verified clean (headless + behavior probe PASS)
- [x] Stage 5: Custom Gauge bar (top of screen) fills over 8s. When full, A opens `scenes/chip_select.tscn` (pause the battle via `get_tree().paused = true`; the menu root uses `process_mode = PROCESS_MODE_ALWAYS`), showing 5 random chips; pick up to 3 → queue. X uses the next queued chip. Chip data in `scripts/chips.gd`: Cannon (40 dmg, first enemy in row), Sword (80 dmg, panel directly in front of player), Recover (+30 HP). Queued chip names bottom-left. Gauge resets after the menu closes.
- [x] Stage 6: enemy `killed` → "DELETED!" overlay; player `killed` → "GAME OVER"; Enter (`confirm`) → `get_tree().reload_current_scene()`.
- [x] Stage 7 (polish, from a play-test): (a) Chip menu must work with the keyboard alone: number keys 1-5 toggle the matching chip; when the menu opens, the first chip button gets focus (`grab_focus()`); selected chips are clearly marked ("[x] " prefix and a highlight colour), unselected show "[ ] ". Enter must only confirm (it must not also toggle the focused button), Esc closes. Test found: with keys only, nothing could be selected and Enter closed the menu with 0 chips. (b) End screen must draw ABOVE everything: put the overlay in a `CanvasLayer` (layer 10) in battlefield.tscn with a full-screen dim ColorRect + centered Labels, hidden by default, shown on kill; remove the `_draw()` overlay. Test found the player/enemy squares and HP label drawn on top of "GAME OVER". (c) When the battle ends, freeze the player and enemy (`set_process(false)` on both) so the enemy stops moving/telegraphing behind the overlay.

## Session log (newest last, one line each)
- Session 1: built stages 1–3 (long session; context hit 64K and slowed down). Restarted with notes.
- Session 2: stage 4 — enemy telegraph + fire cycle, player HP label. Verified clean.
- Session 3: stage 5 — custom gauge (fills 8s to READY; A opens chip_select.tscn while get_tree().paused, menu root process_mode=ALWAYS; 5 random chips, up to 3, Enter=commit / Esc=discard; gauge resets on close); X uses next queued chip: Cannon 40 (first enemy in player's row), Sword 80 (panel directly in front, player.col+1), Recover +30 (capped at max_hp, guarded vs revive); chips.gd roster + bottom-left queue label. Fixed Sword from "any panel in front" to adjacent col+1 to match spec. Verify PASS (import + quit-after clean, no script errors).
- Fix (outside Hermes): battlefield.gd gauge used mini() (int) so it never filled; changed to minf(). Behaviour probe: gauge 1.0 after 9s, menu/queue/Recover OK.
- Session 4: stage 6 — battle-over overlays: connected player.killed/enemy.killed in battlefield.gd (both emit `killed` with no args); overlay_text gates _process (Enter/confirm → reload_current_scene, no gauge/chip/shot updates while up) and _draw draws a dimmed full-screen rect with centered text ("DELETED!" / "GAME OVER" + "press Enter to restart"); in-flight shots cleared on kill. Verify PASS (import + quit-after, grep clean).
- Session 5 (Hermes, CLI): stage 7 parts (a)-(c) written; run went 50+ calls looping on its own probe script and was stopped before ticking.
- Fix + art (outside Hermes): end-screen labels were anchored to the screen bottom (anchor_bottom 1.0 → 0.0, Dim kept full-screen). Added sprites: tools/extract_sprites.gd cut the 24 faction characters from the Desktop sheets into assets/sprites/<faction>/; scripts/fighter_sprite.gd draws them with procedural idle (breathing), attack (recoil + muzzle flash), enemy wind-up (crouch + orange pulse), hit flash, land squash and death fade. Player = terran/pathfinder, enemy = manyworlds/reed_runner (mirrored). Shots now spawn at the muzzle. Stage 7 ticked: verify clean + rendered keyboard play-test PASS.

## v2 — squad test environment (UI + movement)
- [x] 6x9 grid (3 columns per side), 1280x720 window.
- [x] 3 units per side (test squads: Terran Claim Lord / Breacher / Pathfinder vs Manyworlds Tide Speaker / Reef Bulwark / Reed Runner). Q/E swap control; control auto-moves off a dead unit; lose all 3 = lose.
- [x] Shared energy bar (abilities shave it, recharges after 1.5s of no use) and segmented stamina bar (1 chunk per move, constantly refilling), each with its own animation.
- [x] Fighting-game health bars per unit with damage trails.
- [x] Custom gauge and chip menu removed (cards will replace them).
- [ ] Next: leader/heavy/light pairings per faction, then the card system (cards target units or tiles), faction ability lists.
- Session 6 (outside Hermes): built v2 as above. Verify clean; rendered scripted play-test PASS (moves, swaps, shots, recharge, stamina/energy denial, damage trails, unit down, win screen).

## v0.2 — menus and leader select
- [x] Title screen: Continue (latest save), Start New Run, Load Run, Settings, How to Play, Credits, Quit; animated background with the 8 leaders.
- [x] Leader select: only leaders shown, grouped by faction; detail panel with bundled heavy + light, faction blurb, random pick, save-slot choice.
- [x] Save slots (3), Load Run screen with delete confirm; Settings (volume, fullscreen, v-sync, screen shake, damage numbers; saved); scrolling Credits.
- [x] Battle uses the run's squads; pause menu; victory advances the run, defeat ends it.
- Pairings (confirmed by the user): Banner Marshal + Siege Rig + Pathfinder; Claim Lord + Breacher + Standard Guard; Chief Visionary + Synapse Brute + Field Scholar; Director Zero + Protocol Warden + Courtesy Android; Tide Speaker + Reef Bulwark + Reed Runner; Prism Elder + Spore Keeper + Glasswing; Mission Mother + Red Giant + Cinder Scout; Captain Everafter + Deadweight + Parallax.
- Session 7 (outside Hermes): built the above. Verify clean; scripted walk through every screen and the save/win/loss flow PASS.
- Leader select shows style tags, difficulty, blurb, faction blurb and the squad. Ability kits (primary fire / passives / cards, cards outlive their unit, three-hit marks) are in DESIGN.md as a draft awaiting review; Director Zero's kit is still open.

## v0.3 — squad kits
- [x] Leader titles are commands ("Hold the Line", "Never Turn Back", ...).
- [x] All kits from DESIGN.md built: 7 unique primary fires (Mortar, Charge Beam, Courtesy Round, Undertow, Refraction, Ember Shot, Afterimage), standard shots by role, 9 passives (Steady Aim, Shield Up, Braced, Analysis, Enforcer, Ambush, Hit and Run, Overheat, Interval Mark), 8 cards (Fortify, Claim, Deploy Drone, Issue Protocol, Flood, Spore Bloom, Medpod Tether, Void Orb).
- [x] Deck + hand (keys 1-3), cards survive their unit. Three-hit marks with a pip counter. Damage numbers (setting). Enemy squads use the same energy/stamina/cards.
- Session 8 (outside Hermes): built v0.3. Verify clean; kit probe 47/47 PASS (every primary, passive and card, plus enemy AI spending and card play); effect screenshots checked.
- Next: tune numbers in play; Director Zero kit is up for testing; more cards per squad / generic cards so the deck isn't just copies.

## v0.4 — step 1 of the next phase
- [x] Controls for keyboard + mouse (WASD, Q/E, Space/right-click, 1-3, click cards/tiles/health bars), controller (D-pad, L1/R1, A, X/Y/B, right-stick aim + R2, L2 cancel, Start) and touch.
- [x] 8 faction starter cards; starter decks = 2 cards ×3 + leader card ×1 (both sides).
- [x] Per-tile ground: Stake Claim tiles, walkable only when linked to your ground; lost ground pushes units back.
- [x] Draw pressure: timer always runs, full hand burns a random card; deck viewer on leader select and in the pause menu.
- Session 9 (outside Hermes): built v0.4. Verify clean; step-1 probe 49/49 PASS (decks, draw/burn/reshuffle, keyboard/mouse/controller input, Stake Claim rules, all 8 starter cards, AI tile cards) + earlier kit probe 47/47 still PASS.
- Next: step 2 (3-stage sectors, card drafting with the 12-card cap, enemy scaling).

## v0.5 — step 2: sectors, drafting, enemy scaling
- [x] Sectors of 3 stages, one battle against each other faction; sector 2+ follows automatically.
- [x] After every win: pick 1 of 2 cards (must take one); 12-card cap with a forced drop; leader card locked. Offer saved, so it can't be re-rolled.
- [x] Enemy decks, HP and AI scale with level (faster, dodges shots, focuses the weakest unit, plays cards when they're useful).
- [x] Continue / Load resume a pending draft; Load Run shows sector, stage and deck size; old saves migrate.
- Session 10 (outside Hermes): built v0.5. Verify clean; step-2 probe 27/27 PASS; step-1 probe and kit probe still all PASS.
- Next: step 3 (world map, winning a run at 3 sectors, Complete Run / Infinity and Beyond).
- Settled: draft offers come from your faction + the faction you just beat; HP carries within a sector (fallen units return at 25%), clearing a sector heals. Probe 8/8 PASS; all earlier probes still PASS.

## v0.6 — step 3: sector map and winning a run
- [x] Sector map: pick each sector from 2-3 choices with modifiers; the whole route to the win is shown.
- [x] 7 sector modifiers (Uncharted, Supply Cache, Fortified Foes, Veteran Foes, Field Hospital, Low Gravity, Ion Storm).
- [x] Claim 3 sectors to win (+2 per NG+, max 9) -> Complete Run (reward card to the collection) or Infinity and Beyond (endless; the loss counts as the win, reward from the deck snapshot at the win).
- [x] Profile save (collection, runs won, best sectors, NG+ unlocked); run summary screen.
- Session 11 (outside Hermes): built v0.6. Verify clean; step-3 probe 27/27 PASS; all earlier probes still PASS.
- Next: step 4 (collection screen, NG+ selection, sculpting the starting deck).

## v0.7 — step 4: collection, New Game+, deck sculpting
- [x] Collection screen from the title screen (cards + copies, runs won, best run, NG+ unlocked).
- [x] NG+ level picker on leader select; NG+ runs are tougher, ramp faster and need more sectors.
- [x] Sculpt the starting deck on NG+ runs: swap starter cards for collected ones (leader card locked, owned copies only).
- Session 12 (outside Hermes): built v0.7. Verify clean; step-4 probe 21/21 PASS; all earlier probes still PASS. The planned four-step phase is complete.
- New Long Tomorrow art: `the-long-tomorrow-v2.webp` (Desktop faction-sprites folder; the old sheet is untouched) cut by `tools/extract_sprites.gd`, which now handles per-sheet borders and clears enclosed background patches. All 24 muzzle points reset (y is measured up from the feet); `tools/muzzle_sheet.gd` renders them for checking. Verify clean; all six probes PASS (kit, s1-s5; one Sandbags timing wait lengthened in the probe because the Tide Speaker's muzzle moved). Title lineup shifted right and slot picker text shortened so nothing overlaps.
- Sector map planets: 20 planets cut from `planets.webp` (Desktop screencaps folder) by `tools/extract_planets.gd` into `assets/planets/`. Each map node gets a planet matched to its modifier (`Game.MOD_PLANETS`, `Game.node_planet`); claimed planets get your faction ring + flag; choice buttons show their planet. Older saves get a fixed planet per node. Map probe still PASS.

## v0.8 — content pass
- [x] 12 new draftable faction cards (3 per faction), enemy decks grow from their own faction.
- [x] Faction AI styles: Terran dug in, Ascendancy methodical, Manyworlds restless, Long Tomorrow reckless (announced at battle start).
- [x] Sector commander battle at stage 3 (+25% HP, smart cards).
- Session 13 (outside Hermes): content probe 36/36 PASS; all earlier probes PASS (2 probe expectations updated for the larger draft pool and the commander/dodge behaviour).

## Alpha Test Snapshot v0.0.1 — AI pass + first shareable build
- [x] 4 more draftable cards (8 per faction now): Suppressing Fire (Terran), Firewall (Ascendancy), Mycelial Link (Manyworlds), Supernova (Long Tomorrow).
- [x] Commander doctrines (stage 3 only): Terran Artillery Doctrine (shells every 14s), Ascendancy Total Surveillance (Analyzes your weakest unit every 12s), Manyworlds Tidecaller (mud under your active unit every 12s), Long Tomorrow Burning Stars (each enemy shrugs off one killing blow).
- [x] Smarter enemy targeting at every level: 3-tile strikes aim at your most crowded column, Flood/Spore aim at your busiest row, row cards go to the enemy unit lined up on the most targets, Containment/Mire usually pin the unit you're steering. Smart AIs favour their faction's signature cards.
- [x] Version label "Alpha Test Snapshot v0.0.1"; Windows, Linux and macOS builds in `builds/release/` (export presets in export_presets.cfg; templates 4.7.2 installed; ETC2/ASTC import enabled for Apple Silicon).
- Probe s7 written (sandbox gbs6) but not run this session (verify step skipped at the user's request). Compiles clean.

## Alpha 0.0.1 rebuild — polish, sound, backgrounds
- [x] FIX: battlefield.gd/unit.gd type-inference errors from the AI pass stopped the battle script loading (first 0.0.1 packages were broken). s6 + s7 probes now 0 FAILS.
- [x] Controller: A presses buttons / B backs out everywhere (Godot's ui_accept had no pad button); deck viewer scrolls by stick; deck editor keeps focus.
- [x] Leader select: chosen leader stays framed + "✓ CHOSEN" while browsing; detail panel returns to it when the cursor leaves the grid.
- [x] Area effects redrawn: fortify plates, containment bars, bubbling mire, wave floods, spore clouds, flames, claim stripes, shell landing rings, crackling Void Orb tethers, explosion flashes; all fade in/out.
- [x] Sound: scripts/sfx.gd (autoload Sfx) synthesizes every effect in code. Per-unit fire (faction timbre x primary x role pitch x name offset), hits, deaths, steps; card sounds by effect kind in the card's faction timbre; UI ticks/clicks; deny, draw, burn, shell, doctrine, win/lose stingers. Samples in screenshots/sfx-samples/.
- [x] Backgrounds: per-menu backdrops (menu_background.gd: "grid"/"space" looks, planets, tint); leader select tints to the browsed faction; battles show the sector's planet with a nebula in its colours.

## Alpha 0.0.1 rebuild 2: animation, events, knowledge base
- [x] Frame animation: FighterSprite plays <unit>_idle.png (8 frames), _attack.png (2) and _move_<up|down|fwd|back>.png when present (procedural fallback otherwise). <unit>_frames.json carries body_h (scale by the body, not the cell) and an auto-detected muzzle point.
- [x] Art pipeline: Codex (local project) draws to art_incoming/ following kb/briefs/codex-02-unit-frames.md. tools/import_frames.gd keys magenta, cuts cells, drops stray fragments, scales per strip, aligns feet and checks idle motion. tools/watch_frames.sh imports units as Codex logs them in art_incoming/progress.txt.
- [x] Knowledge base kb/ (README, generated roster, briefs, proposals, decisions) shared by Claude, Codex and Gemma (Hermes).
- [x] 6 new cards from Gemma's proposals, revised: Supply Drop and Dig In (Terran), Data Breach (Ascendancy), Tide Pool (Manyworlds), Flash Forward and Collapse (Long Tomorrow). Test s8.
- [x] Events between battles (50% after a mid-sector draft), 11 events; effects heal, hurt, add, remove, discount, next battle {enemy_hp, barrier, enemy_cards}, draft_bonus. Tests s9 and s10.
- [x] Tips on the defeat screen and the sector map; draft cards show unit art; soft nebulae; controller-aware battle hints.

## Rebuild 3 (in progress)
- [x] 6 more sector modifiers (Gemma), data-driven SECTOR_MODS; 21 events (10 from Gemma's premises, reworked); commander voice lines; 15 tips; a Units screen (animated roster); run stats on the end screens; dark-backed, sequenced battle banners.
- [ ] Codex art: 13/24 units done; resume per kb/NEXT.md.
- Packages last built at 11:33 (before the Units screen, run stats and the last 4 events). Rebuild with tools/build_release.sh.

## Alpha Test Snapshot v0.0.3 (2026-10-28)
- [x] Version bumped to 0.0.3 (game.gd, export presets, READMEs). Builds in builds/windows, builds/linux, builds/macos; archives in builds/release. art_backup/ now excluded from exports.
- Includes the redone idles imported so far (14 by Codex) plus the Red Giant and Cinder Scout placeholders.

## Alpha Test Snapshot v0.0.4 (2026-10-29)
- [x] Version 0.0.4 (game.gd, export presets, build READMEs, README badge). Builds in builds/windows, builds/linux, builds/macos; archives in builds/release (older snapshots kept; build_release.sh now only replaces its own version's files).
- Includes everything since 0.0.3: all 24 idles, pixel fonts, card art on every card, draft rewards (own faction + beaten faction), draft card name fitting, layout fixes, Conquest default of 1 unit, window no longer shrinks on settings change.
- Windows build smoke-tested headless: starts clean, no script errors.

## Alpha Test Snapshot v0.0.5 (2026-10-29)
- [x] Self-updater: title screen checks GitHub's latest release; "Update to vX" downloads the Windows/Linux build, swaps the executable and restarts (macOS opens the release page). scripts/updater.gd; tested end to end with a local fake release.
- [x] Fullscreen by default (setting + project window mode), so first launches fill the screen.
- [x] tools/publish_release.sh publishes builds as GitHub releases; the repo is now public so games can see them.
- Windows build smoke-tested headless: starts clean.

## Enemy AI proposal (2026-10-30)
- [x] Planning deliverable: `kb/proposals/codex-enemy-ai.md`, following brief codex-07; shared tactics, all 24 units, faction/card combinations, faster level-5 AI cadence and fairness limits. Implementation remains with Claude.
- Session (Codex, 2026-10-30): read the current mechanics and wrote the proposal; document checks passed (six sections, all 24 units, under 250 lines). No `.gd` edits or gameplay verification. Runtime acceptance checks are specified in the proposal for the implementation stage.

## Alpha Test Snapshot v0.0.6 (2026-10-30)
- [x] Tester feedback: centred event screen; event discounts apply to one copy; extra leader-card copies can be dropped; starting deck readable from character select; Echo Strike reworked (20: 4 s of free echo shots); Overclock 12 / 4 s / 3 s jam.
- [x] Bullet sprite and fire sound for every unit (sounds levelled to one peak); shots drawn per lane with a tile glow and floor shadow.
- [x] Enemy AI rebuilt from Codex's plan (kb/proposals/codex-enemy-ai.md): aims, dodges with a reaction delay, rations stamina/energy, kit and faction tactics, card plans and combos; full cadence at level 5 (was 8).
- [x] Battle shows the last card each side played.
- Checks: feedback.tscn 16, shots.tscn, ai_probe.tscn 20, lane/lastcard screenshots. Windows build smoke-tested headless.

## Alpha Test Snapshot v0.0.7 (2026-10-30)
- [x] Card rarity: Common (blue) < Uncommon (green) < Rare (purple) < Legendary (yellow). Starters Common, leader cards Rare, Supernova Legendary; drafts, event cards and enemy decks weighted 100/55/25/8; frames coloured by rarity everywhere. Check: rarity.tscn.
- [x] Credits: "A game by David Dwight" on every role; third-party font, music and engine creators credited by name.
- Windows build smoke-tested headless.

## Card set 2 artwork (2026-10-30)
- [x] Art delivery: 40 native 32px icons, 40 nearest-neighbour 128px exports, four faction sheets, per-icon checks and notes in `art_incoming/cards/set2/`; completed in Terran / Ascendancy / Manyworlds / Long Tomorrow order. Artwork checks 40/40 PASS; no `.gd` or `assets/` edits.
- Session (Codex, 2026-10-30): followed brief codex-08 using the existing cardkit drawing helper; reviewed all sheets and refined seven ambiguous icons. Temporary-copy Godot import clean after cache generation; runtime exit 0 but **verify not clean** due to a retained `menu.wav` audio resource at shutdown. See `art_incoming/cards/set2/verification.md`; no gameplay integration or gameplay-clean claim.

## Alpha Test Snapshot v0.0.8 (2026-10-30)
- [x] Card set 2: 40 new cards (10 per faction, 4/3/2/1 by rarity) with icons by Codex; Codex built the game-wide rules and 26 cards, Claude the 14 board-mechanic cards and enemy AI plans for all 40.
- [x] Game-wide rules: MK-numbered lasting cards (Annex, Deploy Drone at 40, one drone per copy); card moves break locks; pure draw cards speed the draw timer; 1.5 s alternate-fire cooldown; blocked pushes deal 8 and stun 0.5 s.
- Checks: cards2.tscn 45 PASS (both teams), ai_probe 20, feedback, shots, rarity; board2/lane/lastcard screenshots; ai_sim with new cards in enemy decks, no errors. Windows build smoke-tested.
