# Extra pair: Chief Visionary + Prism Elder

Built from the clean base sprites with `build_pair_15.py`, after comparing the
backed-up idles in `art_backup/idle_v1/`. The current idle strips supply canvas
dimensions only. Their pixels are not reused. No Godot run or game-asset edits.

Both bodies move down **0, 1, 1, 2, 2, 1, 1, 0 px**, matching the approved pilots.
The head adds a 1 px horizontal glance on frames 3–5. All rigid pieces use
integer translations without rotation or resampling. Frame 1 uses the clean
base at its original scale; frame 8 equals frame 1.

## Chief Visionary

- Base: `assets/sprites/ascendancy/chief_visionary.png`, offset (143, 2).
- Strip: 4544 × 360; eight 568 × 360 cells.
- Torso, arms, hands and complete coat move together. The head moves as a
  separate rigid cut-out; the hand remains in front of the chin. Neck/waist
  backing uses only nearby source pixels, at most 1–3 px away.
- Four drones are extracted as complete connected components, including their
  antennae. Each bobs 3 px with opposing phases, plus at most 1 px sideways.
  Their cyan lenses pulse. The glasses glint during the head beat.
- Legs and shoes stay planted. All pixels in the full feet region are identical
  across the eight frames. Checked the exterior coat edges for pixels left in
  the fixed-leg mask: zero remain.

## Prism Elder

- Base: `assets/sprites/manyworlds/prism_elder.png`, offset (34, −1).
- Strip: 3984 × 385; eight 498 × 385 cells.
- The base has no visible feet or legs. Its complete cloak moves as one piece.
  The vertical placement leaves room for its 2 px dip: the negative offset
  removes only transparent source padding, and no opaque pixels are clipped.
- Twelve floating crystal pieces bob 3 px with opposing phases and at most
  1 px sideways. Every crystal preserves all its original RGBA pixels, including
  facets and outlines. The primary head/core has the 1 px glance above the breath.
- The cyan core and cloak emblem pulse. Brightening follows the source
  brightness so dim halo pixels stay dim. All fourteen isolated cyan spark
  components drift and twinkle; none remains frozen in its original position.
- Traced the front crystal edges and right connector separately from the cloak.
  No warm crystal/connector pixels remain assigned to the cloak.

## Review and verification

`pair_15_self_check.json` records all eight frames for both units. All rigid
body/head/coat, final drone/crystal, visible-leg, feet, unexplained-change and
clipping checks pass with zero mismatches. Each floating-piece comparison runs
again on the completed frame, after all other pieces and effects are placed.
Saved strips are decoded and compared exactly to the generated arrays.

Reviewed masks, head/hand and coat/leg seams, crystal/cloak boundaries, frame
1/4 overlays, and game-size contacts against the approved pilot method. Source
backups and game assets are untouched.

Each faction's `idle_redo_review/` contains native and 0.37-scale GIFs, enlarged
details, per-frame motion/mask files, and an `old_vs_new.gif` comparing the current
game idle with the proposed replacement. No replacement has been imported.
