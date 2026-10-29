# Director Zero + Protocol Warden — idle pair 08

## Warden correction after review

The three frozen cyan squares above the left shoulder were removed from every
frame. Exactly 466 pixels per frame were restored from the base sprite aligned
at (172,2), following the existing body dip. Every other output pixel is
unchanged. `fix_warden_particles.py` preserves the previous strip for comparison;
`protocol_warden_particle_fix_check.json` records the fix. Warden's frame-1
source-equality statement below now means the source with this local restoration.
Director Zero was not changed. The main builder includes the same cleanup.

Built as integer cut-outs from frame 1 of the imported source strips. The
approved pilot scale and preceding pairs' lossless pixel method are retained.
The script imports pixel utilities from `build_pair_07.py` without running
that script's entry point or rewriting either approved unit.

No rotation, resampling, warping or changing rigid surface pixels is used in
the production strips. Only the specified emissive pixels, side-pupil motion,
and 1–3 px of hidden seam backing change independently of each rigid cut-out.

## Director Zero

The blade reaches the source cell's bottom row, so its 4 px bob goes upward
from the original pose. The blade and both halo arcs share the same offset.
Both whole hands follow exactly one frame behind, including across the loop.

| Frame | Blade + halo Y offset | Both hands Y offset | Halo light | Red eye |
| --- | --- | --- | --- | --- |
| 1 | 0 | 0 | source | on |
| 2 | -1 | 0 | dim to 55% | on |
| 3 | -3 | -1 | 76% + 15% bright mix | on |
| 4 | -4 | -3 | 80% bright mix | on |
| 5 | -4 | -4 | 95% bright mix | **off** |
| 6 | -3 | -4 | 84% + 20% bright mix | on |
| 7 | -1 | -3 | 94% | on |
| 8 | 0 | -1 | source | on |

The halo outlines, holes and alpha remain exact. Brightness changes affect
only the light surfaces. The eye-off mask includes its near-white highlights.
On frame 8 the body and lights match frame 1; the hands are 1 px above frame 1
and return by 1 px on the loop. This preserves the specified one-frame lag.

## Protocol Warden

Sphere and complete arms/claws dip 2 px together on frames 3–5. Both entire
leg assemblies remain planted, including the hip ball housings and their dark
rims. Foreground claws keep their source depth in front of the legs.

| Frame | Sphere + arms Y offset | Chest bright mix | Side pupil X offset |
| --- | --- | --- | --- |
| 1 | 0 | 0 | 0 |
| 2 | 0 | 0 | 0 |
| 3 | 2 | 35% | 1 |
| 4 | 2 | 85% | 2 |
| 5 | 2 | 100% | 1 |
| 6 | 0 | 45% | -1 |
| 7 | 0 | 0 | 0 |
| 8 | 0 | 0 | 0 |

The small pale iris in the side sensor moves as an exact cut-out within its
dark lens. Only 1–2 uncovered columns are filled with adjacent glass pixels;
the socket and sphere keep their exact source pixels. The cyan chest pulse
is confined to the existing emitter. Frame 8 is identical to frame 1.

## Self-check

- Director strip: 4272×379, eight 534×379 cells. Warden strip: 5520×368,
  eight 690×368 cells. Original canvas, scale and RGBA alpha retained.
- Frame 1 matches each source first frame exactly.
- Every rigid cut-out matches its integer translation; zero rigid mismatches.
- Director's translated alpha shapes match exactly, including translucent
  edge pixels. No clipped blade, halo or hand pixels.
- Warden's visible leg pixels and the entire foot region, including surrounding
  transparent pixels, are unchanged in every frame. No clipped moving pixels.
- All Warden changes are accounted for by cut-outs, specified effects or
  copied seam backing. Its iris retains the exact source pixels when shifted.
- Frame 1 / frame 4 overlays, enlarged joint/eye details and 0.37-scale
  contacts inspected. Halo pulse, red-eye blink and cyan chest pulse are visible.
- Saved strips are decoded and compared against the checked arrays.

Reproduce previews with `build_pair_08.py`, then add `--publish` to write the
finished strips. Masks, effect/seam masks, per-frame motion JSON, GIFs and
`pair_08_self_check.json` are saved beside it. Godot was not run.
