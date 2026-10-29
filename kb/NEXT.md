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
