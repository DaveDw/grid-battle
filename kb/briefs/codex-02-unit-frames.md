For: Codex
From: Claude
Output: art_incoming/<faction>/<unit>_*.png, plus one line per unit in art_incoming/progress.txt

# Brief: animation frames for every unit (the standard)

The approved reference sets are `terran/banner_marshal_idle.png` (idle) and `terran/pathfinder_attack.png` (attack). Match their quality.

## Files per unit
- `<unit>_idle.png`: 8 equal cells in one row, a looping idle.
- `<unit>_attack.png`: 2 cells. Frame 1 fires, with a bright yellow-white muzzle flash or impact flare at the weapon's tip. Frame 2 recoils.
- `<unit>_move_up.png`, `_move_down.png`, `_move_fwd.png`, `_move_back.png`: one cell each, a quick dash pose.
- Every image: flat #FF00FF background, facing RIGHT, pixel art matching `assets/sprites/<faction>/<unit>.png` exactly (design, colours, outline weight).

## Idle rules (this is what makes or breaks it)
1. **Lock the scale.** Use frame 1 as the master, and make every other frame an edit of it on the same canvas at the same scale. Head and boot sizes stay within 3% across all frames.
2. **The body moves gently.** It rises and dips 3-6% of its height over the cycle, at most 2% per frame step, eased.
3. **Secondary motion is big and visible in EVERY frame.** Scarves, capes, flags, coat tails, tentacles, drones, crystals, glows, smoke and sparks should move clearly, lagging the body by a frame. This is where the life is. Banner Marshal's flag is the bar; Pathfinder's first attempt, with only a 1-2 px scarf, was too little.
4. **Give it a themed beat.** Use the unit's plan in `kb/proposals/gemma-idle-motion.md` if it's there and sensible. Otherwise invent one that fits the unit (see `kb/roster.md`).
5. **Floating, mech or crystal units** hover, bob, rotate, pulse or vent instead of breathing. Their "feet" baseline is the bottom of the art.
6. **Check before saving:**
   - top-of-body travel is 3-6%;
   - the pixels that differ between frames 1 and 5 make up at least 3% of the art;
   - frames 8 and 1 are close.

## Attack rules
- The weapon points straight FORWARD, level, at chest or shoulder height. It never angles down at the floor.
- Melee units (sword, scythe, blade, shield bash): frame 1 is mid-strike with a bright flash at the impact point, and frame 2 is the follow-through.
- Use the same scale as idle frame 1.

## Per-unit weapon notes
- **terran:** banner_marshal (sword thrust, flag held high), siege_rig (mortar shell launching upward, flash at the barrel), claim_lord (heavy gauntlet shot), breacher (shield bash shot), standard_guard (rifle volley).
- **ascendancy:** chief_visionary (the drones fire a beam), synapse_brute (charged energy beam), field_scholar (precise laser), director_zero (blade energy pulse), protocol_warden (stun bolt), courtesy_android (polite little shot).
- **manyworlds:** tide_speaker (water bolt), reef_bulwark (undertow wave), reed_runner (rifle jab), prism_elder (refracted light ray), spore_keeper (spore burst), glasswing (wing-blade shot).
- **long:** mission_mother (medic drone shot), red_giant (ragged red blast), cinder_scout (ember shot), captain_everafter (scythe slash), deadweight (void gravity pulse), parallax (afterimage shot).

## Process
Work through the units in order without waiting for review. After each unit, append `<faction>/<unit> done` (or `<faction>/<unit> FAILED: reason`) to `art_incoming/progress.txt`. Art only: don't edit code or existing project files.
