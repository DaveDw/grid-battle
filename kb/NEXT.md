# Where the production loop stopped (2026-10-27, 11:40)

## In flight
- **Codex (ChatGPT app, local project grid-battle):** out of usage until 11:57. 13 of 24 units are done (all Terran and Ascendancy units, plus manyworlds/tide_speaker). To resume, send it:
  > Continue the batch in kb/briefs/codex-02-unit-frames.md from where you stopped (next: manyworlds/reef_bulwark). Then do kb/briefs/codex-03-fixes.md.
- **Background importer:** `tools/watch_frames.sh` runs until about 13:47 and imports each unit Codex logs in `art_incoming/progress.txt`. If it has stopped, run it again (`bash tools/watch_frames.sh`), or import by hand: `godot --headless --path . -s tools/import_frames.gd -- manyworlds/reef_bulwark`.
- **Gemma (Hermes, Gemma4 model):** working on `kb/briefs/gemma-09-copy-edit.md`, which writes `kb/proposals/gemma-copy-edit.md`. It must not edit `game.gd`; a backup exists in the Claude session scratchpad. Review the table and apply the good rows by hand.

## After the art lands
1. Run `godot --headless --path . -s tools/frames_preview.gd`, then look at `screenshots/frames_preview.png`. Look for scale drift, weapons angled down or up, and static idles.
2. Put any fixes in `kb/briefs/codex-03-fixes.md` (the standard_guard attack is already listed).
3. Rebuild: `bash tools/build_release.sh`.

## Tests
They live in the sandbox (`%LOCALAPPDATA%/Temp/gbs6`): kit and s1-s12, all passing at 11:36. Copy `scripts/*.gd` there before running them.

## Ideas queue
- Event choices that pick two cards (the "discount2" idea).
- A codex/lore screen.
- Gemma: more leader taunts; per-unit card flavour lines.

## Idle redo (started 2026-10-27, afternoon)
- Codex (now GPT-6 Astra, Extra High) is redoing 22 idles per `kb/briefs/codex-04-idle-redo.md`: rigid parts move only as whole pieces, and nothing waves except Banner Marshal's flag. Chief Visionary and Prism Elder are approved and stay as they are.
- Codex logs each unit in `art_incoming/redo_progress.txt`. The old idles are backed up in `art_backup/idle_v1/`.
- To review a unit: `godot --headless --path . -s tools/idle_diff.gd -- terran/pathfinder out.png`. The motion map is a guide only (the approved idles are repainted too); judge the frames by eye.
- Import a unit only after it is approved: `godot --headless --path . -s tools/import_frames.gd -- <faction>/<unit>`.
- 2026-10-28: banner_marshal and pathfinder approved by the user and imported. They are the new standard (better than Chief Visionary and Prism Elder). Codex now works two units at a time and stops for review; next pair is siege_rig + claim_lord.
- 2026-10-28 12:05: siege_rig and claim_lord passed review and were imported. Next pair: breacher + standard_guard.
- 2026-10-28 12:20: breacher and standard_guard passed and were imported (Terran done). Next pair: ascendancy synapse_brute + field_scholar.
- 2026-10-28 12:35: synapse_brute and field_scholar passed and were imported. Next pair: director_zero + protocol_warden.
- 2026-10-28 14:10: director_zero and protocol_warden passed and were imported. Next pair: courtesy_android + manyworlds/tide_speaker.
- 2026-10-28 14:40: Claude can now build idles without Codex: kb/protocols/cutout-idle.md + tools/cutout_idle.gd (rigs in tools/rigs/). Tested on protocol_warden (output in art_incoming/claude/, not published; Codex is fixing its own version).
- 2026-10-28 14:50: protocol_warden particle fix, courtesy_android and tide_speaker passed and were imported (Ascendancy done, 12 of 22). Next pair: reef_bulwark + reed_runner.
- 2026-10-28 15:15: Claude built red_giant and cinder_scout with tools/cutout_idle.gd (from the clean base sprites; the old idles had frozen embers) and imported them. 14 of 22.
- 2026-10-28 15:40: the user rejected Claude's red_giant/cinder_scout; they go back to Codex (brief updated). Claude's versions stay in assets until Codex's replace them.
- 2026-10-28 15:45: reef_bulwark and reed_runner passed and were imported (12 of 22 by Codex; red_giant and cinder_scout back in Codex's queue). Next pair: spore_keeper + glasswing.
- 2026-10-28 19:10: spore_keeper and glasswing passed (rigid body, legs planted, spore puff/blades only change) and were imported. Next pair: long/mission_mother + long/red_giant.
- 2026-10-28 19:30: mission_mother and red_giant (Codex rebuild, replaces Claude placeholder) passed and were imported. Next pair: long/cinder_scout + long/captain_everafter.
- 2026-10-28 19:50: cinder_scout (Codex rebuild, replaces Claude placeholder) and captain_everafter passed and were imported. Next pair: long/deadweight + long/parallax, then captain_everafter attack frame 1 scale fix.
- 2026-10-28 23:30: user asked to see Chief Visionary + Prism Elder redone too; queued after deadweight + parallax (brief section added, old idles backed up in art_backup/idle_v1).
- 2026-10-29 00:20: deadweight and parallax passed and were imported. All 22 idles redone. Parallax's glitch streaks on the planted shin stay still with the leg (flagged to user). Next: chief_visionary + prism_elder (user asked), then captain_everafter attack frame 1 scale fix.
- 2026-10-29 00:40: user approved the new chief_visionary and prism_elder; imported (old ones in art_backup/idle_v1). User is having Codex redo deadweight + parallax again; review when they land.
- 2026-10-29 00:45: user had Codex fix Parallax (astrolabe cut off) and Deadweight (backpack lighting); fixed versions checked and imported. Claude's review missed both; protocol lesson added.
- 2026-10-29 01:50: text restyle + card art started. Fonts (user's pick): Press Start 2P for everything on cards plus numbers/stats (Game.FONT_CARD / FONT_NUM), Silkscreen as the project default for UI text, Jersey 10 for headers/titles (Game.FONT_HEAD; any title >= 24 px). Fonts + OFL licences in assets/fonts/; ligatures off (Pixelify Sans was tried and dropped: its fi ligature and 5/7 digits misread). Card art brief kb/briefs/codex-06-card-art.md (32x32 at 4x, simple, faction accents); terran + ascendancy done and in assets/cards/ (19/38); manyworlds next after Codex's 4:58 AM reset, then long. Game.card_art(id) is cached (an uncached texture freed after the draw call rendered as a white square). Icons show in the hand (32 px), deck view (32 px) and draft (128 px).
- 2026-10-29: fixed settings changes un-maximizing the window (apply_settings now only changes window mode when Fullscreen actually changes). Tested: maximized stays maximized; fullscreen on/off still work.
- 2026-10-29: Silkscreen's wider caps overflowed two screens: settings controls text now wraps (560 px), How to Play dialog wraps (1040 px, 12 px text) and fits 720 px.
- 2026-10-29: Conquest now defaults to 1 unit on character select.
- 2026-10-29: card art everywhere cards show: deck view 64 px (pause/sector map/run end/collection/draft deck), deck sculpt + event buttons 32 px, draft small cards 32 px, run-end reward 64 px, Units screen card 64 px, character select starting deck as icon row. Helpers Game.card_icon / card_button_icon. Checked by screenshot: deck view, deck sculpt, character select, units. Not checked in-game: event, draft drop grid, run-end reward (need a run).
- 2026-10-29: user asked Claude to try card art. Claude built the 9 Manyworlds icons with Codex's method (art_incoming/claude/cards/build_manyworlds.py; same 32px grid, auto outline, 5-7 colours, 4x export). Three redraw rounds (waves -> water symbol, mire, flood, mudslide). Awaiting user verdict; not imported. Codex's Manyworlds request is still typed (unsent) in its box; a 5:01 AM timer sends it.
- 2026-10-29: user approved Claude's Manyworlds icons (imported) and asked for the Ascendancy set redone in the same style; Claude's redraws imported (art_incoming/claude/cards/build_ascendancy.py). Codex's original Ascendancy icons kept in art_incoming/cards/. Codex's next job switched to Long Tomorrow (sent after its 4:58 AM reset).
- 2026-10-29: user said Claude's card art is better; Claude drew Long Tomorrow and redrew Terran (and Ascendancy earlier). All 38 card icons are Claude's, in assets/cards/. Credits updated. Codex's queued Long Tomorrow job cancelled (Codex idle; remaining Codex task: captain_everafter attack frame 1 scale fix).
- 2026-10-29: Banner Marshal looked small (body_h measured to his flag tip). body_h override 258 (head to feet on the idle frame) in tools/import_frames.gd BODY_H_OVERRIDES + his _frames.json; he's now leader-sized everywhere. Added FighterSprite.max_height so boxed views (Units tiles/detail, character select portrait/squad) still fit the raised flag.
- 2026-10-29: removed purple/magenta edge fringe from units whose base art has no purple (all Terran + Ascendancy, Mission Mother, Cinder Scout, Red Giant, Reef Bulwark): purple edge pixels deleted, magenta outline pixels neutralised, Banner Marshal + Pathfinder alpha made solid/clear. Backups in art_backup/fringe_2026-10-29/. Purple-art units (Tide Speaker, Prism Elder, Spore Keeper, Glasswing, Reed Runner, Captain Everafter, Deadweight, Parallax) not touched.
- 2026-10-29: sector map text overflow fixed: choice boxes 340x150, names in Jersey 10 (wrap), descriptions 12px; planet names under the map in Jersey 16; SECTOR / CLAIM TO WIN headings widened; 'you face...' line 13px and wraps. Tested with the longest modifiers in a throwaway slot (99, deleted).
- 2026-10-29: draft offer = 1 card from your faction + 1 from the faction just beaten; extra slots (modifiers/events) random from both, no duplicates (Game.win_battle). Tested over 200 simulated wins.
- 2026-10-29: draft card tag uses short faction names (Terran / Ascendancy / Manyworlds / Long Tomorrow) so 'faction · target' fits; card text keeps 'HP/s' together (word joiner after '/') in draft, deck view and run end.

- 2026-10-29: Draft cards step the name font down (16 to 8) until it fits beside the cost; "Artillery Barrage" no longer hides its 28. README draft screenshot recaptured.
- 2026-10-29: Alpha 0.0.4 snapshot built (all three platforms) in builds/release.
- 2026-10-29: Fullscreen by default: DEFAULT_SETTINGS fullscreen=true and project window/size/mode=3, so a first launch fills the screen with no windowed flash. Checked with no settings.cfg (tools/rigs/check/winmode.tscn): mode 3, 3840x2160. Not in the 0.0.4 builds.
- 2026-10-29: Self-updater (scripts/updater.gd + title-screen button, top right): checks GitHub latest release, downloads the -windows.exe / -linux.x86_64 asset, swaps the exe (Windows renames the running one to .old) and restarts; macOS opens the release page. Tested end to end with a local fake release (0.0.4 -> 0.0.9). Needs a public repo and releases published with tools/publish_release.sh.
- 2026-10-29: Alpha 0.0.5 built (updater + fullscreen default); first GitHub release.
- 2026-10-29 tester feedback: event panel centred (and shrinks to fit the card picker); event discounts now apply to one copy (run["discounts"]: id -> [per-copy amounts], CardHand.cost_of per slot; old saves keep their every-copy discount); extra leader-card copies can be dropped/removed (only the last copy is locked); character select deck icons open the Deck screen, whose cards are always selectable with an info line; Echo Strike reworked (20: 4 s of free echo shots), Overclock 12 / 4 s / 3 s jam (was 10 / 5 / 2). Checks: tools/rigs/check/feedback.tscn (16 PASS).
- 2026-10-30: Bullet sprite per unit (assets/bullets/<faction>/<unit>.png, 16px, drawn by art_incoming/claude/bullets/build_bullets.py), drawn on a nearest-filtered shot layer with a faint team-coloured trail; mortar shells turn along their arc; Charge Beam orb uses the sprite. Every unit has its own fire sound (Sfx.UNIT_FIRE). Check: tools/rigs/check/shots.tscn (samples in screenshots/sfx-samples/fire/).
- 2026-10-30: Enemy AI rebuilt from Codex's plan (kb/proposals/codex-enemy-ai.md, response lists what is built and what is left). Full cadence now at level 5 (was 8). Bench (30 s vs wandering dummies, dmg/energy old -> new): level 5 Terran 0.37->0.61, Ascendancy 0.24->0.49, Manyworlds 0.28->0.49, Long 0.28->0.83. Probes: ai_probe.tscn 13 PASS.
- 2026-10-30: Rest of Codex's AI plan built: card plans executed as scored, utility-card rules, lane sharing (lvl 3+), mark bursts and Captain guard (lvl 2+), protocol responses. ai_probe.tscn 20 PASS.
- 2026-10-30: Battle shows the last card each side played (scripts/last_card.gd): yours left of the board, the enemy's right; icon, name, energy paid, text; flashes on a new card. Check: tools/rigs/check/lastcard.tscn.
- 2026-10-30: Shots drawn per row (y-sorted among units): a bullet passes in front of units in the rows above and behind those below; its tile glows in team colour and it casts a shadow on its own row; mortars on an air layer. Check: tools/rigs/check/lane.tscn.
- 2026-10-30: Card rarity (DESIGN.md "Card rarity"): starters Common, leader cards Rare, Supernova Legendary; drafts, event cards and enemy decks weighted 100/55/25/8; card frames coloured by rarity on every screen. Check: tools/rigs/check/rarity.tscn (3000 drafts: Supernova 49 vs Borrowed Time 614).
