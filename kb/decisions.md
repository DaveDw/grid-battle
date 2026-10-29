# Decisions

Log of accepted, rejected and revised proposals. Claude writes here; newest at the top.

## 2026-10-27
- **Rejected:** gemma-copy-edit (hallucinated strings). Gemma is kept to open-ended idea and voice work; text checks are scripted.
- **Built:** 4 faction events from gemma-events-3 (rewritten choices). 21 events total; events paused. Added a Units screen (all 24 units animated, with kits) and run stats (end screens).
- **Built:** 6 more events from gemma-events-2 (4 faction-only, 2 neutral) with reworked choices; 17 events total.
- **Built:** 6 sector modifiers from Gemma (Shattered Outpost, Tidal Surge, Nebula Flux, Hostile Nest, Starved Earth, Magma Gate). Modifiers are now data-driven (SECTOR_MODS fx levers). Test s11: 0 fails.
- **Built:** commander voice lines from Gemma (taunt at the battle start, defeat line on the victory screen).
- **Built:** 15 of Gemma's 30 tips (fact-checked; 7 were false). Shown on the defeat screen and the sector map.
- **Built:** events between battles (50% chance after a mid-sector draft; Game.EVENTS, scenes/event.tscn). 3 by Claude plus 8 rewritten from gemma-events. Effects: heal, hurt, add, remove, discount, next {enemy_hp, barrier, enemy_cards}, draft_bonus. Tests s9 and s10: 0 fails.
- **Built (from gemma-cards-long):** Flash Forward and Collapse. Rejected: Time Echo. Every faction now offers 9-10 draftable cards. Test s8: 0 fails.
- **Built (from gemma-cards-*):** Supply Drop and Dig In (Terran), Data Breach (Ascendancy), Tide Pool (Manyworlds). Rejected: Sentry Turret, Drone Swarm, Core Overload, Coral Shelf, Spore Cloud (duplicates or broken). Test s8: 0 fails.
- **Revised:** gemma-idle-motion accepted as inspiration for Codex (the sprite wins on conflicts). Feedback is in the proposal.
- **Accepted:** the Banner Marshal idle (body steady, flag ripples every frame) and the Pathfinder attack (rifle level and forward) are the reference quality for the rollout. Standard: kb/briefs/codex-02-unit-frames.md.
- **Accepted (human + Claude):** units get 8-frame idle loops, 2-frame attacks and 4 single-frame move poses. Idles must feel alive and themed, not just breathing. The import tool flags loops whose top-of-art travel is under 4%.
- **Accepted:** the Pathfinder attack is to be redrawn with the rifle level and pointing forward.
- 2026-10-29: README intro: Gemma's gemma-readme-intro.md accepted with fact fixes (Long Tomorrow origin, no strip between sides).
