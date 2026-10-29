# Protocol: cut-out idle animation (the Astra method, done by Claude)

This is the method Codex (GPT-6 Astra) uses for the idle redo, written down so that Claude can do the same work without Codex. The approved standard is Banner Marshal and Pathfinder (2026-10-28). The per-unit specs are in `kb/briefs/codex-04-idle-redo.md`.

Tool: `tools/cutout_idle.gd`. It needs Godot only, no Python. Rigs live in `tools/rigs/<faction>/<unit>.json`. The worked example is `tools/rigs/ascendancy/protocol_warden.json`.

## The idea in one paragraph
Frame 1 of the existing idle is the **master**. Every other frame is the master cut into a few **parts** (body, head, a drone, a pupil). Each part is shifted by whole pixels, or turned at most 4°, and never redrawn. Whatever is not in a part stays **fixed** (legs and feet). Where a moved part leaves a 1-3 px gap, the gap is filled from the fixed pixels beside it. Life comes from **light**: tints that pulse, glints, rising particles and an afterimage. Light may change freely; shapes may not.

## Steps
1. **Read the unit's spec** in `codex-04-idle-redo.md`, and the motion size in its "User review (2026-10-28)" section:
   - Body breath: 0,1,1,2,2,1,1,0 px.
   - Head shifts: about 1 px.
   - Mechs dip about 2 px.
   - Floaters bob 3-4 px.
   - Cloth moves up to 4 px, but only Banner Marshal's flag waves.
2. **Make a grid sheet.** Write a rig with just `{}` (or `"parts": []`), then run:
   `godot --headless --path . -s tools/cutout_idle.gd -- <faction>/<unit> --grid`
   Open `art_incoming/claude/<faction>/<unit>_parts.png`. On the left is the master with a grid: faint lines every 10 px, brighter every 50, red every 100. On the right are the part colours. **Red boxes mark stray blobs**: small detached pixel islands, usually particles frozen from the old idle. That was the Protocol Warden shoulder bug. Clean every one that isn't real art.
3. **Write the rig** (format below). List small parts first, because a pixel belongs to the first part that claims it. Then list the big part they ride on, and use `follow` so the small part moves with it.
4. **Build:** run `godot --headless --path . -s tools/cutout_idle.gd -- <faction>/<unit>`. It writes these files to `art_incoming/claude/<faction>/`:
   - `<unit>_idle.png`: the strip, same size as the source.
   - `_parts.png`: check that each colour covers exactly one rigid piece.
   - `_contact.png`: the 8 frames, 2 rows of 4.
   - `_small.png`: the frames at game size (0.37). The beat must read here.
   - `_check.json`: `problems` must be `[]` and `stray_blobs` must be `[]`.
5. **Review** the same way as Codex's work:
   `godot --headless --path . -s tools/idle_diff.gd -- claude/<faction>/<unit> out.png`
   - Grey means still. One flat colour per part means it moved rigidly.
   - Red is allowed only on glows, glints, particles, fire and the flag.
   - Then judge by eye at both scales.
6. **Publish only units assigned to Claude.** Add `--publish` to write `art_incoming/<faction>/<unit>_idle.png`; Codex writes to the same path. Then run `godot --headless --path . -s tools/import_frames.gd -- <faction>/<unit>`, log the unit in `art_incoming/redo_progress.txt` as `<faction>/<unit> redone (claude)`, and add a line to `kb/NEXT.md`.

## Rig format
```json
{
  "feet_y": 350,                     // rows from here down must never change (omit for floaters)
  "base_offset": [172, 2],           // where assets/sprites/<faction>/<unit>.png sits on the frame
  "master": "base",                  // optional: start from the base sprite, not idle frame 1
  "clean": [                         // fix the master before anything moves
    {"rect": [195,0,290,95], "select": "cyan", "fill": "base"},   // repaint from the base sprite
    {"rect": [266,25,272,32]}                                      // or just erase ("fill": "clear")
  ],
  "parts": [
    {"name": "pupil", "rect": [300,182,322,207], "select": "bright",
     "follow": "body", "dx": [0,0,1,2,1,-1,0,0], "z": 2},
    {"name": "body", "dy": "breath", "rects": [[0,0,690,200]], "polys": [[[x,y], ...]]}
  ],
  "effects": [
    {"type": "tint", "shape": {"rect": [378,136,408,173], "select": "cyan"},
     "color": [155,255,255], "amount": "pulse"}
  ]
}
```
(Comments are for this doc only. JSON files can't contain them.)

**Shapes**, used by parts, clean entries and effect `shape`s:
- `rect` / `rects` take `[x0,y0,x1,y1]`, with the end excluded.
- `poly` / `polys` take `[[x,y],...]`.
- `circle` takes `[cx,cy,r]`.
- No region means the whole frame.
- `select` keeps one colour family: `cyan red orange yellow green purple blue bright dark any`.
- `minus` cuts out another shape.
- Only pixels with any opacity count.

**Part motion:** `dx`, `dy` and `rot` (degrees; positive turns clockwise, about `pivot`, which defaults to the part's centre). Each is an 8-value list or a preset:

| Preset | Values |
|---|---|
| `breath` | 0,1,1,2,2,1,1,0 |
| `dip` | 0,0,2,2,2,0,0,0 |
| `float` | 0,-1,-3,-4,-4,-3,-1,0 |
| `still` | all 0 |

- `follow: "<part>"` copies that part's motion, and `delay: n` makes it n frames late (Director Zero's hands). The part's own `dx/dy/rot` are added on top.
- `z` sets draw order; fixed pixels are at z 0 and parts default to 1.
- A part with no motion is a way to keep pixels fixed inside another part's region (Warden's hip housings).
- `"rigid": false` marks a part that may deform, such as an orb's inner swirl turned as a disc.

**Effects** (`amount` is an 8-value list or `pulse` = 0,0,.35,.85,1,.45,0,0):

| Effect | What it does | Example |
|---|---|---|
| `tint` | Lerps `shape` pixels toward `color` by `amount`, and/or multiplies them by `mul` (`mul` ≈ 0.05 turns a light off). Applied before the move, so it rides with its part. | Glow, pulse, blink, a red eye going off |
| `glint` | A plus-shaped sparkle at `at`, following `part`, with opacity `amount`. | Glasses, visor, helmet glass |
| `particles` | `count` squares start in `rect` between `frames: [from, to]` (1-based), rise `rise` px per frame, drift sideways up to `drift` px, and fade over `life` frames. Use `size` and `color` to style them. Seeded, and gone by frame 8. | Spores, embers, vent puffs |
| `ghost` | A copy of the whole master tinted toward `color` at `opacity` × `amount`, drawn behind the unit, offset by `dx`/`dy`. | Parallax's afterimage |

## Seams
When a part moves, the gap it leaves is filled from the nearest opaque pixel within 3 px **on the side it moved away from**. A body dipping 2 px extends the hip joint above it down into the gap. Above a dipping head there is nothing, so that space stays transparent.

`_check.json` gives `seam_pixels` per frame:
- A few hundred is normal for a full-body dip.
- If thousands, a part outline probably cuts through the middle of a solid area.

## Rules the tool checks, and rules it can't
The tool checks:
- Frame 1 equals the master.
- Nothing below `feet_y` changes.
- No part jumps more than 2 px between frames, including frame 8 back to frame 1.
- No turn is over 6°.
- No stray blobs.

You check by eye:
- Each part covers one rigid piece. A weapon must be in the same part as the hands holding it.
- Cloth moves only with its body.
- The beat is visible on `_small.png`.
- The motion size matches Banner Marshal and Pathfinder, no bigger.

## Lessons so far
- **Frozen particles (Protocol Warden, 2026-10-28):** the old idles had particle swirls, and building from old frame 1 froze a few in place as stray squares. Always clean stray blobs, and repaint from the base sprite when one sits on the body.
- **Too-small motion is wrong too:** the bigger "Pilot review" budget was withdrawn. The user approved the pilots' size: 2 px body, about 1 px head.
- **Keep weapons inside the body part:** a rifle split from the hands that hold it shears at the grip.
- **Never use a box that reaches below the belt (Red Giant and Cinder Scout, 2026-10-28, rejected by the user):** "parts attached to movement that shouldn't be." A rectangle or rough polygon around an arm, knife or rock that hangs in front of a leg also grabs thigh, knee-pad or cloth pixels, and those then slide while the rest of the leg stays put. Below the waist:
  - Outline the piece tightly.
  - Add `select` (a list is fine, e.g. `["grey", "orange", "yellow"]` for rock and lava) so the suit colour behind it stays fixed.
  - Check the waist on a 2× zoom of `_parts.png`: every thigh, knee pad and leg must be the fixed (green) colour. Every hanging tip of belt cloth must have the body's colour.
- **Check every held object and every light, not just the legs (Parallax and Deadweight, 2026-10-29, caught by the user after Claude passed them):** Parallax's astrolabe was cut off, and Deadweight's backpack lighting flickered oddly. The leg crops and motion maps didn't show either. In review, also crop each held object (weapon, tool, orb, astrolabe) and each lit area across all 8 frames. Confirm the object is whole in every frame and that light changes only where the brief asks for it.
- **Magenta/purple fringe (Banner Marshal, 2026-10-29, spotted by the user):** some frame sheets carry a 1-3px purple or magenta rim left from a keyed-out background, plus semi-transparent edge pixels. In review, count purple (b>r+20 and r>g+10) and magenta (r-g>20 and b-g>20) pixels within 3px of the background. If the unit's base sprite has no purple, any found there is fringe: delete the purple pixels on the edge and turn the magenta outline pixels grey. Only treat transparent gaps of 40px or more as background, so emblem holes are left alone.
