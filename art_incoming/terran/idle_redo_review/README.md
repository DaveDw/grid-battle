# Rigid idle pilot — Banner Marshal and Pathfinder

Built with deterministic Pillow/NumPy cut-outs from the original incoming **frame 1**, retained as `*_master.png`. Deliverables are the two 3072 x 384 strips in the parent directory. Each has eight 384 x 384 cells on the original #FF00FF background. No resizing, rotation, interpolation or generated repainting is used in the strips.

## Exact motion

Offsets below are native source pixels relative to frame 1. Positive Y is down; positive X is right. Both units use the same body Y offset. Banner Marshal's body includes his head, cap, torso, sleeves and complete coat; his two grips, sword, flagpole, tassel and legs remain fixed. Pathfinder's torso, armour, arms, rifle, pouches and entire scarf move together; his legs remain fixed. His head follows the body's Y offset and adds the listed X offset.

| Frame | Body Y, both units | Marshal cloth Y range* | Pathfinder head X | Pathfinder eyes / screen |
|---|---:|---:|---:|---|
| 1 | 0 | 0 | 0 | Master |
| 2 | 1 | -2 to 0 | 0 | Master |
| 3 | 1 | -3 to 1 | 0 | Master |
| 4 | 2 | -4 to 2 | 1 | Eyes glance 1 px right; glint at screen x=197 |
| 5 | 2 | -4 to 2 | 1 | One blink; glint at screen x=201 |
| 6 | 1 | -2 to 2 | 1 | Eyes glance 1 px right; glint at screen x=205 |
| 7 | 1 | -1 to 1 | 0 | Master |
| 8 | 0 | 0 | 0 | Exact frame-1 pixels |

*Only flag cloth columns move. Each column retains its pixels and is translated vertically by an integer. The travel tapers to zero at the pole attachment; phase travels across the fabric. `banner_marshal_motion.json` contains every column's offset, starting at x=228. The screen positions above are in the unshifted master; head/body offsets apply afterward.

## Seam treatment

The only reconstructed pixels are hidden backing for a maximum 2 px reveal at cut boundaries. They are copied from neighbouring master pixels; rigid objects are not repainted. Marshal has 52 visible seam pixels when dipped 1 px and 103 when dipped 2 px, along the fixed grips/sword and adjacent coat. Pathfinder has 23 visible neck/scarf backing pixels while his head is shifted right. Individual `*_seam_fN.png` files mark them. These are counts along the seams, not seam widths. Original rigid pixels take priority in front of the backing.

## Self-check results

- PASS: frame 1 is identical to the retained master; frame 8 is identical to frame 1.
- PASS: every visible rigid-body pixel matches the master at its declared integer translation, across all eight frames. Helmet checks exclude only the documented eye and screen effects. Marshal's pole, tassel, sword and grips have zero changed pixels.
- PASS: visible legs remain stationary. The full foot/ankle regions (Marshal y=348–383; Pathfinder y=326–383) are identical in all eight frames.
- PASS: head size, rifle length, sword length, cap, armour and coat scale are unchanged; there is no resampling or rotation. Allowed overlap at the waist/coat hem is at most 2 px.
- PASS: actual saved PNGs decode to the checked pixels. Detailed per-frame results are in `self_check.json`.
- Visually checked native frames, frame-1/frame-4 overlays, enlarged sword/face details and game-size contact sheets: flag motion and the single head/glance/glint/blink beat remain visible. Game previews use 98 px for Marshal's full art height, 86 px for Pathfinder and an average 8 fps, matching current game settings. The original master edge pixels are retained; actual game import keying may clean the magenta fringe further.
- PASS: Godot 4.7.2 `--headless --path . --import` and `--headless --path . --quit-after 300` both exit 0; no `error|invalid` matches. Logs are included. The sandbox initially blocked the installed binary; the approved check ran successfully outside it, using PowerShell's equivalent log filter.

## Review files

- `pilot_preview.gif`: both loops at native size.
- `*_game.gif` / `*_game_contact.png`: previews at current game size.
- `*_contact.png`: all eight frames at native size.
- `*_blend_f1_f4.png`: 50% overlay of frames 1 and 4.
- `*_overlay_f1_f4.png`: difference overlay; cyan = frame 1 only, orange = frame 4 only, pale grey = changed overlapping pixels.
- `*_detail.png`: enlarged frames 1, 4 and 5 for the sword/coat or face.
- `*_segmentation.png`, `*_mask_*.png`, `*_effect_fN.png`, `*_seam_fN.png`: inspectable cut-out and permitted-change masks.
- `build_pilot.py`: reproducible art script. Run without arguments to refresh the review outputs; `--publish` also replaces the two parent strips. It never appends progress logs.

Only these two pilot units were redone. Awaiting Claude's pixel review before any other unit or Captain Everafter's attack.
