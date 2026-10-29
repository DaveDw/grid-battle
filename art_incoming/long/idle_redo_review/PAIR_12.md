# Mission Mother and Red Giant idle redo

Built and published with `build_pair_12.py --publish`. Both masters come directly from the clean base PNGs at original scale. Existing idle files contribute only canvas dimensions; no rejected idle pixels or frozen ember squares are carried over. Godot was not run.

Mission Mother uses base offset (232, 2) on a 736 x 399 cell. Red Giant uses (235, 2) on an 834 x 416 cell.

| Frame | Mother body down | Left medical assembly | Right medical drone | Crosses dimmed | Giant body down | Lava pulse | Embers |
| --- | ---: | ---: | ---: | --- | ---: | ---: | --- |
| 1 | 0 px | 0 px | 0 px | none | 0 px | source | none |
| 2 | 1 px | 1 px up | 1 px down | none | 1 px | 10% | none |
| 3 | 1 px | 2 px up | 2 px down | left | 2 px | 45% | emitted |
| 4 | 2 px | 3 px up | 3 px down | left | 3 px | 100% | rise, brightest |
| 5 | 2 px | 3 px up | 3 px down | right | 3 px | 80% | rise, fade |
| 6 | 1 px | 2 px up | 2 px down | right | 2 px | 30% | rise, fade out |
| 7 | 1 px | 1 px up | 1 px down | none | 1 px | 10% | none |
| 8 | 0 px | 0 px | 0 px | none | 0 px | source | none |

Mission Mother's two red-cross drones bob in opposite phases as complete pixel cut-outs. The upper gold-marked module belongs to the left assembly because its long tube connects to that medical drone; the module and tube keep their exact shape and move together. The right drone includes its complete loop and lower ring. The pointing arm, helmet, backpack and coat translate with the torso. Coat lining and torn outlines were checked around both fixed knee pads and boots.

Red Giant uses the per-unit brief's 3 px heavy breath. The rock arm, fist, helmet, armour, right arm and tabard translate as rigid pieces. The fist's bottom outline was traced above the thigh: no red thigh pixels occur in its lower boundary mask. The tabard has its own mask, separate from the thigh plates, knee pads and leg strap. These leg parts are excluded from the moving body and restored in front of hanging cloth, with independent exact-pixel checks.

The lava effect changes only connected molten fissures, excluding isolated tan rock highlights and metallic knuckles. Brighter source pixels heat more strongly than the orange halo to retain the source gradients. Three fresh ember particles rise and fade on frames 3–6. No source geometry is warped, scaled or rotated.

All eight frames passed checks for exact visible rigid-body and named-part translations, exact drone/tube translations, fixed visible legs, complete protected knee/thigh/strap pixels, unchanged foot regions and surrounding transparency, no clipping, and no unexplained changes. Frame 1 equals the clean base master; frame 8 equals frame 1 for both units. Published PNGs were decoded and compared with the generated arrays.

Visually reviewed masks, enlarged drone/coat/fist/thigh/tabard/knee/lava details, frame 1/frame 4 overlays and 0.37-scale contacts, alongside the approved pilot previews. Reproducible script, masks, seam maps, motion JSON, GIFs and checks are saved here; detailed numeric results are in `pair_12_self_check.json`.

Published: `../mission_mother_idle.png` (5888 x 399) and `../red_giant_idle.png` (6672 x 416), eight frames each.
