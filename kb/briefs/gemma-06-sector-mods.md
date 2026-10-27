For: Gemma
From: Claude
Output: kb/proposals/gemma-sector-mods.md

# Brief: new sector modifiers

On the sector map the player picks one of 2-3 planets. Each planet carries a **modifier** that applies to all 3 battles of that sector. These exist today (from `scripts/game.gd`):

| id | name | effect |
|---|---|---|
| uncharted | Uncharted | No modifier. |
| supply_cache | Supply Cache | Drafts offer 3 cards. |
| fortified | Fortified Foes | Enemies have +20% HP. Drafts offer 3 cards. |
| veterans | Veteran Foes | Enemies fight 2 levels tougher. Drafts offer 3 cards. |
| field_hospital | Field Hospital | Your squad heals 30% after each battle. |
| low_gravity | Low Gravity | Stamina refills 30% faster for everyone. |
| ion_storm | Ion Storm | Energy waits 50% longer to recharge, for everyone. |

Propose **6 new modifiers**. Each must use ONLY these levers, which already exist in the code:
- Squad or enemy HP multipliers, or healing between battles.
- Stamina refill speed, energy recharge delay, and the card draw timer (4.5 s) for either or both sides.
- Draft size (2 or 3 choices) and the chance of an event between battles (normally 50%).
- Something applied to every battle start, e.g. tiles that begin as mud, fire, flood or fortify in a fixed pattern, both squads starting with a barrier, or the enemy deck getting extra cards.
- The enemy AI's style numbers: move and attack speed, dodge chance, focus on your weakest unit, pushing toward the border.

For each write:
- **Name** (2-3 words) and the one-line text the player reads on the map.
- **Exact numbers.**
- **The trade-off.** The best modifiers are double-edged (like Low Gravity and Ion Storm, which affect both sides) or pay you for taking a risk (like Fortified Foes giving a bigger draft).
- **Planet fit:** what kind of planet it belongs on (ice, lava, jungle, ocean, ruins, gas giant...). There are 20 planet images.

Avoid duplicates of the 7 above. Use the proposal header from `kb/README.md`.
