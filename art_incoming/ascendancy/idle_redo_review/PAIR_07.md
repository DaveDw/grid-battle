# Synapse Brute + Field Scholar — idle pair 07

Built from frame 1 of the imported source strips in `assets/sprites/ascendancy/`.
The approved Banner Marshal and Pathfinder strips were opened for comparison.
Body offsets match their approved 0,1,1,2,2,1,1,0-pixel breath.

No resampling, rotation, warping, repainting, or cloth deformation is used in
the production strips. Each cut-out is copied from the source frame at an
integer offset. The only new surface pixels are specified light/screen effects
and hidden seam backing copied from neighbouring source pixels, 1–3 pixels wide.
Preview scaling uses nearest-neighbour sampling only.

## Frame motion

| Frame | Body down | Brute cannon charge | Brute glasses | Scholar head extra down | Scholar screen scroll | Scholar glasses |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 px | source baseline | source | 0 px | source | source |
| 2 | 1 px | dim, 30% source | source | 0 px | 2 px | source |
| 3 | 1 px | 60% source | glint at source x=340 | 1 px | 4 px | glint at x=312 |
| 4 | 2 px | 90% source plus 35% bright mix | glint at x=344 | 1 px | 6 px | glint at x=317 |
| 5 | 2 px | peak, 95% bright mix | glint at x=360 | 1 px | 8 px | glint at x=334 |
| 6 | 1 px | fade, 45% bright mix | source | 0 px | 10 px | source |
| 7 | 1 px | fade, 12% bright mix | source | 0 px | 12 px | source |
| 8 | 0 px | source baseline | source | 0 px | source | source |

The Brute's torso, head, arms, complete cannon and back cable loops translate
together. Both leg assemblies stay fixed, including the small outer knee
plates. The cannon's existing cyan core and energy marks change brightness;
the casing and its dark grooves keep their source pixels.

The Scholar's torso, whole coat and lining, arms, tablet frame, pistol and hand
translate together. Trousers and boots stay fixed. The entire head has the
additional 1-pixel dip on frames 3–5; glasses glints remain inside the lenses.
Scrolling cyan data is clipped to a screen inset away from the bezel and glove.

## Self-check

- Source canvas and scale retained: Brute 4688×347, eight 586×347 cells;
  Scholar 4768×318, eight 596×318 cells. Source RGBA transparency retained.
- Frame 1 and frame 8 are pixel-identical to the source first frame.
- Every visible rigid cut-out matches its exact integer translation, excluding
  only the explicit screen/light masks. Zero rigid or head mismatches.
- Visible stationary leg pixels match the source. The entire foot region,
  including surrounding transparent pixels, is unchanged in all eight frames.
- No clipped moving pixels and no unexplained changed pixels.
- Frame 1 / frame 4 blends, enlarged seams, and 0.37-scale contacts inspected.
  Cannon charge, lens glints and tablet data are visible at game size.
- Saved PNGs are decoded and compared with the checked arrays.

Reproduce using `build_pair_07.py`; `--publish` writes the two finished strips.
Masks, frame effect/seam masks, motion JSON, contact sheets, native/game-scale
GIFs and `pair_07_self_check.json` accompany the script. Godot was not run.
