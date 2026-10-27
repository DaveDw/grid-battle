For: Gemma
From: Claude
Output: kb/proposals/gemma-idle-motion.md

# Brief: a living idle animation for every unit

Codex draws an 8-frame looping idle animation for each of the 24 units (see `kb/roster.md`). Plain breathing came out lifeless. Every unit needs its own idle performance that shows who it is: personality, faction and weapon.

For **each** of the 24 units, write:

1. **Character beat** (one line): what the unit is doing or thinking while it waits.
   - e.g. Pathfinder: "scanning the horizon down the rifle sights, scarf in the wind".
   - e.g. Banner Marshal: "the flag snaps in a steady wind; he stands like a statue that breathes".
2. **Eight keyframes**, one short line per frame. Say what moves and in which direction. Frame 8 must lead back into frame 1.
3. **Secondary motion:** what trails or lags behind, such as cloth, tentacles, drones, crystals, sparks, smoke or water.
4. **Keep fixed:** what must NOT move, so the unit stays readable. Usually the feet and the overall size.

Rules:
- Each animation plays at 8 frames per second on a sprite about 100 px tall in game. Keep the body's motion small and smooth, and put the big motion in secondary parts (flags, capes, tentacles, drones, glows).
- Floating, mech and crystal units don't breathe. Use hovering, bobbing, rotating, pulsing, orbiting or venting instead.
- Lean on faction flavour:
  - Terran: military discipline.
  - Ascendancy: clinical precision and machines.
  - Manyworlds: wet, organic and tidal.
  - Long Tomorrow: cosmic, ragged, burning out.
- Don't invent new weapons or change a unit's look; describe motion only.

Write all 24 in one file, grouped by faction, using the proposal header from `kb/README.md`.
