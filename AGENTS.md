# Grid Battle — project notes (read this first)

Godot 4.7 grid-combat game, heading toward a squad deck-building roguelike (leader + heavy + light per side, faction cards that target units or tiles). Art: the faction sprites in assets/sprites. Window 1280x720.

## Rules
- Godot 4 GDScript only: typed vars, `@onready`, `@export`, `signal.emit()`, `Input.is_action_just_pressed`. No Godot 3 syntax (`yield`, `onready var`, `KinematicBody2D`, `emit_signal` strings).
- Progress lives in `PROGRESS.md` (status checklist, stage specs, session log). Read it after this file.
- Do NOT edit AGENTS.md (Hermes requires approval for it and the prompt times out). Record progress in PROGRESS.md instead.
- Work on ONE stage per session. Finish it, verify it, tick it and add a log line in PROGRESS.md, then stop and report.
- Editing existing files: use `patch`. `write_file` on an existing file is refused unless you `read_file` it first in this session.
- Keep tool output small: don't re-read files you don't need; read only the files the current stage touches.
- Never claim a stage works unless the verify run below is clean.

## Verify (Git Bash, run from the project folder)
```
GODOT="/c/Users/ddwig/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
"$GODOT" --headless --path . --import 2>&1 | grep -iE "error|invalid" | head -20
"$GODOT" --headless --path . --quit-after 300 2>&1 | grep -iE "error|invalid" | head -20
```
No output from the grep = clean. Fix every SCRIPT ERROR / parse error before moving on.

## Architecture (as built, v2 test environment)
- `scenes/main.tscn` (main scene): Background ColorRect (1280x720) + Battlefield instance.
- `scenes/battlefield.tscn` + `scripts/battlefield.gd`: draws the grid and runs the battle.
  - Grid: `COLS=6, ROWS=9, PANEL_W=150, PANEL_H=46, GRID_X=190, GRID_Y=160, PLAYER_MAX_COL=2` (cols 0-2 player side, 3-5 enemy side). `panel_center(col,row)`, `unit_at(col,row)`, `can_move(unit,col,row)` (own side, on grid, tile free).
  - `SQUADS` const: 3 units per side (name, sprite, role leader/heavy/light, hp, height, muzzle, starting cell). Units are spawned in `_ready()`; `player_units` / `enemy_units` arrays; `active_idx` = the unit under control.
  - Input: arrows move the active unit (costs 1 stamina chunk via `stamina.try_spend()`), Q/E (`swap_prev`/`swap_next`) cycle control to the next living unit, Z (`buster`) fires a test shot costing `SHOT_COST` energy via `energy.try_spend()`.
  - Shots: dicts in `shots` (`team`, `row`, `pos`, `dir`, `dmg`), hit the first living opposing unit in that row. `fire(unit)` spawns one from the unit's muzzle.
  - Battle ends when one side has no living units: `_show_over()` shows the `OverScreen` CanvasLayer; Enter reloads.
  - `y_sort_enabled` so lower rows draw in front.
- `scripts/unit.gd` (`Unit`): one fighter, either team. `setup(bf, data, team)` builds its `FighterSprite`. `move_to(c,r)` slides between tiles, `take_damage(n)`, signals `hp_changed(unit)`, `killed(unit)`. Draws a pulsing ring under the controlled unit. Enemy units run a placeholder AI (wander to adjacent tiles, telegraph 0.6s, row shot).
- `scripts/fighter_sprite.gd` (`FighterSprite`): character art + procedural animations (idle breathing, `play_attack`, `play_windup`, `play_hit`, `play_land`, `play_death`), `muzzle_point()`, `get_texture()`.
- HUD (`$HUD` CanvasLayer in battlefield.tscn):
  - `scripts/energy_bar.gd` (`EnergyBar`): shared energy 0-100. `try_spend(cost)`; recharges at 30/s after 1.5s with no spend. Spend animation: white ghost of the lost amount drains away + sparks; recharge shimmer; red shake on deny.
  - `scripts/stamina_bar.gd` (`StaminaBar`): 6 segments, one refills every 0.75s continuously. `try_spend()` breaks the top chunk off as tumbling shards; red shake on deny.
  - `scripts/health_bar.gd` (`HealthBar`): fighting-game bar per unit (portrait, name, role, slanted fill, red damage trail). Player bars top-left, enemy bars top-right mirrored; the controlled unit's bar is lit. Created in `battlefield._ready()`.
- Sprites: `assets/sprites/<terran|ascendancy|manyworlds|long>/<name>.png` (24 characters, cut by `tools/extract_sprites.gd`). Sheet tiers: L = light, H = heavy, C/LEADER = leader.
- Input: `scripts/input_layout.gd` (`InputLayout.apply()`, called by the Game autoload) defines every action for keyboard + mouse (WASD, Q/E, Space or right-click, 1-3, Esc), controller (D-pad, L1/R1, A, X/Y/B, right stick aim, R2 confirm, L2 cancel, Start) and touch (taps arrive as mouse clicks). Battle pause is the `pause` action; `ui_cancel` (Esc / B) is for menus.
- Previous single-unit version (with the chip menu) is backed up in `../grid-battle-v1-backup`.

## Menus and runs (v0.2)
- Main scene is `scenes/main_menu.tscn`; the battle is `scenes/main.tscn`.
- `scripts/game.gd` is the autoload `Game`: `FACTIONS`, `ROLES` (hp/height per role), `UNITS` (name + muzzle per sprite), `LEADERS` (8 leaders, each with its bundled `heavy` and `light`, plus `title`, `blurb`, `style`, `difficulty`). Squad abilities (primary fire, passives, cards) are designed in `DESIGN.md`, `squad_for(leader_id, enemy)`, save slots (`user://saves/slot_N.json`, 3 slots: `new_run`, `load_run`, `save_run`, `win_battle`, `end_run`, `delete_slot`, `latest_slot`), settings (`user://settings.cfg`), the shared UI `theme`, and `go(scene)` fade transitions.
- Screens (UI built in code, root Control + script): `main_menu` (Continue, Start New Run, Load Run, Settings, How to Play, Credits, Quit), `character_select` (leaders only, squad preview, save-slot picker), `load_run` (slots with Load/Delete), `credits`. `scripts/settings_panel.gd` is an overlay used by the main menu and the pause menu. `scripts/menu_background.gd` is the animated backdrop.
- Kits: `Game.KITS` maps each unit to its primary / passive / card; `Game.CARDS` holds card costs and text; `Game.deck_for(leader)` builds the deck. The battlefield implements them all (`fire_primary`, `charge_tick`/`release_charge`, `try_move`, `damage` pipeline, `play_card`/`_apply_card`, board effects: fortified, fires, floods, spores, claim, drones, protocol, void_orb). `scripts/card_hand.gd` is a team's deck + hand (player's shown at the bottom; enemy's hidden). Both teams have their own EnergyBar/StaminaBar (enemy's hidden) and the enemy AI uses the same calls, so it pays the same costs.
- Battle: squads come from `Game.run` (leader vs `run.enemy`). Esc opens `scripts/pause_menu.gd` (Resume, Settings, Save & Quit, Abandon Run). Win → `Game.win_battle()` (next battle, new enemy); loss → `Game.end_run()` deletes the save.
- Ground is per tile: `holds(team, c, r)` (base columns, Claim column, Stake Claim tiles) and `standable(team, c, r)` (a stake tile must connect to the team's ground). `_settle_ground()` pushes anyone off ground their team lost (backwards first).
- Starter decks: `Game.STARTERS` (2 cards per faction, ×3) + `Game.leader_card()` ×1 = `Game.starter_deck()`. `Game.CARDS[id]["target"]` is "unit", "tile" or "none". Tile cards are aimed: `select_card` arms, `confirm_aim` / `cancel_aim`, reticle via mouse, right stick or touch.
- `scripts/card_hand.gd`: draw timer always runs; a full hand burns a random card on draw. `scripts/deck_view.gd` (`DeckView`) lists a deck (pause menu → Deck; leader select → View Deck).
- Runs (step 2): `Game.new_run` stores `deck`, `sector`, `stage` (0-2), `order` (the 3 other factions, shuffled per sector), `enemy`, `phase` ("battle" / "draft") and `offer`. A win calls `Game.win_battle()` (saves the squad's HP + a 2-card offer from `faction_cards` of yours + the beaten faction; `starting_hp` applies carried HP, 25% for fallen units, cleared on sector clear); `scenes/draft.tscn` + `scripts/draft.gd` lets the player pick one (and drop one at `DECK_CAP` = 12, leader card locked) via `Game.take_draft()`, which advances stage/sector. `Game.resume_scene()` sends Continue / Load to the draft if one is pending. `Game.level()` drives `Game.enemy_deck()`, enemy HP (`squad_for(..., hp_mult)`) and `Game.ai_params()`, which the battlefield stores as `ai` and `unit.gd` reads (dodge via `incoming_shot`, focus via `weakest_player_row`, smart card choice via `_ai_card_score`).
- Sector map + run end (step 3): run `phase` is "map" / "battle" / "draft" / "won"; `Game.resume_scene()` routes each. `run.map` = columns of `{mod, planet}` (planet art: `Game.MOD_PLANETS`, `node_planet`), `run.path` = chosen index per column; `Game.SECTOR_MODS`, `sector_mod()`, `choose_sector(i)`, `draft_choices()`. `scenes/sector_map.tscn` + `scripts/sector_map.gd` draws the map and the choice buttons. `take_draft` returns to the map after a sector and calls `win_run()` (snapshots `win_deck`) at `sectors_to_win()`. `scenes/run_end.tscn` + `scripts/run_end.gd`: Complete Run / Infinity and Beyond choice, then the summary. `Game.complete_run()` adds the reward to `Game.profile` (`user://profile.json`: collection, runs_won, best_sectors, ng_unlocked) and fills `Game.last_result`. An infinite run's defeat calls `complete_run()` from the battlefield.
- Meta (step 4): `scenes/collection.tscn` (collection + profile stats, from the title screen). Leader select: `_ng_pick` (NG+ level, shown when `profile.ng_unlocked` > 0) and the Deck button → `scripts/deck_sculpt.gd` (`DeckSculpt`, read-only unless NG+ ≥ 1 and the collection has cards). `Game.new_run(leader, slot, ng, deck)`; `Game.valid_start_deck()`, `Game.collection_counts()`; `Game.level()` applies `NG_START_LEVELS` and `NG_RAMP`.
- Content pass: `Game.FACTION_CARDS` (3 draftable cards per faction; `faction_cards()` = starters + leader cards + these). `Game.AI_STYLES` + `ai_params(lvl, faction, boss)` give each enemy faction its own tempo, and stage 3 of a sector is a commander battle (`BOSS_HP`, `ai.boss`). Unit fields for the new cards: `barrier`/`barrier_until`, `undying_until`, `heal_rate`; battlefield `guard_until[team]` (Hold the Line). The damage pipeline applies guard, then barrier, then Last Stand.

## Multi-agent workflow (Claude + Codex + Gemma)
- `kb/` is the shared knowledge base: `README.md` (rules), `roster.md` (generated from game data), `briefs/` (work orders), `proposals/` (ideas, with Claude's responses appended), `decisions.md` (Claude's log).
- Codex makes art only: it writes to `art_incoming/<faction>/` and logs to `art_incoming/progress.txt`. `tools/import_frames.gd` turns that into game frames; `tools/watch_frames.sh` runs it as units arrive. `tools/frames_preview.gd` builds a contact sheet for review.
- Gemma (Hermes) writes ideas only. Its proposals need checking against the real game: early rounds invented mechanics. Briefs that list the exact available levers get the best results.
