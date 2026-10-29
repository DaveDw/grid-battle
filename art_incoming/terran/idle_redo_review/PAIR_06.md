# Breacher + Standard Guard idle pair

Scripted rigid cut-outs from frame 1 of the current `assets/sprites/terran/` idle strips. Source transparency, native scale and eight-cell horizontal layout are preserved.

- Breacher: 560 x 329 cells; output 4480 x 329.
- Standard Guard: 486 x 306 cells; output 3888 x 306.

## Motion

Breacher's source shield reaches the last row of its cell. A downward breath would clip rigid shield pixels, so the approved 2 px motion is reversed for this unit: **0,-1,-1,-2,-2,-1,-1,0 px**. The complete head, torso, armour, arms, shield and hanging fabric rise together and return. The shield and helmet have no independent rotation or deformation. The feet stay planted. This preserves the source frame 1 and cell dimensions without cropping or shrinking the shield.

Standard Guard uses **0,1,1,2,2,1,1,0 px** down. His entire upper body, arms, hands and rifle translate together, with fixed legs and feet.

| Frame | Breacher Y | Guard Y | Visor sweep | Shield emblem | Rifle cyan lights |
|---|---:|---:|---|---|---|
| 1 | 0 | 0 | master | master | master |
| 2 | -1 | 1 | master | master | bright flash |
| 3 | -1 | 1 | starts left | master | master |
| 4 | -2 | 2 | crosses left centre | bright peak | master |
| 5 | -2 | 2 | crosses right centre | fading pulse | master |
| 6 | -1 | 1 | reaches right | master | bright flash |
| 7 | -1 | 1 | master | master | master |
| 8 | 0 | 0 | exact frame 1 | exact frame 1 | exact frame 1 |

Only the existing visor-light, orange shield-emblem and cyan rifle-light pixels change colour. Metal surfaces and outlines retain their source pixels. Small hidden seams use neighbouring master pixels copied over at most 3 px; no rigid part is stretched, rotated, resized or redrawn.

## Verification and review

- All eight frames have zero rigid-body, shield/rifle, visible-leg and foot pixel mismatches outside the declared light masks.
- Every source body pixel remains on the canvas: zero clipped rigid pixels.
- Frame 1 exactly equals the source master; frame 8 exactly equals frame 1.
- Saved PNGs are reopened and compared with the verified arrays.
- Native frames, frame-1/frame-4 blends, enlarged waist/visor/weapon details and 0.37-scale contact sheets were inspected. Light effects are visible at 0.37 scale.
- Godot was not run. All outputs and review files are inside `art_incoming/`.

`build_pair_06.py` reproduces the outputs and checks, using the preceding approved pair's shared pixel operations without running its entry point. Use `--publish` to write the two parent strips; it does not append progress logs. See `pair_06_self_check.json`, each unit's motion JSON, segmentation, masks, effect/seam masks, native/0.37 GIFs and contact sheets for review.
