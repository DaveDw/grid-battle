# Pair 05: Siege Rig + Claim Lord

Built from frame 1 of each current `assets/sprites/terran/<unit>_idle.png`, using the approved pilot method. The retained masters and output strips keep the source pixels, transparency, cell dimensions and eight-cell horizontal layout.

- Siege Rig: 428 x 365 cells; 3424 x 365 strip.
- Claim Lord: 542 x 352 cells; 4336 x 352 strip.

## Motion, by frame

All offsets are native whole pixels relative to frame 1. Positive Y is down.

| Frame | Siege hull + guns Y | Mortar rotation up | Canister band lit | Claim body + cape Y | Knuckle pulse | Blink |
|---|---:|---:|---|---:|---:|---|
| 1 | 0 | 0 | none | 0 | 0 | no |
| 2 | 1 | 0 | left upper | 1 | 0 | no |
| 3 | 2 | 0 | left lower | 1 | 40% | no |
| 4 | 2 | 0 | middle upper | 2 | 100% | no |
| 5 | 2 | 2 degrees | middle lower | 2 | 75% | yes |
| 6 | 1 | 2 degrees | right upper | 1 | 30% | no |
| 7 | 1 | 0 | right lower | 1 | 0 | no |
| 8 | 0 | 0 | none | 0 | 0 | no |

Siege Rig's hull, canisters, mortar and side cannon translate together. The leg assemblies, including the curved left hip hinge, stay fixed. The mortar uses one nearest-neighbour rigid rotation around source pivot (196, 99) on frames 5–6. Its original colours are retained without interpolation. The two detached grey source puff elements rise and fade, then a replacement rises into the loop pose; all other source pixels on the hull are retained. Puff Y offsets are 0,-1,-2,-3,-4,3,1,0; alpha is 255,220,160,90,20,65,170,255.

Claim Lord's head, torso, both arms/gauntlets, armour, tabard and complete cape share one translation. The cape passes behind the fixed legs. Only the knuckle light patches and eyelids change colour. Knuckle ridges and armour outlines retain their original pixels. There is one blink on frame 5.

## Checks

- Zero rigid-body or stationary-leg pixel mismatches across all eight frames, outside documented light/eye effects and normal overlap.
- Feet are identical across all frames. Siege's entire y=285–364 region is unchanged; Claim's complete fixed leg masks, including both feet, are unchanged.
- Frame 1 exactly matches its source master. Frame 8 exactly matches frame 1.
- Original scale is retained: no resizing, nonuniform transforms or repainting of rigid parts. The mortar's explicitly allowed rotation is the only resampling.
- Only 1–3 px hidden backing seams are filled by copying neighbouring source pixels. Siege exposes 57 backing pixels at the mortar mounting on frames 5–6. Claim exposes 35/70 backing pixels for the 1/2 px dip. These are seam-area counts, not widths.
- Native frames, frame-1/frame-4 and frame-1/frame-5 blends, enlarged joint/face/gauntlet details and 0.37-scale contact sheets were inspected. Sequential canister lights, rising/fading puffs, knuckle glow and blink remain visible at 0.37.
- Final PNGs are reopened and compared with the checked arrays before completion.
- Godot was not run. No files outside `art_incoming/` were edited.

`build_pair_05.py` reproduces the cut-outs, strips, masks, previews and `pair_05_self_check.json`. Run without arguments to refresh review files; `--publish` also writes the two parent strips. It never changes the progress log or the approved pilots. `siege_rig_motion.json` and `claim_lord_motion.json` give every frame's transforms. The `*_scale037.gif` and `*_native.gif` loops use an average 8 fps. Individual masks, effect masks, seam masks and overlays are included beside them.
