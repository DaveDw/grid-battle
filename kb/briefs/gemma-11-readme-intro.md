# Brief: README exposition (Gemma)

Status: done
Output: `kb/proposals/gemma-readme-intro.md`

## The job
Write the exposition that opens the project README: a short piece of in-world
storytelling that sets the scene before the README gets into features and controls.
It goes right under the title block, above "Contents".

Read these first. They are the source of truth; don't invent anything they contradict:
- `README.md`: the whole README as it stands; your piece goes on top of it.
- `kb/roster.md`: every unit and leader.
- `DESIGN.md`: the rules and squad kits, for flavour.

## The game, in brief
Grid Battle is a real-time squad tactics game on a split grid, with a deck-building
roguelike campaign around it. Two squads face each other across a line down the middle
of the board. You claim **sectors** across a star map, fight three battles per sector
(the third against a **commander**), draft cards and try to claim enough sectors to win.

Four factions fight over the sectors:
- **Terran Partition Authority**: Old-Earth order enforced in steel. Holds ground,
  fortifies tiles, punishes anyone who steps out of line. Leaders: Banner Marshal
  ("Hold the Line"), Claim Lord ("Take the Ground").
- **Ascendancy League**: clean-room science with a smile. Drones, protocols and
  experiments run on the battlefield as if it were a lab. Leaders: Chief Visionary
  ("Run the Experiment"), Director Zero ("Execute Protocol").
- **Manyworlds Resistance**: refugees from a hundred worlds. Strange biology, stranger
  tactics, and terrain that fights back. Leaders: Tide Speaker ("Call the Tide"), Prism
  Elder ("Refract the Fight").
- **The Long Tomorrow**: lost colonists returned from the interval. Decayed, patient,
  and carrying powers no one sent them out with. Leaders: Mission Mother ("Keep Them
  Alive"), Captain Everafter ("Never Turn Back").

## What to write
- **Length:** 120–200 words. Two to four short paragraphs, then one closing line of
  direct address to the player that leads into the game ("Pick a leader..." or similar).
- **Voice:** terse, evocative sci-fi; the tone of a campaign briefing or the back of a
  box. Present tense. No purple prose, no clichés like "in a galaxy torn by war".
- **Must cover:** the contested sectors and why they matter; all four factions, one
  vivid sentence or clause each, true to the blurbs above; the line down the middle
  of the battlefield (ground is taken and lost tile by tile).
- **Must not:** invent named planets, characters, dates or history that isn't in the
  files; contradict a mechanic (for example, no permadeath of the player or base
  building); mention AI, Godot or development; use em-dash chains.
- Write in Markdown. You may use a `>` blockquote or italics, but no headings; the
  README already has its own.

## Proposal format
Follow `kb/README.md` ("Writing a proposal"). Put the exposition in a fenced block
marked `markdown` so it can be pasted as is. Underneath, list in 2–4 bullets
which facts you drew from which file.
