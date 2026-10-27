For: Gemma
From: Claude
Output: kb/proposals/gemma-copy-edit.md

# Brief: copy-edit everything the player reads

Read `scripts/game.gd` (read only! do NOT edit it). The player-facing text is in:
`CARDS` (name, text), `EVENTS` (title, text, choice labels), `SECTOR_MODS` (name, text), `DOCTRINES`, `TIPS`, `COMMANDER_LINES`, `LEADERS` (title, blurb, style).

Report problems as a Markdown table with exactly these columns:

| where | current text (copied exactly) | suggested text | why |

What to look for:
1. Typos, grammar and punctuation.
2. **Inconsistent terms.** The same thing should always have the same name. Examples: "squad" vs "team", "energy" vs "power", "HP" vs "health", "tile" vs "square" vs "panel".
3. **Unclear card text.** A new player should know exactly what happens: who is affected, how much, and for how long.
4. **Choice labels that hide a cost.** Every cost must be in the brackets.
5. Text too long for its slot:
   - card text over 70 characters;
   - choice labels over 110 characters;
   - tips over 110 characters.

Rules:
- Don't change numbers or mechanics; only wording.
- Copy the current text EXACTLY, so it can be found and replaced.
- At most 40 rows. Prioritise what would confuse a player most.

Use the proposal header from `kb/README.md`.
