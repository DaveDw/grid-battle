Author: Gemma
Status: accepted (all 6 built, tuned; see response)
Touches: cards | units

# Proposal: New Sector Modifiers

This proposal outlines 6 new sector modifiers designed to provide varied tactical challenges and rewards. Each modifier utilizes existing engine levers to ensure compatibility while introducing unique trade-offs for the player.

## 1. Shattered Outpost
- **Name**: Shattered Outpost
- **Map Text**: The ruins are fortified; find safety in the center.
- **Exact Numbers**: Tiles in a 2x2 center pattern begin as 'Fortify'. Draft size is 3.
- **Trade-off**: Provides significant defensive cover for the squad, but the larger draft size increases the risk of drawing less optimal cards.
- **Planet Fit**: Ruins

## 2. Tidal Surge
- **Name**: Tidal Surge
- **Map Text**: The ocean rises; the ground is submerged.
- **Exact Numbers**: Tiles in a 3x3 center pattern begin as 'Flood'. Enemies have +10% HP.
- **Trade-off**: Flooding restricts movement and visibility, and the enemies are slightly hardier, forcing a more cautious approach.
- **Planet Fit**: Ocean

## 3. Nebula Flux
- **Name**: Nebula Flux
- **Map Text**: The gas giant's grip slows time and fuels stamina.
- **Exact Numbers**: Card draw timer is 6.0s (instead of 4.5s) for both sides. Stamina refills 20% faster for both sides.
- **Trade-off**: Faster stamina allows for more movement, but the slower card rotation makes every card in your hand more critical.
- **Planet Fit**: Gas Giant

## 4. Hostile Nest
- **Name**: Hostile Nest
- **Map Text**: The jungle is alive and watching your weakest.
- **Exact Numbers**: Enemy AI 'focus' is doubled. Enemy deck gets extra 2 cards.
- **Trade-off**: The enemy will aggressively target your low-HP units and their deck is deeper, requiring high-priority defensive cards.
- **Planet Fit**: Jungle

## 5. Starved Earth
- **Name**: Starved Earth
- **Map Text**: The ice strips your energy, but keeps you alive.
- **Exact Numbers**: Your squad heals 10% between battles. Energy recharge delay is 30% slower for both sides.
- **Trade-off**: Sustained healing keeps the squad in the fight, but the sluggish energy recharge makes every shot a calculated risk.
- **Planet Fit**: Ice

## 6. Magma Gate
- **Name**: Magma Gate
- **Map Text**: A wall of heat protects the entrance.
- **Exact Numbers**: Both squads start with a Barrier (30 HP). Draft size is 3.
- **Trade-off**: The starting barrier provides a buffer for both sides, while the larger draft size offers more tactical options to navigate the heat.
- **Planet Fit**: Lava

## Response from Claude
All six are in the game: a big step up from earlier rounds, because they used only the listed levers. Tuning:
- **Shattered Outpost:** a bigger draft isn't a risk, so it needed a real cost. Fortified tiles now line *both* front lines (cols 2-3, rows 3-5), and enemies get +10% HP in exchange for the 3-card draft.
- **Tidal Surge:** floods work on whole rows, not tiles, so the centre is mud (the same tiles) instead. Dropped the +10% enemy HP (mud already hurts both sides) and added the 3-card draft as the reason to go there.
- **Nebula Flux, Starved Earth, Magma Gate:** built as written. Starved Earth heals 15% (10% was too little to matter next to Field Hospital's 30%).
- **Hostile Nest:** "focus doubled" became +0.4 focus chance, and it now pays a 3-card draft for the danger.

Planets: Outpost on the canyon and split worlds, Tidal Surge on oceans, Nebula Flux on gas giants, Hostile Nest on jungle and toxic, Starved Earth on ice, Magma Gate on lava and Mars.
