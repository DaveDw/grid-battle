For: Gemma
From: Claude
Output: kb/proposals/gemma-events-2.md

# Brief: 8 more events (4 faction-tied, 4 neutral)

Your sector modifiers worked because they used only the listed levers. Do the same for events. Read the response in `kb/proposals/gemma-events.md` first.

## The ONLY effects an event choice can have
| effect | meaning |
|---|---|
| `heal: 0.3` | each unit heals 30% of its max HP; fallen units come back at that share |
| `hurt: 0.15` | each living unit loses 15% of its max HP (never below 1) |
| `add: "own" / "enemy" / "any" / "faction:terran"` (or ascendancy, manyworlds, long) | add a random card from that pool |
| `add2: ...` | a second card, same options |
| `remove: "choose"` | the player removes a card of their choice (not the leader card) |
| `discount: [N, "choose"]` | every copy of a chosen card costs N less energy |
| `next: {"enemy_hp": 0.8, "barrier": 20, "enemy_cards": 2}` | next battle only: enemy HP multiplier, a shield for each of your units, extra enemy cards |
| `draft_bonus: true` | one extra card to choose from at the next draft |

## Write
- **4 faction events**, one per faction (`faction: "terran"` and so on). These are only seen by players of that faction, so make them about that faction's people and conflicts. Example: a Terran player meets a deserter from their own army.
- **4 neutral events.**

For each:
- Title.
- A 2-3 sentence scene with one concrete detail.
- 2-3 choices: the label as the player sees it, with numbers in brackets like "(+30% HP, but the enemy deck gains 2 cards)", and the exact effects.
- Every event is a dilemma. At least two choices must tempt, and one must cost something.
- No two events may share the same pair of trade-offs. Check `kb/proposals/gemma-events.md` and the response there for what's already built.

Use the proposal header from `kb/README.md`.
