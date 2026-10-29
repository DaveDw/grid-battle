# Deadweight + Parallax

User review fixes: the backpack amber patch is a brass fitting, so its lighting
now stays exactly as drawn. Parallax's base sprite clipped the astrolabe's left
arc; that missing area is completed with reflected gold/outline pixels from
the intact opposite arc. This corrected master is used in all eight frames.
These changes supersede the backpack-light and exact-base descriptions below.

Built from the clean base sprites with `build_pair_14.py`. Existing idles supply
canvas dimensions only; none of their pixels are reused. No Godot run or game
asset edits. Only this pair is published.

Both upper bodies use the approved pilot offsets **0, 1, 1, 2, 2, 1, 1, 0 px**.
Rigid parts and hanging cloth use integer translation without rotation,
stretching or resampling. Waist backing copies only 1–3 adjacent source rows.
Frame 1 is the clean base at its original resolution. Frame 8 equals frame 1.

## Deadweight

- Base offset: (212, 2). Strip: 5520 × 340; eight 690 × 340 cells.
- Torso, helmet, arms, gloves, orb outline and backpack move together.
- The void interior rotates 0, 0, 60, 140, 220, 300, 0, 0 degrees. Only the
  interior light pixels rotate; the glove pixels and orb silhouette do not.
  The hidden interior behind the fingers is backed with opposite-side void
  pixels before sampling, so glove colours never enter the swirl.
- The purple rim pulses during frames 3–6. The backpack's existing amber light
  dims on frames 3–4, brightens on frames 5–6, and returns to its base appearance.
- Gloves have zero overlap with either orb effect mask. Knees and feet remain
  fixed. The full glove comparison passes with zero mismatches.

## Parallax

- Base offset: (255, 3). Strip: 6544 × 363; eight 818 × 363 cells.
- Helmet, torso, arms, pouch, ring staff and rags move together. Legs stay put.
- The ring stays in front of the leg: its translated outside edge covers
  0, 2, 2, 4, 4, 2, 2, 0 source pixels at the pad boundary. These are occluded
  pixels, not leg pixels included in the moving ring. All visible protected
  pad pixels remain fixed, and the entire ring retains its exact source pixels.
- On frames 3–6, a blue copy of the whole figure slides left by 6, 8, 10, 10 px
  at 35%, 35%, 23%, 10% opacity. The copy includes the feet and excludes only
  the flat ground-shadow bridge. It is behind the real figure and never changes
  any real foreground pixel. The visor star twinkles during the same beat.
- The real feet and their original pixels are identical in every frame.
  Additional translucent foot pixels belong only to the afterimage.
- Checked the full inner and right rag tips for pixels incorrectly left in the
  fixed-leg mask: zero remain.

## Checks and review

`pair_14_self_check.json` records zero mismatches for rigid body parts, complete
held parts, visible legs and protected pads, real foot regions, original foot
pixels, afterimage foreground preservation, and unexplained changes. No rigid
body pixels are clipped. Both saved strips are decoded and compared exactly
against the generated arrays.

Reviewed segmentation, frame 1/4 overlays, enlarged orb/glove and ring/knee
boundaries, backpack-light details and 0.37-scale contacts. Compared with the
approved Banner Marshal and Pathfinder strips (`pair_14_pilot_reference.png`).
Native and game-size GIFs, motion tables, masks and real-figure-only strips are
included alongside this report for review.
