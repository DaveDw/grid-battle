# Reef Bulwark and Reed Runner idle redo

Built with `build_pair_10.py --publish` from the clean base sprites at original scale. No old idle frame pixels are used. Base offsets on the existing cell canvases are Reef Bulwark (124, 2) and Reed Runner (148, 2). No Godot run.

Both use the approved pilot breath: upper body offsets (0, 0), (0, 1), (0, 1), (0, 2), (0, 2), (0, 1), (0, 1), (0, 0). Legs and feet stay fixed. All translations are whole pixels, and the pincer rotation uses nearest sampling.

| Frame | Body down | Reef upper jaw | Reef eye glow | Reed pouch | Reed eyes |
| --- | ---: | ---: | ---: | ---: | --- |
| 1 | 0 px | 0 degrees | source | normal | open |
| 2 | 1 px | 0 degrees | 15% | normal | open |
| 3 | 1 px | 4 degrees | 65% | swell step 1 | open |
| 4 | 2 px | 4 degrees | 100% | swell step 2 | open |
| 5 | 2 px | 4 degrees | 85% | swell step 2 | closed |
| 6 | 1 px | 0 degrees | 40% | swell step 1 | open |
| 7 | 1 px | 0 degrees | 10% | normal | open |
| 8 | 0 px | 0 degrees | source | normal | open |

Reef's shell and claw-shield move rigidly with the torso. The upper jaw, including its entire dark outline, rotates around (229, 286). Only its hinge receives copied seam pixels. The fixed sole masks include two isolated outline pixels. The lower jaw extends to y=351, so the full-canvas foot check starts at y=355; the separately checked leg masks cover the rest of both feet.

Reed's rifle, both hands, scarf and hanging pouches move with the torso. The tail stays with the pelvis. Only the soft throat skin swells: 2% horizontal and 8% vertical expansion per step, anchored below the mouth, using nearest samples. The original mouth line and scarf cover its edges. The frame 5 blink uses sampled cheek skin and a dark lid crease.

Self-check passed for every frame: exact rigid-body and named-part translations, fixed visible legs, unchanged feet and surrounding transparency, no clipped body pixels, exact allowed special transforms, no unexplained changed pixels. Frame 1 and frame 8 both equal the clean base master byte for byte. Saved PNGs were decoded and compared with the generated arrays.

Visually checked segmentation, enlarged jaw/eyes/pouch/waist/foot details, frame 1/frame 4 blends and 0.37-scale contact sheets against the approved pilot previews. All masters retain the source scale; no old-idle particles remain.

Outputs: `../reef_bulwark_idle.png` (4704 x 373, eight 588 x 373 cells) and `../reed_runner_idle.png` (4640 x 305, eight 580 x 305 cells). Detailed frame checks are in `pair_10_self_check.json`; per-frame motion maps, masks, blends, contact sheets and GIF previews are alongside this note.
