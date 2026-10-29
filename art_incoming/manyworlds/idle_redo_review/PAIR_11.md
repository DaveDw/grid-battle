# Spore Keeper and Glasswing idle redo

Built and published with `build_pair_11.py --publish`. Both masters use the clean base sprite at its original scale, on the existing idle canvas. Spore Keeper is offset (185, 2) in a 698 x 383 cell; Glasswing is offset (254, 4) in a 796 x 344 cell. No old idle pixels were used, including Spore Keeper's old square particles over the caps. Godot was not run.

Both upper bodies use the approved pilot offsets: 0, 1, 1, 2, 2, 1, 1, 0 pixels down. Legs and feet stay fixed. Weapons, hands and cloth move with the torso as exact integer cut-outs. All rotations use nearest sampling.

| Frame | Body down | Spore orbs up | Launcher pulse | Spore puff | Glass wings | Antennae |
| --- | ---: | ---: | ---: | --- | --- | --- |
| 1 | 0 px | 0 px | source | absent | normal | normal |
| 2 | 1 px | 1 px | 15% | absent | raised 3 degrees | normal |
| 3 | 1 px | 2 px | 55% | emitted | normal | twitch 3 degrees |
| 4 | 2 px | 3 px | 85% | rises, brightest | raised 3 degrees | twitch 3 degrees |
| 5 | 2 px | 3 px | 65% | rises, fades | normal | twitch 3 degrees |
| 6 | 1 px | 2 px | 30% | rises, fades out | raised 3 degrees | normal |
| 7 | 1 px | 1 px | 10% | absent | normal | normal |
| 8 | 0 px | 0 px | source | absent | raised 3 degrees | normal |

Spore Keeper's mushroom caps, rock and moss never deform. The orbs translate independently of the torso. The launcher glow uses exposure changes to preserve its source texture; the five new spores drift upward and fade over frames 3–6. All hanging cloth, including the small left cuff tips, moves with the body. Frame 8 equals frame 1 exactly.

Glasswing's four panels are individual rigid cut-outs, including their pale and dark outlines. Left panels rotate -3 degrees and right panels +3 degrees on even frames, continuing the alternating buzz across frame 8 to frame 1. The two antennae rotate once on frames 3–5. Foreground arms, blades, breastplate, holster and scarf keep their exact pixels. Wing joints receive at most three copied source pixels underneath foreground limbs; those additions are hidden at rest. Legs are composited in front of the wings.

Self-check passed in all eight frames for both units: exact rigid-body and named-part translations, unchanged visible legs and foot regions, no clipped translated pixels, exact orb translations / permitted wing and antenna rotations, and no unexplained pixel changes. Both frame 1 masters match the clean bases. Published PNGs were decoded and compared with the generated arrays.

Visually checked segmentation, enlarged cap/orb/cloth/waist/wing/antenna details, frame 1/frame 4 overlays and 0.37-scale contact sheets. The motion uses the same 2 px body sequence as the approved pilots. Masks, seam maps, motion JSON, native GIFs and scaled previews are saved alongside this note. Detailed checks are in `pair_11_self_check.json`.

Published strips: `../spore_keeper_idle.png` (5584 x 383) and `../glasswing_idle.png` (6368 x 344), each containing eight frames.

Queue note: the updated brief restores Red Giant and Cinder Scout to their normal places. They must be built from their clean base sprites, not Claude's rejected idles. Neither was touched in this pair.
