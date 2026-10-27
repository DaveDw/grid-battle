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
