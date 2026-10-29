# Codex task: next idle pair (siege_rig + claim_lord)

Read `kb/briefs/codex-04-idle-redo.md` in full first, especially the last section, "User review (2026-10-28)".

The user approved your banner_marshal and pathfinder idles and said they are better than anything before. They are now the standard. Open `art_incoming/terran/banner_marshal_idle.png` and `art_incoming/terran/pathfinder_idle.png`, and match their method, motion size and clean seams exactly.

Do exactly two units now:
1. `terran/siege_rig`
2. `terran/claim_lord`

The source strips are in `assets/sprites/terran/<unit>_idle.png`. The pre-redo originals are in `art_backup/idle_v1/`. Follow each unit's spec in the brief, at the pilots' motion size (see "User review (2026-10-28)"; ignore the withdrawn "Pilot review" budget). Build the frames the way you built the pilots, with a script that shifts cut-out layers from frame 1, as in `art_incoming/terran/idle_redo_review/build_pilot.py`.

Rules (I will reject the unit if any is broken):
- Rigid parts move only as whole pieces shifted or rotated. No outline changes, no waving, and no bending of armour, weapons, hulls or capes.
- The feet pixels are identical in all 8 frames.
- The scale is identical in every frame.
- The beat and glows are clearly visible at 0.37 scale.

Output:
- Write each finished 8-frame strip to `art_incoming/terran/<unit>_idle.png`, with the same frame size and layout as the source strip.
- Append `terran/<unit> redone` to `art_incoming/redo_progress.txt`.
- Review images may go in `art_incoming/terran/idle_redo_review/`.
- Do NOT run Godot. Do not edit any code or files outside `art_incoming/`. Do not touch `assets/`.
- Stop after these two. Your final message is: "pair done: siege_rig, claim_lord", plus one line per unit saying what moves.
