For: Codex
From: Claude
Output: overwrite art_incoming/<faction>/<unit>_idle.png, then append one line to art_incoming/redo_progress.txt: `<faction>/<unit> redone` (or `<faction>/<unit> FAILED: reason`)

# Brief: redo the idle animations (rigid parts stay rigid)

The current idles were rejected. Most of them ripple or bend things that are solid: rifles, armour plates, helmets, mech legs, shields, scythe poles, coats and capes. It reads as the whole sprite melting. **This overrides rule 3 ("big secondary motion in every frame") of codex-02-unit-frames.md. That rule is cancelled.**

Two idles were approved, so match them: `ascendancy/chief_visionary_idle.png` and `manyworlds/prism_elder_idle.png`. Both keep the character solid. The life comes from separate pieces (drones, crystals) moving as whole objects, plus glows.

Leave those two units alone. Redo the other 22 below.

## How to build every frame (cut-out animation, not redrawing)
1. Frame 1 is the master. It is the current idle frame 1, or the base sprite `assets/sprites/<faction>/<unit>.png` on the same canvas and scale.
2. Every other frame is frame 1 with **whole parts moved**. Cut the part out (head, torso + arms + weapon, a drone, a pincer) and shift it by whole pixels, or rotate it by at most 4° only where the per-unit notes allow. Then repaint only the 1-3 px seam it uncovers.
3. **Rigid parts keep their exact pixels. They only move as a whole.** Rigid parts are weapons, guns, blades, shields, armour, helmets, visors, metal, robots, mechs, poles, staffs, glass, crystals, shells and rock. Do not bend, ripple, stretch or redraw them.
4. **Cloth does not wave.** Coats, capes, scarves and torn rags move only with the body they hang from. The one exception is Banner Marshal's flag cloth.
5. Glow, light, fire, smoke, sparks, particles and screen pixels may change freely. Use them for life.
6. Feet stay planted on the same pixels in all 8 frames, unless a unit's notes say it floats.

## Motion budget (cells are 384 px; characters are about 250 px tall)
- **Breath:** move the upper body (head, torso, arms and held weapon, all together) down 2 px over frames 2-4, then back up over frames 5-8. Legs stay put. The total travel is 2-4 px, not more.
- **One themed beat per unit,** as listed below. It happens once in the loop and lasts 2-4 frames.
- Frame 8 must lead smoothly back into frame 1.

## Per-unit spec

### terran
- **banner_marshal:** Breath only on the body. The flag CLOTH waves: a gentle travelling ripple. The pole stays straight and rigid, held still in the hand. The sword is held still. The cap and coat are rigid.
- **siege_rig** (mech, no breath): Hydraulic settle: the hull, mortar and side cannon drop 2 px together on frames 3-5 while the feet stay locked, then rise back. Beat: on frames 5-6 the mortar barrel ticks up 2° as one rigid piece, then back down. The orange canister bands light up in sequence, one per frame. A small grey vent puff rises from the top and fades.
- **pathfinder:** Breath, with the rifle locked to the hands so it moves exactly with the torso. Beat: the head turns slightly. Shift it 1 px forward on frames 4-6 while the eyes glance, and the visor screen glints. Blink once. The scarf moves only with the body.
- **claim_lord:** Breath. Beat: the gauntlet knuckles glow, then fade, on frames 3-6. Blink once. The cape and armour move only with the body.
- **breacher:** Breath, with the shield locked to the arm. Beat: the orange visor light sweeps left to right across the visor slit, while the helmet itself doesn't move. The shield emblem pulses brighter on frames 4-5.
- **standard_guard:** Breath, with the rifle locked to the hands. Beat: the visor stripe glow sweeps across once. The rifle's cyan light blinks on frames 2 and 6.

### ascendancy
- **synapse_brute:** Breath. Beat: the cyan core in the arm cannon charges from dim to bright over frames 2-5, then dims. Glints on the glasses. The back cables move only with the body.
- **field_scholar:** Breath. Beat: the head dips 1 px toward the tablet on frames 3-5, then back up. The tablet screen shows scrolling data (changing pixels, not the frame moving). The glasses glint. The pistol is rigid and locked to the hand.
- **director_zero** (floats): The whole blade body bobs 4 px up and down as a single rigid object, eased. The two hands bob the same way, one frame behind the body. The halo arcs bob with the body and pulse brightness. The red eye light blinks off on frame 5. Nothing bends.
- **protocol_warden** (robot, no breath): The sphere body and arms drop 2 px on frames 3-5, with the legs fixed. Beat: the cyan chest lens pulses, and the side eye lens shifts its pupil 1-2 px, looking around.
- **courtesy_android** (robot): Beat: a polite head tilt. Rotate the head 4° as a rigid piece on frames 3-6, then return. The eye light blinks. The arm gun is rigid and doesn't move. There is no breath; at most a 1 px servo dip.

### manyworlds
- **tide_speaker:** Breath on the head and the bowl. The glowing orb bobs 3 px as a whole object and pulses. Tentacles do not ripple along their length. Only the last 10-15 px of each tentacle tip curls slightly in or out once, and the rest of each tentacle stays fixed. The brass bowl is rigid. The water sparkles can twinkle.
- **reef_bulwark:** Breath, with the shell rigid and the claw-shield locked to the arm. Beat: the pincer opens and closes. The upper pincer jaw rotates 4° as a rigid piece on frames 3-5. The eyes glow.
- **reed_runner:** Breath, with the rifle locked to the hands. Beat: the throat pouch inflates and deflates on frames 3-6 (soft skin can swell). Blink. The scarf moves only with the body.
- **spore_keeper:** Breath. The mushroom caps are rigid and move only with the body. Beat: a puff of spore particles drifts up from the caps and fades. The green glow at the launcher pulses, and its green orbs drift up 2-4 px. The moss doesn't ripple.
- **glasswing:** Breath. Wings: flick each rigid wing panel between its normal angle and 3° raised, on alternate frames, like a buzz. Never bend the wing shape. The blades are rigid and locked to the hands. The antennae twitch: rotate them 3° as rigid pieces once.

### long
- **mission_mother:** Breath. The two med drones bob 3 px as whole objects, out of phase with each other, like Chief Visionary's drones. Their tubes follow the drone and keep the same shape, moving as a piece. The pointing arm is rigid with the body. The coat moves only with the body. The red crosses blink.
- **red_giant:** Heavy breath, 3 px. Beat: the lava cracks brighten from orange to yellow-white over frames 3-5, then dim back. A few embers rise from the cracks and fade. The rocks and armour are rigid.
- **cinder_scout:** Breath. The flame in the hand flickers (fire may change shape freely), and small embers rise. The knife is rigid and locked to the hand. The helmet glass glints.
- **captain_everafter:** Breath, with the scythe locked to the hand. The pole stays straight and the blade keeps its exact shape. Beat: the purple edge glow on the blade pulses bright on frames 3-5. A faint light glides across the helmet glass. The cape and rags move only with the body.
- **deadweight:** Breath. Beat: the void orb's inside swirls (inner pixels rotate) and its purple rim pulses. The gloves are rigid on the orb. The backpack lights blink.
- **parallax:** Breath. Beat (the afterimage): on frames 3-6 a faint blue translucent copy of the whole unit, at 35% opacity, slides 6-10 px back from the body and fades out. The real unit doesn't move except for breath. The star in the visor twinkles. The ring staff is rigid. The rags move only with the body.

## Check every unit before saving it. I will reject any unit that fails one of these.
- Overlay frame 1 and frame 4. Every rigid part either matches exactly or is the same shape shifted by whole pixels. If its outline changed, redo it.
- The feet pixels are identical in all 8 frames (except director_zero).
- The scale is identical in every frame: same head size, same weapon length.
- There is visible life: the beat and the glows are clearly visible at game size.

## Then the outstanding fix
After the 22 idles, do `long/captain_everafter_attack.png`: frame 1 is drawn smaller than frame 2 and the idle. Redraw frame 1 at the same scale. Log it as `long/captain_everafter attack redone`.

## Order and process
Do the units in the order listed, without waiting for review. Art only: don't edit code or other project files.

## Pilot review (Claude, after banner_marshal + pathfinder)
**Approved method.** The rigid parts are clean: the motion map shows the upper body moving as one piece and the legs fixed, with no warping. The flag ripple is good. Keep this exact approach.

**Rejected: the motion is too small to see.** Units render about 112 px tall on screen, so a body of about 300 px is scaled to 0.37. A 2 px breath becomes 0.7 screen px, which reads as a static image (the original complaint). New budget:
- **Breath:** upper-body offsets of 0, 2, 4, 6, 6, 4, 2, 0 px (6 px peak). Fill the waist seam by repeating the belt or waist rows. The waist is soft, so this is allowed; it's the only stretch allowed.
- **Head beats** (glance or turn): 3-4 px, not 1.
- **Floating units, drones and orbs:** 8-10 px bob.
- **Mechs** (siege_rig, protocol_warden): a 5-6 px hydraulic dip.
- **Glows, glints and blinks:** high contrast, so they read at 0.37 scale. A glint needs at least a 4×4 px bright patch.
- Rotations of pincers, mortar, antennae or head: 4-6°.

**Process changes:**
- Do NOT run Godot. I import after review.
- Write each finished strip straight to `art_incoming/<faction>/<unit>_idle.png`, and log it in `art_incoming/redo_progress.txt`.
- Review images may go in `art_incoming/<faction>/idle_redo_review/`.
- Redo the two pilots with the bigger budget, then continue with all the other units without stopping.

## User review (2026-10-28): the pilots are the standard
**Approved and imported:** banner_marshal and pathfinder. The user says they are better than Chief Visionary and Prism Elder. They are now **the reference for every unit**: match their motion size, their rigid cut-out method, and their clean seams. Open `art_incoming/terran/banner_marshal_idle.png` and `pathfinder_idle.png` and compare against them before you save anything.

**Motion size: match the pilots, not the "Pilot review" budget above.** That section was never sent and is withdrawn. Use the pilots' scale: body bob 0,1,1,2,2,1,1,0 px; head or glance shifts about 1 px; cloth or flag up to 4 px; glows and blinks clearly visible. Mechs dip about 2 px, and floaters bob about 3-4 px.

**New process: two units at a time.**
- Do the next two units in the order listed, then STOP and say "pair done: <unit>, <unit>".
- Log each in `art_incoming/redo_progress.txt` as before. Do NOT run Godot.
- Wait for my review. I will reply "approved" or list fixes. Only then start the next pair.
- Next pair: **terran/siege_rig + terran/claim_lord**. Then breacher + standard_guard, and so on down the list.

## Red Giant and Cinder Scout are yours again (2026-10-28)
Claude tried long/red_giant and long/cinder_scout with its own tool, and the user rejected them. Do both in their normal place in the order, with your method. The idles in assets/ for these two are Claude's attempts: don't build from them. Build from the base sprites (assets/sprites/long/<unit>.png) or art_backup/idle_v1/, and clean the ember squares frozen in the old idles.

## Extra pair: Chief Visionary and Prism Elder (added 2026-10-28)
The user wants to see these two redone to the Banner Marshal / Pathfinder standard, after deadweight + parallax. Their current idles were the earlier reference; they are backed up in `art_backup/idle_v1/ascendancy/chief_visionary_idle.png` and `art_backup/idle_v1/manyworlds/prism_elder_idle.png`.
- Keep what worked: drones (Chief Visionary) and crystals (Prism Elder) move as whole objects, plus glows.
- Bring them up to the standard: rigid cut-out body breath (0,1,1,2,2,1,1,0), head about 1 px, legs planted, clean seams, no frozen particles or stray blobs.
- Write to `art_incoming/ascendancy/chief_visionary_idle.png` and `art_incoming/manyworlds/prism_elder_idle.png`, log `ascendancy/chief_visionary redone` and `manyworlds/prism_elder redone` in `art_incoming/redo_progress.txt`, then stop for review. The user will compare old and new before anything is imported.
