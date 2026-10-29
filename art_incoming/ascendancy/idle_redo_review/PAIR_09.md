# Courtesy Android + Tide Speaker — idle pair 09

Both masters come directly from the clean base sprites, placed on their
existing idle canvases without resizing. No pixels from either old idle are
used. This removes Android's frozen cyan eye squiggle and avoids carrying any
old idle particles into Tide Speaker.

## Courtesy Android

Base: `assets/sprites/ascendancy/courtesy_android.png`, placed at (182,2).
Output: 4512×333, eight 564×333 cells.

| Frames | Head | Eye | Gun, torso and legs |
| --- | --- | --- | --- |
| 1–2 | source position | on | fixed |
| 3–4 | 4° clockwise tilt | on | fixed |
| 5 | 4° clockwise tilt | off | fixed |
| 6 | 4° clockwise tilt | on | fixed |
| 7–8 | source position | on | fixed |

The whole head rotates around the neck socket at (282,64), using nearest
sampling. No breath or servo movement is added. The socket lip remains fixed
in front of the join, with only 1–3 px of copied backing behind it. The eye
mask includes the light's white core but excludes the helmet's white casing.

## Tide Speaker

Base: `assets/sprites/manyworlds/tide_speaker.png`, placed at (228,2).
Output: 6208×385, eight 776×385 cells.

| Frame | Head + bowl Y | Orb Y | Orb exposure | Tip curls |
| --- | --- | --- | --- | --- |
| 1 | 0 | 0 | 1.00 | source |
| 2 | 1 | -1 | 0.72 | source |
| 3 | 1 | -2 | 0.90 | inward/outward 4° |
| 4 | 2 | -3 | 1.20 | inward/outward 4° |
| 5 | 2 | -3 | 1.35 | inward/outward 4° |
| 6 | 1 | -2 | 1.10 | inward/outward 4° |
| 7 | 1 | -1 | 0.94 | source |
| 8 | 0 | 0 | 1.00 | source |

The head moves as one piece, with tiny distal facial/crest tips handled as
separate soft cut-outs. The brass bowl, its front light, lip and clamps move as
one rigid piece. Foreground skin is excluded from the metal mask, including
its highlights and dark edges. The long outer tentacle shafts, backpack, lower
support and ground contacts stay fixed. Only the distal roughly 10–15 px of
each tip curls; no shaft ripples or stretches.

The orb and its rings translate as one object. Its light uses exposure changes
that preserve the dark aura and concentric shading. Base water streaks and
sparkles twinkle in phases and drift by 1 px; all 351 water-effect pixels change
during the loop. Orb-adjacent particles move with the orb. No base water
particles are carried through the loop as frozen overlays.

## Self-check

- Frame 1 and frame 8 exactly match each clean, aligned base master.
- Saved canvas sizes and scale match the existing strips.
- Android: exact expected 4° rigid rotation outside its eye effect; fixed gun,
  body and feet have zero mismatches.
- Tide Speaker: all visible translated head/bowl/orb pixels and rotated tip
  cut-outs match their expected transforms. The orb's alpha shape is unchanged.
- Fixed shafts, metal supports, and the entire ground-contact region match the
  original pixels in every frame. No clipped moving body or orb pixels.
- No changes outside the named cut-outs, light effects and small copied seams.
- Enlarged seams, frame 1 / frame 4 overlays, and 0.37-scale contacts inspected.
  Head blink/tilt, orb pulse/bob and water twinkles are visible.
- Saved PNGs are decoded and checked against the validated arrays.

`build_pair_09.py` stages previews and checks; `--publish` writes both strips.
Each faction's `idle_redo_review/` contains masks, effect/seam masks, motion
JSON, a self-check JSON, native/game-size GIFs and contact/detail sheets.
The combined report is `pair_09_self_check.json` beside this file.

Warden's requested correction was saved and logged separately before this
pair. Godot was not run. No game files were changed.
