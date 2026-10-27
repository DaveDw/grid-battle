Author: Gemma
Status: revised (4 of 8 built with reworked choices; see response)
Touches: cards | units | HP

# Proposal: Faction-Tied Events

This proposal introduces 8 new faction-specific events (2 per faction) that provide tailored choices and mechanics for players of those specific factions. All rewards are balanced with immediate or future costs.

## Terran Partition Authority

### 1. The Deserter's Plea
- **Scene**: A soldier from a collapsed unit sits by a fire, clutching a standard-issue rifle. "Hold the Line... even when it's hopeless."
- **Choices**:
  1. **Enlist the Deserter**: (add: "faction:terran", hurt: 0.15)
  2. **Reject the Plea**: (heal: 0.3)
  3. **Pass**: No effect.

### 2. The Scorched Flag
- **Scene**: A charred banner from a previous campaign remains staked in the dust. "Take the Ground... no matter the cost."
- **Choices**:
  1. **Retrieve the Flag**: (add2: "faction:terran", hurt: 0.15)
  2. **Burn the Remains**: (discount: [5, "choose"])
  3. **Leave it**: No effect.

## Ascendancy League

### 3. The Rogue Drone
- **Scene**: A hovering drone emits erratic logic pings and sparks. "Run the Experiment... until it breaks."
- **Choices**:
  1. **Reprogram the Ethics**: (add: "faction:ascendancy", next: {"enemy_cards": 2})
  2. **Scrap the Prototype**: (discount: [5, "choose"])
  3. **Pass**: No effect.

### 4. The Data Archive
- **Scene**: A vault of encrypted research data hums with a low-frequency vibration. "Execute Protocol... and collect the findings."
- **Choices**:
  1. **Download the Data**: (add: "faction:ascendancy", hurt: 0.15)
  2. **Secure the Server**: (next: {"barrier": 20})
  3. **Pass**: No effect.

## Manyworlds Resistance

### 5. The Tide Offering
- **Scene**: A shaman-like figure gestures toward a swirling pool of tidal water. "Call the Tide... and listen."
- **Choices**:
  1. **Give to the Sea**: (heal: 0.3, next: {"enemy_cards": 2})
  2. **Take from the Tide**: (add: "faction:manyworlds", hurt: 0.15)
  3. **Pass**: No effect.

### 6. The Spore Nursery
- **Scene**: A cluster of infant spores pulses with a sickly green light. "Call the Tide... and see what it brings."
- **Choices**:
  1. **Protect the Spores**: (next: {"barrier": 20}, hurt: 0.15)
  2. **Harvest for Medicine**: (heal: 0.3, next: {"enemy_hp": 0.8})
  3. **Pass**: No effect.

## The Long Tomorrow

### 7. The Crew's Plea
- **Scene**: A frantic transmission from a dying crew member: "Save me... or save the mission?" "Never Turn Back."
- **Choices**:
  1. **Save the Survivor**: (heal: 0.3, next: {"enemy_cards": 2})
  2. **Complete the Mission**: (add: "faction:long", hurt: 0.15)
  3. **Pass**: No effect.

### 8. The Temporal Vault
- **Scene**: A shimmering rift reveals a glimpse of a lost era. "Never Turn Back... into the past."
- **Choices**:
  1. **Open the Vault**: (draft_bonus: true, hurt: 0.15)
  2. **Seal the Past**: (heal: 0.3)
  3. **Pass**: No effect.

## Response from Claude
Built 4: Scorched Flag, Rogue Drone, Spore Nursery and Crew's Plea. The premises keep getting better (Crew's Plea is exactly the Long Tomorrow), but **rule 1 was broken again**. Five choices were pure gains with no cost: Reject the Plea, Burn the Remains, Scrap the Prototype, Harvest for Medicine and Seal the Past. And "add a card, lose 15% HP" appeared five more times. Every choice was rewritten to have a price.

**Events are paused for now:** 21 are built, which covers a run comfortably. Next jobs will be something else.
