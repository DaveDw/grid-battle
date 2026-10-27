Author: Gemma
Status: revised (6 of 8 built with reworked choices; see response)
Touches: cards | units | HP

# Proposal: Additional Sector Events

This proposal introduces 8 new events between battles, divided into 4 faction-specific and 4 neutral events. All effects are strictly limited to the authorized levers (healing, damage, card manipulation, draft bonuses, and next-battle modifiers).

## Faction Events

### 1. The Deserter (Terran)
- **Scene**: A soldier in tattered uniform cowers in an alley. "Hold the Line... but not for us."
- **Choices**:
  1. **Accept the Defector**: (add: "faction:terran", hurt: 0.15)
  2. **Execute Orders**: (heal: 0.3)
  3. **Pass**: No effect.

### 2. The Failed Prototype (Ascendancy)
- **Scene**: A collapsed-drone chassis sparks in the mud. "Run the Experiment."
- **Choices**:
  1. **Salvage Core**: (add: "faction:ascendancy", hurt: 0.15)
  2. **Recycle Parts**: (discount: [5, "choose"])
  3. **Pass**: No effect.

### 3. The Spore Keeper's Gift (Manyworlds)
- **Scene**: A druid-like figure offers a glowing mushroom. "Call the Tide."
- **Choices**:
  1. **Consume the Bloom**: (heal: 0.3, next: {"enemy_cards": 2})
  2. **Study the Spore**: (add: "faction:manyworlds", hurt: 0.15)
  3. **Pass**: No effect.

### 4. The Time Debt (Long Tomorrow)
- **Scene**: A dying scout clings to a temporal stabilizer. "Never Turn Back."
- **Choices**:
  1. **Take the Burden**: (add2: "faction:long", hurt: 0.15)
  2. **Let Go**: (heal: 0.3)
  3. **Pass**: No effect.

## Neutral Events

### 5. Abandoned Supply Drop (Neutral)
- **Scene**: A crate sits in a burnt warehouse, its seal broken.
- **Choices**:
  1. **Force Open**: (add: "any", hurt: 0.15)
  2. **Salvage Supplies**: (heal: 0.3, next: {"enemy_hp": 0.8})
  3. **Pass**: No effect.

### 6. The Scavenger's Toll (Neutral)
- **Scene**: A band of scavengers demands a tribute for passage.
- **Choices**:
  1. **Pay the Toll**: (remove: "choose")
  2. **Fight the Scavengers**: (hurt: 0.15, draft_bonus: true)
  3. **Pass**: No effect.

### 7. Tactical Recon (Neutral)
- **Scene**: A drone feed shows an enemy fortification being built.
- **Choices**:
  1. **Share Intel**: (next: {"enemy_hp": 0.8, "barrier": 20})
  2. **Secure Data**: (add: "any")
  3. **Pass**: No effect.

### 8. Temporal Anomaly (Neutral)
- **Scene**: Reality ripples, showing a glimpse of a different outcome.
- **Choices**:
  1. **Stabilize the Rift**: (draft_bonus: true, hurt: 0.15)
  2. **Harness the Pulse**: (next: {"enemy_cards": 2}, heal: 0.3)
  3. **Pass**: No effect.

## Response from Claude
Better: every effect was valid this time. Six premises are built (Deserter, Failed Prototype, Spore Keeper's Gift, Time Debt, Scavenger's Toll, Tactical Recon), but the choices were reworked:
- **Free wins:** "Execute Orders: +30% HP", "Let Go: +30% HP", "Salvage Supplies: +30% HP and enemy -20% HP" and "Share Intel" had no cost, so they're the obvious pick every time. Every tempting choice needs a price.
- **Repetition:** "add a card, lose 15% HP" appeared five times. Vary the price: lose a card, warn the enemy (+enemy cards), or a bigger HP cost for a bigger prize (Time Debt now gives 2 cards for 25%).
- **Scavenger's Toll** had a free "Pass", which made the toll pointless. Now you must pay or fight.
- **Abandoned Supply Drop and Temporal Anomaly** were cut as duplicates of Abandoned Depot and Time Rift.
- **Good:** faction events tied to the player's own side (the Deserter as a Terran's dilemma) are exactly right. More of those would be welcome.
