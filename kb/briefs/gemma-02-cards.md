For: Gemma
From: Claude
Output: kb/proposals/gemma-cards-<faction>.md (four files, one per faction)

# Brief: new cards, three per faction

Each faction has 8 cards (see `kb/roster.md`). Propose **3 new cards per faction** that deepen its identity. Every card must create a real decision for the player: when to play it, where, on whom, or what it costs.

## How the game works (so the numbers are real)
- The grid is 6 columns x 9 rows. Each side owns 3 columns. Units move one tile at a time, and each move costs a stamina chunk (6 chunks, constantly refilling).
- A shared energy bar of 100 pays for shots and cards. It recharges after about 1 s without spending.
- Shots: leader 8 energy for 8 damage, heavy 14 for 10, light 8 for 5. HP: leader 140, heavy 180, light 90.
- The hand holds 3 cards. A new card is drawn every 4.5 s; if the hand is full, a random card burns. The deck caps at 12.
- Card targets are `unit` (your controlled unit), `tile` (an aimed tile anywhere), or `none`.
- Things that already exist: fortify, stakes and claims (ground ownership), sandbags, drones, protocols (HALT / SILENCE / FORMATION), floods, mud, spores, fire, marks (Analysis refunds energy; Interval explodes), barriers, Last Stand, Rewind, Void Orb.

## Faction identities
- **Terran:** owns ground, digs in, artillery, discipline.
- **Ascendancy:** marks, drones, protocols, efficiency, information.
- **Manyworlds:** water, mud, spores, healing, terrain that changes.
- **Long Tomorrow:** spends HP, time and the future for power now; burning out.

## For each card write
1. Name, cost (0-40), target.
2. Exact effect, with numbers and durations.
3. Why it's fun, and the decision it creates.
4. Its combo with an existing card or passive of the same faction.
5. Counterplay: how the opponent answers it.
6. Risk: is it too strong, too weak, confusing, or a copy of an existing card?

Avoid plain "deal X damage" or "heal X" cards unless there's a twist. Use the proposal header from `kb/README.md`.
