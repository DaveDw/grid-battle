# Cinder Scout + Captain Everafter

Built from the clean base sprites with `build_pair_13.py`. The existing idles
provide canvas dimensions only: none of their pixels are used. The bases retain
their original resolution. No Godot run or game asset edits.

Both upper bodies move down by **0, 1, 1, 2, 2, 1, 1, 0 px**, matching the approved
pilots. All rigid parts use integer translation without rotation or resampling.
Seam backing uses only 1–3-pixel copies of the adjacent source rows. Frame 1 is
the exact clean base on its canvas; frame 8 is identical to frame 1.

## Cinder Scout

- Source: `assets/sprites/long/cinder_scout.png`, positioned at (170, 2).
- Strip: 4752 × 324, eight 594 × 324 cells.
- Helmet, torso, arms, glove and knife move together. The knife mask follows
  the blade/hilt and excludes orange thigh pixels. Legs, pants and knees stay
  planted. The full knife pixel comparison passes without any occlusion exemption.
- Only the hand flame deforms: nearest-row flicker anchored at the hand, with
  height changes of 0, +1, +3, +4, +2, −1, −1, 0 px above the fixed flame base.
- All source ember pixels, including their dark halos, rise by 2 px per frame
  through frame 7 and fade, then respawn at the loop. Two small new sparks rise
  during frames 3–6. No frozen particles are taken from the rejected idle.
- A warm glass glint sweeps across the visor in frames 3–6.

## Captain Everafter

- Source: `assets/sprites/long/captain_everafter.png`, positioned at (231, 2).
- Strip: 6320 × 385, eight 790 × 385 cells.
- Torso, arms, scythe shaft, blade and all cape/rag pieces move together. The
  pole stays straight. Knees and boots are protected fixed source pixels.
- All exterior and central cape tips were checked for pixels accidentally
  assigned to the legs. No such cloth pixels remain.
- The blade's existing purple rim brightens on frames 3–5 (50%, 100%, 65% of
  the pulse), preserving its shape and alpha. A faint glass glint passes in
  frames 3–6. No particles are added.
- The complete scythe pixel comparison passes with only the permitted rim
  lighting excluded; no boot/knee occlusion exemption is used in that check.

## Self-check

`pair_13_self_check.json` records all eight frames. All rigid-part, complete
weapon, visible-leg, protected-knee/boot/thigh, feet-region, clipping, and
unexplained-change comparisons pass with zero mismatches. Both strips are
decoded after saving and compared exactly to the generated arrays.

Reviewed the segmentation, frame 1/4 overlays, enlarged weapon/leg and flame/
glove boundaries, and 0.37-scale contacts. Compared the game-size previews with
the approved Banner Marshal and Pathfinder pilots. Native and game-size GIFs,
per-frame masks, and exact motion tables accompany this file.
