extends Node2D
## The battle: a 6x9 grid (left 3 columns are the player's side, right 3 the enemy's),
## three units per side, shared squad energy + stamina per team, a deck and hand per
## team, and the squad kits from DESIGN.md (unique primary fires, passives, cards).
## Both teams follow the same rules: the enemy AI moves, shoots and plays cards through
## the same functions as the player, paying the same stamina and energy.
## Ground is held per tile: each side's base columns, plus temporary ground from Claim
## (a whole column) and Stake Claim (single tiles). Controls are in InputLayout.

const COLS := 6
const ROWS := 9
const PANEL_W := 150.0
const PANEL_H := 46.0
const GRID_X := 190.0
const GRID_Y := 160.0
const PLAYER_MAX_COL := 2
const SHOT_SPEED := 620.0

# marks: MARK_HITS hits from the same marker within MARK_WINDOW seconds
const MARK_HITS := 3
const MARK_WINDOW := 4.0
const MARK_TIME := 6.0

# primary fire numbers (standard shots come from Game.ROLES)
const MORTAR_COST := 16.0
const MORTAR_DMG := 16
const MORTAR_RANGE := 3         # columns ahead
const MORTAR_UP := 0.3
const MORTAR_HANG := 0.3
const MORTAR_DOWN := 0.3
const CHARGE_RATE := 25.0       # energy per second while holding
const CHARGE_DMG_PER := 0.6     # damage per energy poured in
const COURTESY_COST := 6.0
const COURTESY_DMG := 4
const UNDERTOW_COST := 14.0
const UNDERTOW_DMG := 10
const UNDERTOW_SPEED := 380.0
const REFRACT_SPLIT_DMG := 6
const EMBER_SELF_DMG := 3
const EMBER_TIME := 4.0
const FIRE_DPS := 5
const OVERHEAT_SELF_DMG := 2
const PROTOCOL_PENALTY := 10
const DRONE_DMG := 4
const DRONE_INTERVAL := 1.5
const SPORE_DPS := 4
const MEDPOD_HPS := 6.0

# starter card numbers
const STAKE_TIME := 7.0
const SANDBAG_TIME := 8.0
const SANDBAG_HITS := 2
const OVERCLOCK_TIME := 5.0
const JAM_TIME := 2.0
const CONTAIN_TIME := 3.0
const MIRE_TIME := 8.0
const BORROWED_HP := 15
const BORROWED_STAMINA := 2
const REWIND_TIME := 2.0

var time := 0.0
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var team_energy: Array = []     # [player EnergyBar, enemy EnergyBar]
var team_stamina: Array = []
var hands: Array = []           # [player CardHand, enemy CardHand]
var active_idx := 0
var shots: Array = []
var battle_on := true
var overlay_text := ""

# board state
var fortified := {}             # Vector2i -> until
var fires := {}                 # Vector2i -> {until, next}
var floods: Array = []          # {team (whose side), row, until}
var spores := {}                # {team, tiles: {Vector2i: true}, until, next_spread, next_tick}
var claim := {}                 # {team, col, until}
var stakes := {}                # Vector2i -> {team, until} (Stake Claim tiles)
var fields := {}                # Vector2i -> {team (caster), until} (Containment Field)
var mires := {}                 # Vector2i -> until
var crates := {}                # Vector2i -> {team, until} (Supply Drop)
var pools := {}                 # Vector2i -> {team, until} (Tide Pool)
var barricades: Array = []      # {team, row, x, hits, until} (Sandbags)
var drones: Array = [{}, {}]    # per team: {col, row, next}
var protocol := {}              # {team (who must obey), rule, until}
var void_orb := {}              # {team (who is bound), until}
var charges := {}               # unit instance id -> energy poured in
var booms: Array = []           # [pos, radius, time left, colour]
var ai := {}                    # enemy tuning for this stage (Game.ai_params)
var guard_until := [-1.0, -1.0] # Hold the Line, per team
var _enemy_card_t := 0.0
var _doctrine_t := 0.0          # commander doctrine: time until its next use
var _shake := 0.0
var _heal_acc := {}

# tile-card aiming (player)
var aim_slot := -1              # hand slot being aimed, -1 = not aiming
var aim_tile := Vector2i(0, 0)
var _no_shot_frame := -1        # right-click that cancelled aiming doesn't also fire

@onready var hud: CanvasLayer = $HUD
@onready var energy: EnergyBar = $HUD/Energy
@onready var stamina: StaminaBar = $HUD/Stamina
@onready var hand: CardHand = $HUD/Hand
@onready var primary_label: Label = $HUD/Primary
@onready var over_dim: ColorRect = $OverScreen/Dim
@onready var over_title: Label = $OverScreen/Title
@onready var over_hint: Label = $OverScreen/Hint

func _ready() -> void:
	y_sort_enabled = true
	if Game.run.is_empty():
		# launched straight into the battle scene (no run): a throwaway, unsaved run
		Game.new_run("claim_lord", -1)
	var lvl := Game.level()
	var enemy_faction: String = Game.leader_by_id(Game.run["enemy"])["faction"]
	var boss := int(Game.run["stage"]) == Game.STAGES_PER_SECTOR - 1
	ai = Game.ai_params(lvl, enemy_faction, boss)
	for d in Game.squad_for(Game.run["leader"], false):
		var u := _spawn(d, 0)
		u.hp = Game.starting_hp(u.role, u.max_hp)   # damage carries over within a sector
		player_units.append(u)
	var mod := Game.sector_mod()
	var fx := Game.mod_fx()
	for k in fx.get("ai", {}):
		ai[k] = float(ai.get(k, 0.0)) + float(fx["ai"][k])
	var next: Dictionary = Game.run.get("next_battle", {})   # set up by an event
	Game.run.erase("next_battle")
	var enemy_hp: float = ai["hp_mult"] * float(fx.get("enemy_hp", 1.0)) * float(next.get("enemy_hp", 1.0))
	for d in Game.squad_for(Game.run["enemy"], true, enemy_hp):
		enemy_units.append(_spawn(d, 1))
	# the enemy squad has its own (hidden) energy, stamina and hand
	var e_energy := EnergyBar.new()
	var e_stamina := StaminaBar.new()
	var e_hand := CardHand.new()
	for n in [e_energy, e_stamina, e_hand]:
		n.visible = false
		hud.add_child(n)
	team_energy = [energy, e_energy]
	team_stamina = [stamina, e_stamina]
	hands = [hand, e_hand]
	var deck: Array = Game.run["deck"].duplicate()
	deck.shuffle()
	hand.setup(deck, energy)
	var e_deck := Game.enemy_deck(Game.run["enemy"], lvl)
	var fpool := Game.faction_cards(enemy_faction)
	for n in int(next.get("enemy_cards", 0)) + int(fx.get("enemy_cards", 0)):
		e_deck.append(fpool[randi() % fpool.size()])
	e_hand.setup(e_deck, e_energy)
	e_hand.team = 1
	if next.has("barrier"):
		# the squad starts the battle behind a shield (energy refills too fast to matter)
		for u in player_units:
			u.barrier = float(next["barrier"])
			u.barrier_until = 30.0
	for c in [energy, stamina]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# sector modifiers: resource timings per side, starting shields and tiles
	for team in 2:
		team_stamina[team].refill_time = StaminaBar.REFILL_TIME * float(fx.get("stamina", [1.0, 1.0])[team])
		team_energy[team].recharge_delay = EnergyBar.RECHARGE_DELAY * float(fx.get("recharge", [1.0, 1.0])[team])
		hands[team].draw_time = CardHand.DRAW_TIME * float(fx.get("draw", [1.0, 1.0])[team])
	if fx.has("barrier"):
		for u in player_units + enemy_units:
			u.barrier = maxf(u.barrier, float(fx["barrier"]))
			u.barrier_until = 30.0
	var tiles: Dictionary = fx.get("tiles", {})
	for k in tiles:
		for p in tiles[k]:
			var t := Vector2i(p[0], p[1])
			match k:
				"mire": mires[t] = 9999.0
				"fire": fires[t] = {"until": 9999.0, "next": 1.0}
				"fortify": fortified[t] = 9999.0
	_enemy_card_t = randf_range(ai["card_min"], ai["card_max"])
	var info := Label.new()
	info.text = "SECTOR %d  ·  STAGE %d/%d  ·  vs %s" % [int(Game.run["sector"]), int(Game.run["stage"]) + 1, Game.STAGES_PER_SECTOR,
		Game.FACTIONS[Game.leader_by_id(Game.run["enemy"])["faction"]]["name"].to_upper()]
	if mod != "uncharted":
		info.text += "  ·  " + Game.SECTOR_MODS[mod]["name"].to_upper()
	if int(Game.run.get("ng", 0)) > 0:
		info.text = "NG+%d  ·  " % int(Game.run["ng"]) + info.text
	if ai["boss"]:
		info.text = info.text.replace("STAGE 3/3", "COMMANDER")
	# tell the player how this faction fights
	(func():
		# one after another, so they never pile up on top of each other
		var lines: Array = []
		if ai["boss"]:
			lines.append(["SECTOR COMMANDER", 20, 1.2])
			var taunt := Game.commander_line(Game.run["enemy"], "taunts")
			if taunt != "":
				lines.append(["%s: \"%s\"" % [Game.UNITS[Game.leader_by_id(Game.run["enemy"])["leader"]]["name"], taunt], 15, 2.2])
		lines.append([ai["tag"], 14, 2.0])
		if ai["doctrine"] != "":
			var doc: Dictionary = Game.DOCTRINES[ai["doctrine"]]
			lines.append(["%s: %s" % [doc["name"], doc["text"]], 14, 2.5])
		var at := 0.0
		for l in lines:
			get_tree().create_timer(at).timeout.connect(_announce.bind(1, l[0], l[1], l[2]))
			at += l[2] + 0.3).call_deferred()
	if ai["doctrine"] != "":
		_doctrine_t = Game.DOCTRINES[ai["doctrine"]]["every"] * 0.6
	info.position = Vector2(400, 8)
	info.size = Vector2(480, 24)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(440, 8)
	info.size = Vector2(400, 24)
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	hud.add_child(info)
	for i in 3:
		var pb := HealthBar.new()
		pb.position = Vector2(24, 14 + i * 36)
		pb.size = Vector2(440, 30)
		hud.add_child(pb)
		pb.bind(player_units[i], false)
		var eb := HealthBar.new()
		eb.position = Vector2(1280 - 24 - 440, 14 + i * 36)
		eb.size = Vector2(440, 30)
		hud.add_child(eb)
		eb.bind(enemy_units[i], true)
	_set_active(0)
	_add_backdrop()
	var all_cards: Array = []
	for c in hand.deck + hand.hand + e_hand.deck + e_hand.hand:
		if not c in all_cards:
			all_cards.append(c)
	Sfx.warm(player_units + enemy_units, all_cards)
	queue_redraw()

## Space behind the grid: the planet of the sector being fought over, with the
## nebula tinted to its colours (each sector looks different).
func _add_backdrop() -> void:
	var k := int(Game.run.get("sector", 1)) - 1
	var path: Array = Game.run.get("path", [])
	var idx := Game.node_planet(k, int(path[k])) if k >= 0 and k < path.size() else randi() % 20
	var layer := CanvasLayer.new()
	layer.layer = -1
	var MB := preload("res://scripts/menu_background.gd")
	var bg: Control = MB.make("space", MB.planet_color(idx), idx, Vector2(1235, 345), 250.0)
	bg.dim = 0.2
	layer.add_child(bg)
	get_parent().add_child.call_deferred(layer)
	var plain := get_parent().get_node_or_null("Background")
	if plain:
		plain.visible = false

func _spawn(d: Dictionary, team: int) -> Unit:
	var u := Unit.new()
	add_child(u)
	u.setup(self, d, team)
	u.killed.connect(_on_unit_killed)
	return u

# --- grid queries --------------------------------------------------------------------

## Centre point of a grid panel, in battlefield-local coordinates.
func panel_center(col: int, row: int) -> Vector2:
	return Vector2(GRID_X + col * PANEL_W + PANEL_W * 0.5, GRID_Y + row * PANEL_H + PANEL_H * 0.5)

func row_of_y(y: float) -> int:
	return clampi(int(floor((y - GRID_Y) / PANEL_H)), 0, ROWS - 1)

func in_grid(t: Vector2i) -> bool:
	return t.x >= 0 and t.x < COLS and t.y >= 0 and t.y < ROWS

func units_of(team: int) -> Array[Unit]:
	return player_units if team == 0 else enemy_units

func unit_at(col: int, row: int) -> Unit:
	for u in player_units + enemy_units:
		if u.is_alive() and u.col == col and u.row == row:
			return u
	return null

func drone_at(col: int, row: int) -> bool:
	for d in drones:
		if not d.is_empty() and d["col"] == col and d["row"] == row:
			return true
	return false

## Does `team` hold tile (c, r) right now? Base columns, then Claim's column, then
## Stake Claim tiles override.
func holds(team: int, c: int, r: int) -> bool:
	var k := Vector2i(c, r)
	if stakes.has(k):
		return stakes[k]["team"] == team
	if not claim.is_empty() and c == claim["col"]:
		return claim["team"] == team
	return c <= PLAYER_MAX_COL if team == 0 else c > PLAYER_MAX_COL

## Can a `team` unit step onto (c, r)? Held ground only; a Stake Claim tile also has
## to connect to the rest of the team's ground (other claimed tiles count).
func standable(team: int, c: int, r: int) -> bool:
	if not holds(team, c, r):
		return false
	var k := Vector2i(c, r)
	return not stakes.has(k) or _connected_ground(team).has(k)

## Every tile `team` holds that links back to its non-stake ground through held tiles.
func _connected_ground(team: int) -> Dictionary:
	var seen := {}
	var queue: Array = []
	for c in COLS:
		for r in ROWS:
			var k := Vector2i(c, r)
			if holds(team, c, r) and not stakes.has(k):
				seen[k] = true
				queue.append(k)
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = p + d
			if in_grid(n) and not seen.has(n) and holds(team, n.x, n.y):
				seen[n] = true
				queue.append(n)
	return seen

func flooded(team: int, row: int) -> bool:
	for f in floods:
		if f["team"] == team and f["row"] == row:
			return true
	return false

## Legal tile for `u`: on the grid, standable for its team, not flooded, and empty.
func can_move(u: Unit, col: int, row: int) -> bool:
	if not in_grid(Vector2i(col, row)):
		return false
	if not standable(u.team, col, row) or flooded(u.team, row):
		return false
	return unit_at(col, row) == null and not drone_at(col, row)

## After ground changes hands: anyone left on ground their team no longer holds is
## pushed back to the nearest tile they can stand on.
func _settle_ground() -> void:
	for u in player_units + enemy_units:
		if u.is_alive() and not holds(u.team, u.col, u.row):
			_push_to_nearest(u)

func active_unit() -> Unit:
	return player_units[active_idx]

func _set_active(i: int) -> void:
	if active_idx < player_units.size() and charges.has(player_units[active_idx].get_instance_id()):
		release_charge(player_units[active_idx])
	active_idx = i
	for k in player_units.size():
		player_units[k].set_active(k == i)

## Swap control to the next living unit in direction `step` (-1 = Q, +1 = E).
func _swap(step: int) -> void:
	for n in range(1, player_units.size()):
		var k := posmod(active_idx + step * n, player_units.size())
		if player_units[k].is_alive():
			_set_active(k)
			return

# --- main loop ---------------------------------------------------------------------

func _process(delta: float) -> void:
	if not battle_on:
		if Input.is_action_just_pressed("confirm"):
			if Game.run.is_empty():
				Game.go("res://scenes/run_end.tscn" if not Game.last_result.is_empty() else "res://scenes/main_menu.tscn")
			else:
				Game.go(Game.resume_scene())
		elif Input.is_action_just_pressed("ui_cancel") and not Game.run.is_empty():
			Game.go("res://scenes/main_menu.tscn")
		return
	time += delta
	_player_input(delta)
	_update_board(delta)
	_update_units(delta)
	_update_shots(delta)
	_update_enemy_cards(delta)
	_update_doctrine(delta)
	_update_hud()
	_shake = maxf(_shake - delta, 0.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * (_shake / 0.25) if _shake > 0.0 and Game.settings.get("screen_shake", true) else Vector2.ZERO
	queue_redraw()

func _player_input(delta: float) -> void:
	if Input.is_action_just_pressed("swap_prev"):
		_swap(-1)
	elif Input.is_action_just_pressed("swap_next"):
		_swap(1)
	var u := active_unit()
	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"):
		dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		try_move(u, dir)
	var can_shoot := Engine.get_process_frames() != _no_shot_frame
	if u.primary == "charge":
		if Input.is_action_just_pressed("buster") and can_shoot and energy.value < 1.0:
			energy.deny()
		elif Input.is_action_pressed("buster") and can_shoot:
			charge_tick(u, delta)
		elif charges.has(u.get_instance_id()):
			release_charge(u)
	elif Input.is_action_just_pressed("buster") and can_shoot:
		fire_primary(u)
	for i in 3:
		if Input.is_action_just_pressed("card_%d" % (i + 1)):
			select_card(i)
	if aim_slot >= 0:
		var step := Vector2i.ZERO
		if Input.is_action_just_pressed("aim_up"):
			step = Vector2i.UP
		elif Input.is_action_just_pressed("aim_down"):
			step = Vector2i.DOWN
		elif Input.is_action_just_pressed("aim_left"):
			step = Vector2i.LEFT
		elif Input.is_action_just_pressed("aim_right"):
			step = Vector2i.RIGHT
		if step != Vector2i.ZERO:
			aim_tile = Vector2i(clampi(aim_tile.x + step.x, 0, COLS - 1), clampi(aim_tile.y + step.y, 0, ROWS - 1))
		if Input.is_action_just_pressed("aim_confirm"):
			confirm_aim()
		elif Input.is_action_just_pressed("aim_cancel"):
			cancel_aim()

## A card key / button / click on hand slot `i`. Untargeted cards play at once; tile
## cards arm and wait for a tile. Pressing the armed card again confirms it.
func select_card(i: int) -> void:
	if i >= hand.hand.size():
		return
	if aim_slot == i:
		confirm_aim()
		return
	var id: String = hand.hand[i]
	if Game.CARDS[id]["target"] != "tile":
		cancel_aim()
		play_card(0, i)
		return
	if not hand.can_play(i):
		energy.deny()
		return
	aim_slot = i
	hand.armed = i
	aim_tile = _default_aim(id)

func confirm_aim() -> void:
	if aim_slot < 0:
		return
	var slot := aim_slot
	if play_card(0, slot, aim_tile):
		aim_slot = -1
		hand.armed = -1

func cancel_aim() -> void:
	aim_slot = -1
	hand.armed = -1

## Reticle start: Stake Claim -> the enemy tile just in front in the controlled unit's
## row; other tile cards -> the nearest enemy (by row).
func _default_aim(id: String) -> Vector2i:
	var u := active_unit()
	if id in OWN_GROUND_CARDS:
		return Vector2i(u.col, u.row)
	if id == "stake_claim":
		for c in COLS:
			if holds(1, c, u.row) and valid_tile(0, id, Vector2i(c, u.row)):
				return Vector2i(c, u.row)
	var best := Vector2i(PLAYER_MAX_COL + 1, u.row)
	var best_d := 999
	for e in enemy_units:
		if e.is_alive() and absi(e.row - u.row) < best_d:
			best_d = absi(e.row - u.row)
			best = Vector2i(e.col, e.row)
	return best

## Mouse / touch: tap a hand card to select it, a health bar to swap to that unit, a
## tile to aim (and confirm) a tile card. Right-click cancels aiming.
func _unhandled_input(event: InputEvent) -> void:
	if not battle_on:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if aim_slot >= 0:
			cancel_aim()
		else:
			add_child(PauseMenu.new())
		return
	if event is InputEventMouseMotion and aim_slot >= 0:
		var t := _tile_at(event.position)
		if in_grid(t):
			aim_tile = t
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and aim_slot >= 0:
			cancel_aim()
			_no_shot_frame = Engine.get_process_frames()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var slot := hand.slot_at(event.position - hand.position)
			if slot >= 0:
				select_card(slot)
				get_viewport().set_input_as_handled()
				return
			for i in 3:
				if Rect2(24, 14 + i * 36, 440, 30).has_point(event.position) and player_units[i].is_alive():
					_set_active(i)
					get_viewport().set_input_as_handled()
					return
			var t := _tile_at(event.position)
			if aim_slot >= 0 and in_grid(t):
				aim_tile = t
				confirm_aim()
				get_viewport().set_input_as_handled()

func _tile_at(screen: Vector2) -> Vector2i:
	var p := screen - position - Vector2(GRID_X, GRID_Y)
	if p.x < 0 or p.y < 0:
		return Vector2i(-1, -1)
	return Vector2i(int(p.x / PANEL_W), int(p.y / PANEL_H))

# --- movement ------------------------------------------------------------------------

## Move `u` one tile, paying stamina (or a Glasswing free move). Applies Containment,
## Mire, protocols and Void Orb drag. Returns false if the move isn't legal or affordable.
func try_move(u: Unit, dir: Vector2i) -> bool:
	var c := u.col + dir.x
	var r := u.row + dir.y
	if not u.is_alive() or not can_move(u, c, r):
		return false
	var here := Vector2i(u.col, u.row)
	if time < u.rooted_until:
		team_stamina[u.team].deny()   # Flash Forward's time debt
		return false
	if fields.has(here) and fields[here]["team"] != u.team:
		team_stamina[u.team].deny()
		return false
	var free := u.passive == "hit_and_run" and time - u.last_fired_at <= 1.0 and u.free_moves_used < 3
	if free:
		u.free_moves_used += 1
		u.last_fired_at = -99.0
	elif mires.has(here):
		if team_stamina[u.team].value < 2.0:
			team_stamina[u.team].deny()
			return false
		team_stamina[u.team].try_spend()
		team_stamina[u.team].try_spend()
	elif not team_stamina[u.team].try_spend():
		return false
	u.move_to(c, r)
	Sfx.unit_step(u)
	u.dug_until = -1.0   # leaving the foxhole ends Dig In
	u.last_moved_at = time
	if _protocol_on(u.team) and (protocol["rule"] == "HALT" or (protocol["rule"] == "FORMATION" and dir.y != 0)):
		_break_protocol(u)
	if dir.y != 0 and u.primary == "refraction":
		u.vmove_times.append(time)
		u.vmove_times = u.vmove_times.filter(func(t): return time - t <= 1.0)
		if u.vmove_times.size() >= 2:
			u.refract_ready = true
	if not void_orb.is_empty() and void_orb["team"] == u.team:
		_void_drag(u)
	return true

## Void Orb: everyone else on `mover`'s team is dragged until adjacent to it; each
## dragged unit costs that team a stamina chunk.
func _void_drag(mover: Unit) -> void:
	var dragged := 0
	for v in units_of(mover.team):
		if v == mover or not v.is_alive() or _cheb(v, mover) <= 1:
			continue
		# shortest walk (through legal tiles) to any tile next to the mover
		var start := Vector2i(v.col, v.row)
		var seen := {start: true}
		var queue: Array = [start]
		var goal := Vector2i(-1, -1)
		while not queue.is_empty():
			var p: Vector2i = queue.pop_front()
			if p != start and maxi(absi(p.x - mover.col), absi(p.y - mover.row)) <= 1:
				goal = p
				break
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = p + d
				if not seen.has(n) and can_move(v, n.x, n.y):
					seen[n] = true
					queue.append(n)
		if goal.x >= 0:
			v.move_to(goal.x, goal.y)
			v.forced_at = time
			dragged += 1
	team_stamina[mover.team].force_spend(dragged)

func _cheb(a: Unit, b: Unit) -> int:
	return maxi(absi(a.col - b.col), absi(a.row - b.row))

## Forced move to the nearest legal tile (Claim, Flood, lost ground), preferring to go
## backwards (away from the enemy), then sideways; forward only as a last resort.
## `prefer_rows` (Flood) favours staying in the same column.
func _push_to_nearest(u: Unit, prefer_rows := false) -> void:
	var back := -1 if u.team == 0 else 1
	var best := Vector2i(-1, -1)
	var best_d := 999.0
	for c in COLS:
		for r in ROWS:
			if (c != u.col or r != u.row) and can_move(u, c, r):
				var dc := c - u.col
				var col_cost := 2.0 if prefer_rows else (0.9 if signi(dc) == back else 3.0)
				var d := absf(dc) * col_cost + absf(r - u.row)
				if d < best_d:
					best_d = d
					best = Vector2i(c, r)
	if best.x >= 0:
		u.move_to(best.x, best.y)
		u.forced_at = time

# --- primary fire --------------------------------------------------------------------

func primary_cost(u: Unit) -> float:
	var cost: float
	match u.primary:
		"mortar": cost = MORTAR_COST
		"courtesy": cost = COURTESY_COST
		"undertow": cost = UNDERTOW_COST
		"charge": return 1.0
		_:
			if u.passive == "braced":
				var still := time - u.last_moved_at
				cost = 6.0 if still >= 1.5 else (12.0 if still >= 1.0 else 18.0)
			else:
				cost = Game.ROLES[u.role]["shot_cost"]
	if time < u.breach_until:
		cost *= 2.0   # Data Breach
	return cost * 0.5 if time < u.overclock_until else cost

func is_jammed(u: Unit) -> bool:
	return time >= u.overclock_until and time < u.jam_until

func can_afford_primary(u: Unit) -> bool:
	return not is_jammed(u) and team_energy[u.team].value >= primary_cost(u)

## Fire `u`'s primary (everything except the held Charge Beam). Pays energy.
func fire_primary(u: Unit) -> bool:
	if not u.is_alive() or u.primary == "charge":
		return false
	if is_jammed(u):
		team_energy[u.team].deny()
		return false
	if not team_energy[u.team].try_spend(primary_cost(u)):
		return false
	var dir := 1 if u.team == 0 else -1
	var muzzle := u.position + u.sprite.muzzle_point()
	var dmg: int = Game.ROLES[u.role]["shot_dmg"]
	match u.primary:
		"mortar":
			var tc := clampi(u.col + MORTAR_RANGE * dir, 0, COLS - 1)
			shots.append({"kind": "mortar", "team": u.team, "src": u, "from": muzzle, "tc": tc, "tr": u.row, "t": 0.0, "dmg": MORTAR_DMG})
		"courtesy":
			var s := _bullet(u, muzzle, u.row, COURTESY_DMG)
			if not _row_has_target(u.team, u.row):
				for dr in [-1, 1]:
					if _row_has_target(u.team, u.row + dr):
						s["ty"] = panel_center(0, u.row + dr).y
						break
			shots.append(s)
		"undertow":
			var s := _bullet(u, muzzle, u.row, UNDERTOW_DMG)
			s["speed"] = UNDERTOW_SPEED
			s["push"] = true
			s["size"] = 1.6
			shots.append(s)
		"refraction":
			var s := _bullet(u, muzzle, u.row, dmg)
			if u.refract_ready:
				s["split_x"] = muzzle.x + PANEL_W * dir
				s["size"] = 1.4
				u.refract_ready = false
			shots.append(s)
		"ember":
			var s := _bullet(u, muzzle, u.row, dmg)
			s["ember"] = true
			shots.append(s)
		"afterimage":
			shots.append(_bullet(u, muzzle, u.row, dmg))
			if u.prev_row != u.row or u.prev_col != u.col:
				var ghost := panel_center(u.prev_col, u.prev_row) + u.sprite.muzzle_point()
				shots.append(_bullet(u, ghost, u.prev_row, dmg))
		_:
			shots.append(_bullet(u, muzzle, u.row, dmg))
	_on_fired(u)
	u.sprite.play_attack()
	return true

## Bookkeeping every shot triggers: protocol SILENCE, self-damage passives, Glasswing.
func _on_fired(u: Unit) -> void:
	Sfx.unit_fire(u)
	u.last_fired_at = time
	if _protocol_on(u.team) and protocol["rule"] == "SILENCE":
		_break_protocol(u)
	if u.passive == "overheat":
		u.take_damage(OVERHEAT_SELF_DMG)
	if u.primary == "ember":
		u.take_damage(EMBER_SELF_DMG)

func _bullet(src: Unit, from: Vector2, row: int, dmg: int) -> Dictionary:
	var yb := panel_center(0, row).y
	return {"kind": "bullet", "team": src.team if src else 0, "src": src, "x": from.x, "yb": yb, "ty": yb,
		"yo": from.y - panel_center(0, row).y, "dir": 1 if (src == null or src.team == 0) else -1,
		"dmg": dmg, "speed": SHOT_SPEED, "size": 1.0}

func _row_has_target(team: int, row: int) -> bool:
	for t in units_of(1 - team):
		if t.is_alive() and t.row == row:
			return true
	return false

## Charge Beam: pour energy in while the button is held (Overclock doubles what each
## point of energy is worth; a jammed unit can't charge).
func charge_tick(u: Unit, delta: float) -> void:
	if is_jammed(u):
		return
	var got: float = team_energy[u.team].drain(CHARGE_RATE * delta)
	if time < u.overclock_until:
		got *= 2.0
	var id := u.get_instance_id()
	charges[id] = charges.get(id, 0.0) + got

func release_charge(u: Unit) -> void:
	var id := u.get_instance_id()
	var amt: float = charges.get(id, 0.0)
	charges.erase(id)
	if amt < 2.0 or not u.is_alive():
		return
	var s := _bullet(u, u.position + u.sprite.muzzle_point(), u.row, int(round(4 + amt * CHARGE_DMG_PER)))
	s["size"] = 1.0 + amt / 22.0
	s["speed"] = SHOT_SPEED * 0.8
	shots.append(s)
	_on_fired(u)
	u.sprite.play_attack()
	if amt > 40.0:
		_shake = 0.2

# --- shots ---------------------------------------------------------------------------

func _update_shots(delta: float) -> void:
	var spawned: Array = []
	var i := shots.size() - 1
	while i >= 0:
		var s: Dictionary = shots[i]
		var done := false
		if s["kind"] == "mortar":
			s["t"] += delta
			if s["t"] >= MORTAR_UP + MORTAR_HANG + MORTAR_DOWN:
				var t := unit_at(s["tc"], s["tr"])
				var p := panel_center(s["tc"], s["tr"])
				booms.append([p, 34.0, 0.35, Color(1.0, 0.7, 0.3)])
				if t and t.team != s["team"]:
					damage(t, s["dmg"], s["src"])
					_shake = 0.15
				Sfx.shell_land()
				done = true
		else:
			var prev_x: float = s["x"]
			s["x"] += s["dir"] * s["speed"] * delta
			s["yb"] = move_toward(s["yb"], s["ty"], s["speed"] * delta * (PANEL_H / PANEL_W) * 1.5)
			var row := row_of_y(s["yb"])
			if s.has("split_x") and (s["x"] - s["split_x"]) * s["dir"] >= 0.0:
				s.erase("split_x")
				for dr in [-1, 1]:
					if row + dr >= 0 and row + dr < ROWS:
						var b: Dictionary = s.duplicate()
						b["ty"] = panel_center(0, row + dr).y
						b["dmg"] = REFRACT_SPLIT_DMG
						b["size"] = 0.9
						spawned.append(b)
			# Sandbags soak enemy shots in their row
			for bar in barricades:
				var bx: float = bar["x"]
				if bar["team"] != s["team"] and bar["row"] == row and bar["hits"] > 0 and ((s["dir"] > 0 and prev_x < bx and s["x"] >= bx) or (s["dir"] < 0 and prev_x > bx and s["x"] <= bx)):
					bar["hits"] -= 1
					booms.append([Vector2(bx, panel_center(0, row).y - 10), 16.0, 0.25, Color(0.85, 0.75, 0.5)])
					done = true
					break
			if not done:
				for t in units_of(1 - s["team"]):
					if t.is_alive() and t.row == row:
						var tx := t.position.x
						if (s["dir"] > 0 and prev_x < tx and s["x"] >= tx) or (s["dir"] < 0 and prev_x > tx and s["x"] <= tx):
							_bullet_hit(s, t)
							done = true
							break
			if not done and (s["x"] > GRID_X + COLS * PANEL_W + 40.0 or s["x"] < GRID_X - 40.0):
				var src = s["src"]
				if src and is_instance_valid(src) and src.passive == "steady_aim":
					src.streak = 0   # a miss breaks Steady Aim
				done = true
		if done:
			shots.remove_at(i)
		i -= 1
	shots.append_array(spawned)
	barricades = barricades.filter(func(b): return b["hits"] > 0 and b["until"] > time)

func _bullet_hit(s: Dictionary, t: Unit) -> void:
	var src = s["src"] if s["src"] and is_instance_valid(s["src"]) else null
	damage(t, s["dmg"], src)
	if s.get("push", false) and t.is_alive():
		var c: int = t.col + s["dir"]
		if can_move(t, c, t.row):
			t.move_to(c, t.row)
			t.forced_at = time
	if s.get("ember", false):
		fires[Vector2i(t.col, t.row)] = {"until": time + EMBER_TIME, "next": time + 1.0}
	if src and src.passive == "steady_aim":
		src.streak += 1
		if src.streak >= 3:
			src.streak = 0
			team_stamina[src.team].refund(1)

# --- damage --------------------------------------------------------------------------

## All attack damage goes through here so passives, tiles and marks apply.
func damage(t: Unit, amount: int, src) -> void:
	if not t.is_alive():
		return
	var a := float(amount)
	if src:
		if src.passive == "overheat":
			a *= 1.5
		if src.passive == "ambush" and time - t.forced_at <= 3.0:
			a *= 1.5
	if fortified.get(Vector2i(t.col, t.row), -1.0) > time:
		a *= 0.5
	if guard_until[t.team] > time:
		a *= 0.7   # Hold the Line
	if time < t.dug_until:
		a *= 0.6   # Dig In
	if src and time < src.dug_until:
		a *= 1.25
	if t.barrier > 0.0 and time < t.barrier_until:
		var soak := minf(t.barrier, a)
		t.barrier -= soak
		a -= soak
	if time < t.undying_until:
		a = minf(a, t.hp - 1)   # Last Stand
	if t.passive == "shield_up":
		t.shield_hits.append(time)
		t.shield_hits = t.shield_hits.filter(func(h): return time - h <= 3.0)
		if t.shield_up:
			if t.shield_hits.size() > 2:
				t.shield_up = false
			else:
				a *= 0.5
	t.last_hit_at = time
	if t.marks.has("interval"):
		t.marks["interval"]["accum"] += a
	if src and t.marks.has("analysis") and t.marks["analysis"]["team"] == src.team:
		team_energy[src.team].refund(3.0)
	# Burning Stars (Long Tomorrow commander): each unit shrugs off one killing blow
	if ai.get("doctrine", "") == "long" and t.team == 1 and not t.spared and int(round(a)) >= t.hp:
		t.spared = true
		a = t.hp - 1
		t.undying_until = time + 2.0
		booms.append([t.position, 40.0, 0.4, Color(1.0, 0.6, 0.2)])
		_announce(1, "NOT YET")
	# Mycelial Link: the hit is shared evenly by the whole living squad
	if time < t.link_until:
		var squad := units_of(t.team).filter(func(u): return u.is_alive())
		var share := int(round(a / squad.size()))
		for u in squad:
			if u != t:
				u.take_damage(mini(share, u.hp - 1))
				_popup(u.position + Vector2(0, -u.sprite.height * 0.6), str(share), Color(0.5, 1.0, 0.6))
		a = share
	var hp_before := t.hp
	t.take_damage(int(round(a)))
	Game.stat("dealt" if t.team == 1 else "taken", hp_before - t.hp)   # no overkill
	if t.is_alive() and a >= 1.0:
		Sfx.unit_hit(t)
	_popup(t.position + Vector2(0, -t.sprite.height * 0.6), str(int(round(a))), Color(1.0, 0.9, 0.5) if t.team == 1 else Color(1.0, 0.5, 0.45))
	if src and (src.passive == "analysis" or src.passive == "interval_mark") and t.is_alive():
		_count_mark_hit(src, t)

## Three hits from the same marker within MARK_WINDOW marks the target.
func _count_mark_hit(src: Unit, t: Unit) -> void:
	var id := src.get_instance_id()
	var hits: Array = t.mark_hits.get(id, [])
	hits.append(time)
	hits = hits.filter(func(h): return time - h <= MARK_WINDOW)
	t.mark_hits[id] = hits
	t.pip_count = hits.size()
	t.pip_color = Color(0.3, 0.95, 0.9) if src.passive == "analysis" else Color(0.75, 0.45, 1.0)
	t.pip_until = time + MARK_WINDOW
	if hits.size() >= MARK_HITS:
		var kind := "analysis" if src.passive == "analysis" else "interval"
		t.marks[kind] = {"until": time + MARK_TIME, "team": src.team, "accum": 0.0}
		t.mark_hits[id] = []
		t.pip_count = 0
		booms.append([t.position, 30.0, 0.3, t.pip_color])

func _popup(pos: Vector2, text: String, col: Color) -> void:
	if not Game.settings.get("show_damage_numbers", true):
		return
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(randf_range(-14, 14), 0)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	hud.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 30.0, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)

# --- per-unit upkeep -----------------------------------------------------------------

func _update_units(delta: float) -> void:
	for u in player_units + enemy_units:
		if not u.is_alive():
			continue
		# position + HP history for Rewind
		if u.history.is_empty() or time - u.history[-1][0] >= 0.1:
			u.history.append([time, u.col, u.row, u.hp])
			while u.history.size() > 1 and time - u.history[0][0] > REWIND_TIME + 0.5:
				u.history.pop_front()
		if u.passive == "shield_up" and not u.shield_up and time - u.last_hit_at >= 6.0:
			u.shield_up = true
			u.shield_hits.clear()
		if time < u.heal_until:
			var id := u.get_instance_id()
			_heal_acc[id] = _heal_acc.get(id, 0.0) + u.heal_rate * delta
			if _heal_acc[id] >= 1.0:
				u.heal(int(_heal_acc[id]))
				_heal_acc[id] -= int(_heal_acc[id])
		if u.passive == "hit_and_run" and team_stamina[u.team].is_full():
			u.free_moves_used = 0
		for kind in u.marks.keys():
			if time >= u.marks[kind]["until"]:
				if kind == "interval":
					# Interval Mark detonates for half the damage taken while marked
					var boom := int(round(u.marks[kind]["accum"] * 0.5))
					booms.append([u.position, 48.0, 0.45, Color(0.75, 0.45, 1.0)])
					_shake = 0.2
					u.marks.erase(kind)
					if boom > 0:
						u.take_damage(boom)
						_popup(u.position + Vector2(0, -u.sprite.height * 0.8), "%d!" % boom, Color(0.85, 0.6, 1.0))
				else:
					u.marks.erase(kind)
	for b in booms:
		b[2] -= delta
	booms = booms.filter(func(b): return b[2] > 0.0)

# --- board effects -------------------------------------------------------------------

func _update_board(_delta: float) -> void:
	for k in fortified.keys():
		if fortified[k] <= time:
			fortified.erase(k)
	for k in fires.keys():
		var f: Dictionary = fires[k]
		if time >= f["until"]:
			fires.erase(k)
		elif time >= f["next"]:
			f["next"] += 1.0
			var u := unit_at(k.x, k.y)
			if u:
				damage(u, FIRE_DPS, null)
	floods = floods.filter(func(f): return f["until"] > time)
	for k in fields.keys():
		if fields[k]["until"] <= time:
			fields.erase(k)
	for k in mires.keys():
		if mires[k] <= time:
			mires.erase(k)
	# Supply Drop: the first unit of the dropping team to stand on the crate takes it
	for k in crates.keys():
		var u := unit_at(k.x, k.y)
		if u and u.team == crates[k]["team"]:
			u.heal(20)
			team_energy[u.team].refund(15.0)
			booms.append([u.position, 30.0, 0.35, Color(0.5, 1.0, 0.6)])
			_popup(u.position + Vector2(0, -u.sprite.height * 0.7), "+20", Color(0.5, 1.0, 0.6))
			crates.erase(k)
		elif crates[k]["until"] <= time:
			crates.erase(k)
	for k in pools.keys():
		if pools[k]["until"] <= time:
			pools.erase(k)
		else:
			var u := unit_at(k.x, k.y)
			if u and u.team == pools[k]["team"]:
				var id := u.get_instance_id()
				_heal_acc[id] = _heal_acc.get(id, 0.0) + 5.0 * _delta
				if _heal_acc[id] >= 1.0:
					u.heal(int(_heal_acc[id]))
					_heal_acc[id] -= int(_heal_acc[id])
	if not spores.is_empty():
		if time >= spores["until"]:
			spores = {}
		else:
			if time >= spores["next_tick"]:
				spores["next_tick"] += 1.0
				for u in units_of(spores["team"]):
					if u.is_alive() and spores["tiles"].has(Vector2i(u.col, u.row)):
						damage(u, SPORE_DPS, null)
			if time >= spores["next_spread"]:
				spores["next_spread"] += 3.0
				_spread_spores()
	var ground_changed := false
	if not claim.is_empty() and time >= claim["until"]:
		claim = {}
		ground_changed = true
	for k in stakes.keys():
		if stakes[k]["until"] <= time:
			stakes.erase(k)
			ground_changed = true
	if ground_changed:
		_settle_ground()
	if not protocol.is_empty() and time >= protocol["until"]:
		protocol = {}
	if not void_orb.is_empty() and time >= void_orb["until"]:
		void_orb = {}
	for team in 2:
		var d: Dictionary = drones[team]
		if not d.is_empty() and time >= d["next"]:
			d["next"] = time + DRONE_INTERVAL
			var p := panel_center(d["col"], d["row"]) + Vector2(0, -22)
			var s := _bullet(null, p, d["row"], DRONE_DMG)
			s["team"] = team
			s["dir"] = 1 if team == 0 else -1
			s["size"] = 0.7
			shots.append(s)

func _spread_spores() -> void:
	var options: Array = []
	for k in spores["tiles"]:
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = k + d
			if in_grid(n) and holds(spores["team"], n.x, n.y) and not spores["tiles"].has(n):
				options.append(n)
	if not options.is_empty():
		spores["tiles"][options[randi() % options.size()]] = true

func _protocol_on(team: int) -> bool:
	return not protocol.is_empty() and protocol["team"] == team

## A unit broke the active protocol: it pays HP, and an enemy Protocol Warden retaliates.
func _break_protocol(u: Unit) -> void:
	u.take_damage(PROTOCOL_PENALTY)
	_popup(u.position + Vector2(0, -u.sprite.height), "%s!" % protocol["rule"], Color(1.0, 0.4, 0.4))
	for w in units_of(1 - u.team):
		if w.is_alive() and w.passive == "enforcer":
			shots.append(_bullet(w, w.position + w.sprite.muzzle_point(), w.row, Game.ROLES[w.role]["shot_dmg"]))
			w.sprite.play_attack()

# --- cards ---------------------------------------------------------------------------

## Can `team` aim tile card `id` at `t`?
func valid_tile(team: int, id: String, t: Vector2i) -> bool:
	if not in_grid(t):
		return false
	if id == "stake_claim":
		return holds(1 - team, t.x, t.y)
	if id in OWN_GROUND_CARDS:
		return holds(team, t.x, t.y)
	if id == "data_breach":
		var u := unit_at(t.x, t.y)
		return u != null and u.team != team
	return true

## Tile cards that must land on the caster's own ground.
const OWN_GROUND_CARDS := ["supply_drop", "tide_pool"]

## Play card `i` from `team`'s hand. Unit cards act on the controlled unit (the AI
## picks one); tile cards need `tile` (the AI picks its own).
func play_card(team: int, i: int, tile := Vector2i(-1, -1)) -> bool:
	var h: CardHand = hands[team]
	if i >= h.hand.size():
		return false
	var id: String = h.hand[i]
	var card: Dictionary = Game.CARDS[id]
	if card["target"] == "tile":
		if team == 1:
			tile = _ai_tile(id)
		if not valid_tile(team, id, tile):
			if team == 0:
				energy.deny()
			return false
	if not team_energy[team].try_spend(Game.card_cost(id, team)):
		return false
	h.take(i)
	var sel: Unit = active_unit() if team == 0 else _ai_card_unit(id)
	var aim_row: int = sel.row if team == 0 else _ai_aim_row()
	_apply_card(team, id, sel, aim_row, tile)
	Sfx.card(id, team)
	if team == 0:
		Game.stat("cards")
	_announce(team, card["name"])
	return true

func _apply_card(team: int, id: String, sel: Unit, aim_row: int, tile: Vector2i) -> void:
	var foe := 1 - team
	var dir := 1 if team == 0 else -1
	match id:
		"fortify":
			fortified[Vector2i(sel.col, sel.row)] = time + 10.0
		"claim":
			claim = {"team": team, "col": PLAYER_MAX_COL + 1 if team == 0 else PLAYER_MAX_COL, "until": time + 10.0}
			_settle_ground()
		"deploy_drone":
			var spot := Vector2i(-1, -1)
			var tries: Array = [Vector2i(sel.col + dir, sel.row)]
			for c in COLS:
				tries.append(Vector2i(c, sel.row))
			for c in COLS:
				for r in ROWS:
					tries.append(Vector2i(c, r))
			drones[team] = {}
			for t in tries:
				if in_grid(t) and holds(team, t.x, t.y) and unit_at(t.x, t.y) == null and not drone_at(t.x, t.y):
					spot = t
					break
			if spot.x >= 0:
				drones[team] = {"col": spot.x, "row": spot.y, "next": time + 0.5}
		"issue_protocol":
			protocol = {"team": foe, "rule": ["HALT", "SILENCE", "FORMATION"][randi() % 3], "until": time + 6.0}
			_announce(team, "PROTOCOL: " + protocol["rule"])
		"flood":
			floods.append({"team": foe, "row": aim_row, "until": time + 6.0})
			for u in units_of(foe):
				if u.is_alive() and u.row == aim_row:
					_push_to_nearest(u, true)
		"spore_bloom":
			var cols: Array = []
			for c in COLS:
				if holds(foe, c, aim_row):
					cols.append(c)
			if team == 1:
				cols.reverse()
			var r0 := clampi(aim_row, 0, ROWS - 2)
			var tiles := {}
			for c in cols.slice(0, 2):
				for r in [r0, r0 + 1]:
					tiles[Vector2i(c, r)] = true
			spores = {"team": foe, "tiles": tiles, "until": time + 9.0, "next_spread": time + 3.0, "next_tick": time + 1.0}
		"medpod":
			sel.heal_until = time + 8.0
			sel.heal_rate = MEDPOD_HPS
		"void_orb":
			void_orb = {"team": foe, "until": time + 8.0}
		# --- starter cards ---
		"stake_claim":
			stakes[tile] = {"team": team, "until": time + STAKE_TIME}
			_settle_ground()
		"sandbags":
			barricades.append({"team": team, "row": sel.row, "x": panel_center(sel.col, sel.row).x + dir * PANEL_W * 0.45,
				"hits": SANDBAG_HITS, "until": time + SANDBAG_TIME})
		"overclock":
			sel.overclock_until = time + OVERCLOCK_TIME
			sel.jam_until = time + OVERCLOCK_TIME + JAM_TIME
		"containment":
			fields[tile] = {"team": team, "until": time + CONTAIN_TIME}
		"riptide":
			var target: Unit = null
			for u in units_of(foe):
				if u.is_alive() and u.row == sel.row and (target == null or absi(u.col - sel.col) < absi(target.col - sel.col)):
					target = u
			if target and can_move(target, target.col - dir, target.row):
				target.move_to(target.col - dir, target.row)
				target.forced_at = time
				booms.append([target.position, 26.0, 0.3, Color(0.4, 0.7, 1.0)])
		"mire":
			mires[tile] = time + MIRE_TIME
		"borrowed_time":
			sel.take_damage(mini(BORROWED_HP, sel.hp - 1))
			team_stamina[team].refund(BORROWED_STAMINA)
		"rewind":
			var then: Array = sel.history[0] if not sel.history.is_empty() else [time, sel.col, sel.row, sel.hp]
			for hs in sel.history:
				if time - hs[0] <= REWIND_TIME:
					break
				then = hs
			var back := Vector2i(then[1], then[2])
			booms.append([sel.position, 30.0, 0.35, Color(0.75, 0.6, 1.0)])
			if back != Vector2i(sel.col, sel.row) and can_move(sel, back.x, back.y):
				sel.move_to(back.x, back.y)
			var lost: int = then[3] - sel.hp
			if lost > 0:
				sel.heal(lost / 2)
		# --- draftable faction cards ---
		"barrage":
			var from := sel.position + Vector2(0, -sel.sprite.height)
			for dr in [-1, 0, 1]:
				if tile.y + dr >= 0 and tile.y + dr < ROWS:
					shots.append({"kind": "mortar", "team": team, "src": sel, "from": from, "tc": tile.x, "tr": tile.y + dr,
						"t": -0.15 * absi(dr), "dmg": 14})
		"hold_the_line":
			guard_until[team] = time + 5.0
		"requisition":
			hands[team]._draw_card_from_deck()
		"target_lock":
			var t := unit_at(tile.x, tile.y)
			if t and t.team == foe:
				t.marks["analysis"] = {"until": time + MARK_TIME, "team": team, "accum": 0.0}
				booms.append([t.position, 30.0, 0.3, Color(0.3, 0.95, 0.9)])
		"shield_drone":
			sel.barrier = 30.0
			sel.barrier_until = time + 10.0
		"recompile":
			var h: CardHand = hands[team]
			h.discard.append_array(h.hand)
			h.hand.clear()
			for n in CardHand.HAND_SIZE:
				h._draw_card_from_deck()
		"undertow_surge":
			for u in units_of(foe):
				if u.is_alive() and u.row == sel.row and can_move(u, u.col + dir, u.row):
					u.move_to(u.col + dir, u.row)
					u.forced_at = time
					booms.append([u.position, 24.0, 0.3, Color(0.3, 0.6, 1.0)])
		"regrowth":
			for u in units_of(team):
				if u.is_alive():
					u.heal_until = time + 5.0
					u.heal_rate = 4.0
		"mudslide":
			for dr in [-1, 0, 1]:
				if tile.y + dr >= 0 and tile.y + dr < ROWS:
					mires[Vector2i(tile.x, tile.y + dr)] = time + MIRE_TIME
		"last_stand":
			sel.undying_until = time + 4.0
		"burn_bright":
			sel.take_damage(mini(20, sel.hp - 1))
			team_energy[team].refund(40.0)
		"echo_strike":
			for n in 2:
				if sel.primary == "charge":
					charges[sel.get_instance_id()] = 30.0
					release_charge(sel)
				else:
					team_energy[team].refund(primary_cost(sel))
					sel.last_fired_at = -99.0
					fire_primary(sel)
		"suppressing_fire":
			for u in units_of(foe):
				if u.is_alive() and u.row == sel.row:
					u.overclock_until = minf(u.overclock_until, time)
					u.jam_until = maxf(u.jam_until, time + 3.0)
					u._telegraph = 0.0
					booms.append([u.position, 22.0, 0.3, Color(1.0, 0.8, 0.4)])
		"firewall":
			for dr in [-1, 0, 1]:
				if tile.y + dr >= 0 and tile.y + dr < ROWS:
					fields[Vector2i(tile.x, tile.y + dr)] = {"team": team, "until": time + CONTAIN_TIME}
		"mycelial_link":
			sel.link_until = time + 6.0
		"supply_drop":
			crates[tile] = {"team": team, "until": time + 10.0}
		"dig_in":
			sel.dug_until = time + 8.0
		"data_breach":
			var t := unit_at(tile.x, tile.y)
			if t and t.team == foe:
				t.breach_until = time + 6.0
				booms.append([t.position, 28.0, 0.3, Color(0.3, 0.95, 0.9)])
		"tide_pool":
			pools[tile] = {"team": team, "until": time + 10.0}
		"flash_forward":
			for step in [2, 1]:
				if can_move(sel, sel.col + dir * step, sel.row):   # a leap: it can pass over a unit
					booms.append([sel.position, 26.0, 0.3, Color(1.0, 0.75, 0.3)])
					sel.move_to(sel.col + dir * step, sel.row)
					booms.append([panel_center(sel.col, sel.row), 26.0, 0.3, Color(1.0, 0.75, 0.3)])
					break
			sel.rooted_until = time + 1.5
		"collapse":
			var blast := int(sel.hp * 0.5)
			booms.append([sel.position, 80.0, 0.6, Color(1.0, 0.4, 0.15)])
			_shake = 0.35
			for u in units_of(foe):
				if u.is_alive() and u.row == sel.row:
					damage(u, blast, null)
			sel.undying_until = -1.0
			sel.take_damage(sel.hp)
		"supernova":
			sel.take_damage(mini(int(sel.hp * 0.25), sel.hp - 1))
			booms.append([sel.position, 70.0, 0.5, Color(1.0, 0.45, 0.2)])
			_shake = 0.3
			for u in units_of(foe):
				if u.is_alive() and u.row == sel.row:
					damage(u, 30, null)

# --- commander doctrines --------------------------------------------------------------

func _update_doctrine(delta: float) -> void:
	if ai.get("doctrine", "") == "":
		return
	var doc: Dictionary = Game.DOCTRINES[ai["doctrine"]]
	if doc["every"] <= 0.0:
		return
	_doctrine_t -= delta
	if _doctrine_t > 0.0:
		return
	_doctrine_t = doc["every"]
	use_doctrine()

## Fire the commander's doctrine once (on its timer; tests call it directly).
func use_doctrine() -> void:
	var targets := player_units.filter(func(u): return u.is_alive())
	var casters := enemy_units.filter(func(u): return u.is_alive())
	if targets.is_empty() or casters.is_empty():
		return
	match ai["doctrine"]:
		"terran":
			# 3 shells over the player's most crowded spot (they arc in, so they can be dodged)
			var tile := _best_column_tile()
			var from: Vector2 = casters[0].position + Vector2(0, -casters[0].sprite.height)
			for dr in [-1, 0, 1]:
				if tile.y + dr >= 0 and tile.y + dr < ROWS:
					shots.append({"kind": "mortar", "team": 1, "src": null, "from": from, "tc": tile.x, "tr": tile.y + dr,
						"t": -0.2 * absi(dr), "dmg": 12})
		"ascendancy":
			targets.sort_custom(func(a, b): return a.hp < b.hp)
			targets[0].marks["analysis"] = {"until": time + MARK_TIME, "team": 1, "accum": 0.0}
			booms.append([targets[0].position, 30.0, 0.3, Color(0.3, 0.95, 0.9)])
		"manyworlds":
			var u: Unit = active_unit() if active_unit().is_alive() else targets[0]
			for dr in [-1, 0, 1]:
				if u.row + dr >= 0 and u.row + dr < ROWS:
					mires[Vector2i(u.col, u.row + dr)] = time + MIRE_TIME
	_announce(1, Game.DOCTRINES[ai["doctrine"]]["name"], 16)
	Sfx.doctrine()

## AI: the player tile whose column, with the rows above and below, covers the most
## living player units (for 3-tile strikes).
func _best_column_tile() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_n := -1
	for u in player_units:
		if not u.is_alive():
			continue
		var n := player_units.filter(func(o): return o.is_alive() and o.col == u.col and absi(o.row - u.row) <= 1).size()
		if n > best_n or (n == best_n and randf() < 0.5):
			best_n = n
			best = Vector2i(u.col, u.row)
	return best

## AI: the living unit of `team` with the most opposing units sharing its row.
func _most_crowded_row_unit(team: int) -> Unit:
	var best: Unit = null
	var best_n := -1
	for u in units_of(team):
		if not u.is_alive():
			continue
		var n := units_of(1 - team).filter(func(o): return o.is_alive() and o.row == u.row).size()
		if n > best_n:
			best_n = n
			best = u
	return best

func _foes_in_row(u: Unit) -> int:
	return units_of(1 - u.team).filter(func(o): return o.is_alive() and o.row == u.row).size()

## AI tile choice: Stake Claim an enemy tile that touches its ground; Containment and
## Mire on a player unit's tile.
func _ai_tile(id: String) -> Vector2i:
	var alive := player_units.filter(func(u): return u.is_alive())
	if id == "stake_claim":
		var options: Array = []
		var ground := _connected_ground(1)
		for k in ground:
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = k + d
				if in_grid(n) and holds(0, n.x, n.y):
					options.append(n)
		return options[randi() % options.size()] if not options.is_empty() else Vector2i(-1, -1)
	if id in OWN_GROUND_CARDS:
		# drop it under (or next to) its most hurt unit
		var own := enemy_units.filter(func(u): return u.is_alive())
		own.sort_custom(func(a, b): return float(a.hp) / a.max_hp < float(b.hp) / b.max_hp)
		return Vector2i(own[0].col, own[0].row) if not own.is_empty() else Vector2i(-1, -1)
	if alive.is_empty():
		return Vector2i(-1, -1)
	if id in ["barrage", "mudslide", "firewall"]:
		return _best_column_tile()
	if id == "data_breach":
		var a: Unit = active_unit()
		return Vector2i(a.col, a.row) if a.is_alive() else Vector2i(alive[0].col, alive[0].row)
	if id == "target_lock":
		alive.sort_custom(func(a, b): return a.hp < b.hp)
		return Vector2i(alive[0].col, alive[0].row)
	# Containment / Mire: usually pin the unit the player is steering
	var t: Unit = active_unit() if active_unit().is_alive() and randf() < 0.6 else alive[randi() % alive.size()]
	return Vector2i(t.col, t.row)

func _ai_card_unit(id: String) -> Unit:
	var alive := enemy_units.filter(func(u): return u.is_alive())
	if id in ["fortify", "medpod", "rewind", "shield_drone", "last_stand", "mycelial_link"]:
		alive.sort_custom(func(a, b): return float(a.hp) / a.max_hp < float(b.hp) / b.max_hp)
		return alive[0]
	if id in ["borrowed_time", "burn_bright"]:
		alive.sort_custom(func(a, b): return a.hp > b.hp)
		return alive[0]
	if id in ["undertow_surge", "suppressing_fire", "supernova", "echo_strike", "riptide", "collapse"]:
		return _most_crowded_row_unit(1)
	return alive[randi() % alive.size()]

## AI row for Flood / Spore Bloom: the row holding the most player units.
func _ai_aim_row() -> int:
	var alive := player_units.filter(func(u): return u.is_alive())
	if alive.is_empty():
		return 4
	var best: int = alive[randi() % alive.size()].row
	var best_n := 0
	for u in alive:
		var n := alive.filter(func(o): return o.row == u.row).size()
		if n > best_n:
			best_n = n
			best = u.row
	return best

func _update_enemy_cards(delta: float) -> void:
	_enemy_card_t -= delta
	if _enemy_card_t > 0.0:
		return
	_enemy_card_t = randf_range(ai["card_min"], ai["card_max"])
	var h: CardHand = hands[1]
	var order := range(h.hand.size())
	if ai["smart_cards"]:
		order.sort_custom(func(a, b): return _ai_card_score(h.hand[a]) > _ai_card_score(h.hand[b]))
	for i in order:
		if _ai_card_score(h.hand[i]) >= 0.0 and h.can_play(i) and play_card(1, i):
			return

## How much the AI wants to play a card right now (smart AI only; < 0 = hold it).
func _ai_card_score(id: String) -> float:
	if not ai["smart_cards"]:
		return 0.0
	var bonus := 0.5 if id in ai.get("favor", []) else 0.0   # each faction's signature plays
	return _ai_card_need(id) + bonus if _ai_card_need(id) >= 0.0 else -1.0

func _ai_card_need(id: String) -> float:
	var hurt := enemy_units.filter(func(u): return u.is_alive() and u.hp < u.max_hp * 0.5).size()
	var dying := enemy_units.filter(func(u): return u.is_alive() and u.hp < u.max_hp * 0.3).size()
	match id:
		"supernova":
			var u := _most_crowded_row_unit(1)
			return 2.5 if u and _foes_in_row(u) > 0 and u.hp > 40 else -1.0
		"suppressing_fire", "undertow_surge", "echo_strike":
			var u := _most_crowded_row_unit(1)
			return 1.5 if u and _foes_in_row(u) > 0 else -1.0
		"medpod", "rewind", "fortify", "regrowth", "shield_drone", "mycelial_link", "supply_drop", "tide_pool":
			return 3.0 if hurt > 0 else -1.0
		"dig_in":
			return 2.0 if hurt > 0 else 0.5
		"flash_forward":
			return 0.8 if ai.get("front", 0.0) > 0.0 else -1.0   # only reckless squads leap in
		"collapse":
			# a unit that's going down anyway takes the row with it
			var u := _most_crowded_row_unit(1)
			return 2.5 if u and _foes_in_row(u) >= 2 and u.hp < u.max_hp * 0.4 else -1.0
		"last_stand":
			return 4.0 if dying > 0 else -1.0
		"hold_the_line":
			return 2.0 if hurt > 0 else 0.5
		"burn_bright":
			return 1.0 if team_energy[1].value < 30.0 and enemy_units.any(func(u): return u.is_alive() and u.hp > 60) else -1.0
		"borrowed_time":
			return 1.0 if team_stamina[1].value < 2.0 else -1.0
		"overclock":
			return 1.0 if team_energy[1].value > 30.0 else 0.0
	return 1.0

## Enemy AI: is a player shot about to hit `u`? (for dodging)
func incoming_shot(u: Unit, horizon := 0.45) -> bool:
	for s in shots:
		if s["kind"] != "bullet" or s["team"] == u.team or row_of_y(s["yb"]) != u.row:
			continue
		var dx: float = (u.position.x - s["x"]) * s["dir"]
		if dx > 0.0 and dx / s["speed"] < horizon:
			return true
	return false

## Enemy AI: row of the weakest living player unit (to line up a shot on it).
func weakest_player_row() -> int:
	var alive := player_units.filter(func(u): return u.is_alive())
	if alive.is_empty():
		return -1
	alive.sort_custom(func(a, b): return a.hp < b.hp)
	return alive[0].row

func _announce(team: int, text: String, size := 20, hold := 1.0) -> void:
	var l := Label.new()
	l.text = text.to_upper()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(440, 30)
	# stack under any announcements still showing, so quick plays don't overlap
	var showing := hud.get_children().filter(func(n): return n.has_meta("announce")).size()
	l.set_meta("announce", true)
	l.position = Vector2(420, 34 + 26 * (showing % 3))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0) if team == 0 else Color(1.0, 0.6, 0.5))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
	# dark backing so it reads over the health bars
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.08, 0.82)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", sb)
	hud.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)

# --- HUD / end -----------------------------------------------------------------------

func _update_hud() -> void:
	var u := active_unit()
	var txt := "Fire: %s" % Game.PRIMARY_NAMES.get(u.primary, "Shot")
	if is_jammed(u):
		txt += "  ·  JAMMED"
	elif u.primary != "charge":
		txt += "  ·  %d energy" % int(primary_cost(u))
	if time < u.overclock_until:
		txt += "  ·  OVERCLOCKED"
	if u.passive != "":
		txt += "\nPassive: %s" % Game.PASSIVE_NAMES[u.passive]
	if aim_slot >= 0:
		txt = ("Aiming %s: right stick picks a tile, R2 confirms\n(L2 to cancel)" if Game.using_pad else
			"Aiming %s: click a tile\n(right-click / Esc to cancel)") % Game.CARDS[hand.hand[aim_slot]]["name"]
	primary_label.text = txt
	$HUD/Controls.text = "D-pad · L1/R1 swap · A fire · X/Y/B cards · Start" if Game.using_pad else "WASD · Q/E swap · Space fire · 1-3 cards · Esc"

func _on_unit_killed(u: Unit) -> void:
	Sfx.unit_death(u)
	Game.stat("lost" if u.team == 0 else "kills")
	charges.erase(u.get_instance_id())
	if u.team == 0 and u.active:
		_swap(1)
	if player_units.all(func(p): return not p.is_alive()):
		var wins := int(Game.run.get("wins", 0))
		if Game.run.get("infinite", false):
			# the end of Infinity and Beyond counts as the won run
			var n := Game.sectors_claimed()
			var reward := Game.complete_run()
			_show_over("THE END OF INFINITY", "%d sectors claimed. This counts as a won run%s.\nEnter: continue" % [n,
				(": %s joins your collection" % Game.CARDS[reward]["name"]) if reward != "" else ""])
			return
		var stats := Game.stats_text(Game.run.get("stats", {}))   # read before the run is gone
		if int(Game.run.get("slot", -1)) >= 0:
			Game.end_run()
		else:
			Game.run = {}
		_show_over("DEFEAT", "Your squad has fallen after %d victories. The run is over.\n%s\nEnter: return to title\n\n%s" % [wins, stats, Game.random_tip()])
	elif enemy_units.all(func(e): return not e.is_alive()):
		var squad_hp := {}
		for p in player_units:
			squad_hp[p.role] = p.hp
		var last_words := Game.commander_line(Game.run["enemy"], "defeat") if ai["boss"] else ""
		Game.win_battle(squad_hp)
		_show_over("VICTORY", ("\"%s\"\n\n" % last_words if last_words != "" else "") + "Enter: choose a card for your deck    Esc: save & return to title")

## End screen (CanvasLayer above everything); everyone stops acting.
func _show_over(text: String, hint: String) -> void:
	Sfx.stinger(text != "DEFEAT")
	battle_on = false
	cancel_aim()
	shots = []
	overlay_text = text
	over_title.text = text
	over_dim.visible = true
	over_title.visible = true
	over_hint.text = hint
	over_hint.visible = true
	for u in player_units + enemy_units:
		u.set_active(false)

# --- drawing -------------------------------------------------------------------------

func _tile_rect(c: int, r: int) -> Rect2:
	return Rect2(GRID_X + c * PANEL_W + 2.0, GRID_Y + r * PANEL_H + 2.0, PANEL_W - 4.0, PANEL_H - 4.0)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for c in COLS:
		for r in ROWS:
			var inner := _tile_rect(c, r)
			var fill := Color(0.22, 0.32, 0.55, 0.55) if holds(0, c, r) else Color(0.55, 0.25, 0.28, 0.55)
			if r % 2 == 1:
				fill = fill.darkened(0.12)
			draw_rect(inner, fill)
			draw_rect(inner, Color(0.8, 0.85, 1.0, 0.25), false, 1.5)
	var mid := GRID_X + (PLAYER_MAX_COL + 1) * PANEL_W
	draw_line(Vector2(mid, GRID_Y - 6), Vector2(mid, GRID_Y + ROWS * PANEL_H + 6), Color(1, 1, 1, 0.35), 2.0)
	if not claim.is_empty():
		var cr := Rect2(GRID_X + claim["col"] * PANEL_W, GRID_Y, PANEL_W, ROWS * PANEL_H)
		var ca := _fade_in_out(claim["until"], 10.0)
		var gold := Color(1.0, 0.82, 0.3)
		_glow_rect(cr, Color(gold, 0.22 * ca))
		# hazard stripes sliding down the claimed column
		var off := fmod(time * 30.0, 28.0)
		var y := cr.position.y - 28.0 + off
		while y < cr.end.y:
			var a := Vector2(cr.position.x, y)
			var pts := PackedVector2Array([a, a + Vector2(cr.size.x, 18), a + Vector2(cr.size.x, 28), a + Vector2(0, 10)])
			for i in pts.size():
				pts[i].y = clampf(pts[i].y, cr.position.y, cr.end.y)
			draw_colored_polygon(pts, Color(gold, 0.08 * ca))
			y += 28.0
		draw_rect(cr, Color(gold, 0.8 * ca), false, 3.0)
		draw_string(font, cr.position + Vector2(6, -6), "CLAIMED %.0fs" % (claim["until"] - time), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, gold)
	# Stake Claim tiles: flag, time left, and a dashed edge when cut off from its ground
	for k in stakes:
		var tr := _tile_rect(k.x, k.y)
		var team: int = stakes[k]["team"]
		var col := Color(1.0, 0.85, 0.3) if team == 0 else Color(1.0, 0.5, 0.4)
		var linked := _connected_ground(team).has(k)
		draw_rect(tr, Color(col, 0.9), false, 2.5 if linked else 1.0)
		var pole := tr.position + Vector2(12, tr.size.y - 6)
		draw_line(pole, pole + Vector2(0, -26), Color(0.9, 0.9, 0.9), 2.0)
		draw_colored_polygon(PackedVector2Array([pole + Vector2(0, -26), pole + Vector2(14, -21), pole + Vector2(0, -16)]), col)
		var left: float = (stakes[k]["until"] - time) / STAKE_TIME
		draw_rect(Rect2(tr.position + Vector2(0, tr.size.y - 3), Vector2(tr.size.x * left, 3)), col)
	for k in mires:
		_draw_mire(_tile_rect(k.x, k.y), _fade_in_out(mires[k], MIRE_TIME), k)
	for k in pools:
		_draw_pool(_tile_rect(k.x, k.y), _fade_in_out(pools[k]["until"], 10.0), k)
	for k in crates:
		_draw_crate(_tile_rect(k.x, k.y), _fade_in_out(crates[k]["until"], 10.0))
	for f in floods:
		var a := _fade_in_out(f["until"], 6.0)
		for c in COLS:
			if holds(f["team"], c, f["row"]):
				_draw_flood(_tile_rect(c, f["row"]), a, c)
	if not spores.is_empty():
		var a := _fade_in_out(spores["until"], 9.0)
		for k in spores["tiles"]:
			_draw_spores(_tile_rect(k.x, k.y), a, k)
	for k in fires:
		_draw_fire(_tile_rect(k.x, k.y), _fade_in_out(fires[k]["until"], EMBER_TIME), k)
	for k in fortified:
		_draw_fortify(_tile_rect(k.x, k.y), _fade_in_out(fortified[k], 10.0), k)
	for k in fields:
		_draw_field(_tile_rect(k.x, k.y), _fade_in_out(fields[k]["until"], CONTAIN_TIME), fields[k]["team"])
	# incoming shells: a closing target ring on the tile they'll hit
	for s in shots:
		if s["kind"] == "mortar" and s["t"] >= 0.0:
			var k: float = clampf(s["t"] / (MORTAR_UP + MORTAR_HANG + MORTAR_DOWN), 0.0, 1.0)
			var tr := _tile_rect(s["tc"], s["tr"])
			var wc := Color(1.0, 0.35, 0.25) if s["team"] == 1 else Color(1.0, 0.8, 0.35)
			draw_rect(tr, Color(wc, 0.12 + 0.18 * k))
			var c := tr.get_center()
			draw_set_transform(c, 0.0, Vector2(1.0, PANEL_H / PANEL_W))
			draw_arc(Vector2.ZERO, PANEL_W * (0.55 - 0.3 * k), 0, TAU, 32, Color(wc, 0.5 + 0.5 * k), 3.0 / (PANEL_H / PANEL_W))
			draw_set_transform(Vector2.ZERO)
	# Sandbags: stacked bags across the row, one layer per hit left
	for bar in barricades:
		var cy := panel_center(0, bar["row"]).y
		for h in bar["hits"]:
			draw_rect(Rect2(bar["x"] - 7, cy + 12 - h * 13, 14, 11), Color(0.75, 0.65, 0.42))
			draw_rect(Rect2(bar["x"] - 7, cy + 12 - h * 13, 14, 11), Color(0.35, 0.28, 0.15), false, 1.5)
	if not void_orb.is_empty():
		var bound := units_of(void_orb["team"]).filter(func(u): return u.is_alive())
		for a in bound.size():
			for b in range(a + 1, bound.size()):
				_draw_tether(bound[a].position, bound[b].position, Color(0.6, 0.3, 1.0), a * 3 + b)
	if not protocol.is_empty():
		var x0 := GRID_X + (0.0 if protocol["team"] == 0 else 3 * PANEL_W)
		draw_string(font, Vector2(x0 + 6, GRID_Y + ROWS * PANEL_H + 4), "PROTOCOL %s  %.1fs" % [protocol["rule"], protocol["until"] - time], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.45, 0.45))
	for team in 2:
		var d: Dictionary = drones[team]
		if not d.is_empty():
			var p := panel_center(d["col"], d["row"]) + Vector2(0, -22 + sin(time * 4.0) * 3.0)
			draw_circle(p, 11.0, Color(0.92, 0.94, 0.97))
			draw_circle(p + Vector2(4.0 if team == 0 else -4.0, 0), 4.5, Color(0.3, 0.9, 1.0))
			draw_arc(p, 11.0, 0, TAU, 20, Color(0.2, 0.25, 0.3), 1.5)
	# Parallax afterimage: faint copy on the tile it last stood on
	for u in player_units + enemy_units:
		if u.is_alive() and u.primary == "afterimage" and (u.prev_col != u.col or u.prev_row != u.row):
			var tex := u.sprite.get_texture()
			var h := u.sprite.height
			var w := tex.get_width() * h / tex.get_height()
			var base := panel_center(u.prev_col, u.prev_row) + Vector2(0, PANEL_H * 0.4)
			var rect := Rect2(base.x - w * 0.5, base.y - h, w, h)
			if u.team == 1:
				draw_set_transform(Vector2(base.x * 2.0, 0), 0.0, Vector2(-1, 1))
			draw_texture_rect(tex, rect, false, Color(0.6, 0.6, 1.0, 0.25))
			draw_set_transform(Vector2.ZERO)
	# shots
	for s in shots:
		if s["kind"] == "mortar":
			var t: float = s["t"]
			if t < 0.0:
				continue   # staggered barrage shell not launched yet
			var target := panel_center(s["tc"], s["tr"])
			var from: Vector2 = s["from"]
			if t < MORTAR_UP:
				var k := t / MORTAR_UP
				draw_circle(Vector2(from.x, lerpf(from.y, -60.0, k * k)), 7.0, Color(1.0, 0.75, 0.35))
			elif t >= MORTAR_UP + MORTAR_HANG:
				var k := (t - MORTAR_UP - MORTAR_HANG) / MORTAR_DOWN
				draw_set_transform(target + Vector2(0, PANEL_H * 0.25), 0.0, Vector2(1.0, 0.4))
				draw_circle(Vector2.ZERO, 8.0 + 18.0 * k, Color(0, 0, 0, 0.25 + 0.3 * k))
				draw_set_transform(Vector2.ZERO)
				draw_circle(Vector2(target.x, lerpf(-60.0, target.y, k * k)), 7.0, Color(1.0, 0.75, 0.35))
			continue
		var color := Color(0.45, 0.8, 1.0) if s["team"] == 0 else Color(1.0, 0.55, 0.35)
		if s.get("ember", false):
			color = Color(1.0, 0.5, 0.15)
		elif s.get("push", false):
			color = Color(0.3, 0.6, 1.0)
		var p := Vector2(s["x"], s["yb"] + s["yo"])
		var sz: float = s["size"]
		draw_rect(Rect2(p.x - 10.0 * sz, p.y - 3.0 * sz, 20.0 * sz, 6.0 * sz), color)
		draw_rect(Rect2(p.x - 10.0 * sz - 12.0 * s["dir"] * sz, p.y - 1.5 * sz, 12.0 * sz, 3.0 * sz), Color(color, 0.4))
	# Charge Beam: orb growing at the muzzle while held
	for u in player_units + enemy_units:
		var amt: float = charges.get(u.get_instance_id(), 0.0)
		if amt > 0.0 and u.is_alive():
			var p := u.position + u.sprite.muzzle_point()
			var r := 5.0 + amt * 0.25
			draw_circle(p, r + 3.0 * sin(time * 30.0), Color(0.4, 0.9, 1.0, 0.35))
			draw_circle(p, r * 0.6, Color(0.85, 1.0, 1.0))
	for b in booms:
		var k: float = clampf(b[2] / 0.4, 0.0, 1.0)   # 1 at the start, 0 when gone
		var c: Color = b[3]
		var r: float = b[1] * (1.2 - k * 0.6)
		draw_circle(b[0], r * 0.8, Color(c.lightened(0.5), 0.35 * k * k))     # flash
		draw_arc(b[0], r, 0, TAU, 32, Color(c, k), 2.0 + 3.0 * k)
		draw_arc(b[0], r * 0.7, 0, TAU, 24, Color(1, 1, 1, 0.4 * k), 1.5)
		for n in 8:   # sparks flying out
			var ang := n * TAU / 8.0 + float(b[1])
			var d1 := r * (0.6 + 0.6 * (1.0 - k))
			draw_line(b[0] + Vector2.from_angle(ang) * d1, b[0] + Vector2.from_angle(ang) * (d1 + 6.0 * k + 2.0), Color(c.lightened(0.3), k), 2.0)
	# aiming reticle (gold if the card can land there, red if not)
	if aim_slot >= 0 and aim_slot < hand.hand.size():
		var ok := valid_tile(0, hand.hand[aim_slot], aim_tile)
		var tr := _tile_rect(aim_tile.x, aim_tile.y).grow(2.0 + sin(time * 10.0) * 2.0)
		var rc := Color(1.0, 0.85, 0.3) if ok else Color(1.0, 0.3, 0.3)
		draw_rect(tr, Color(rc, 0.15))
		draw_rect(tr, rc, false, 3.0)
		var cpos := tr.get_center()
		draw_line(cpos + Vector2(-10, 0), cpos + Vector2(10, 0), rc, 2.0)
		draw_line(cpos + Vector2(0, -10), cpos + Vector2(0, 10), rc, 2.0)

# --- area effect drawing --------------------------------------------------------------

## 0..1 opacity for a timed effect: eases in over its first 0.25s, out over its last 0.6s.
func _fade_in_out(until: float, duration: float) -> float:
	var left := until - time
	var age := duration - left
	if age < 0.0:
		age = 1.0   # lasts longer than its usual duration (stacked or extended): no fade-in
	return clampf(minf(age / 0.25, left / 0.6), 0.0, 1.0)

## Stable pseudo-random 0..1 per tile and index, so particles keep their places.
func _rnd(k: Vector2i, n: int) -> float:
	return fposmod(sin(k.x * 127.1 + k.y * 311.7 + n * 74.7) * 43758.5453, 1.0)

## A soft fill that is stronger at the edges (layered insets).
func _glow_rect(r: Rect2, c: Color) -> void:
	draw_rect(r, Color(c, c.a * 0.6))
	for i in 3:
		draw_rect(r.grow(-2.0 - i * 3.0), Color(c, c.a * (0.5 - i * 0.15)), false, 3.0)

func _draw_fortify(tr: Rect2, a: float, k: Vector2i) -> void:
	var c := Color(0.45, 0.75, 1.0)
	_glow_rect(tr, Color(c, 0.25 * a))
	# shimmer sweeping diagonally across the plate
	var sx := tr.position.x + fmod(time * 70.0 + _rnd(k, 0) * 200.0, tr.size.x + 60.0) - 30.0
	var pts := PackedVector2Array([Vector2(sx, tr.position.y), Vector2(sx + 14, tr.position.y), Vector2(sx - 6, tr.end.y), Vector2(sx - 20, tr.end.y)])
	for i in pts.size():
		pts[i].x = clampf(pts[i].x, tr.position.x, tr.end.x)
	draw_colored_polygon(pts, Color(1, 1, 1, 0.12 * a))
	# corner brackets + a small shield badge
	var g := tr.grow(-3)
	var L := 12.0
	var bc := Color(0.75, 0.9, 1.0, 0.95 * a)
	for corner in [[g.position, 1, 1], [Vector2(g.end.x, g.position.y), -1, 1], [Vector2(g.position.x, g.end.y), 1, -1], [g.end, -1, -1]]:
		draw_line(corner[0], corner[0] + Vector2(L * corner[1], 0), bc, 2.5)
		draw_line(corner[0], corner[0] + Vector2(0, L * corner[2]), bc, 2.5)
	var s := Vector2(tr.end.x - 16, tr.position.y + 9)
	draw_colored_polygon(PackedVector2Array([s + Vector2(-6, -4), s + Vector2(6, -4), s + Vector2(6, 2), s + Vector2(0, 8), s + Vector2(-6, 2)]), Color(0.6, 0.85, 1.0, 0.8 * a))

func _draw_field(tr: Rect2, a: float, team: int) -> void:
	var c := Color(0.3, 0.95, 1.0) if team == 0 else Color(1.0, 0.4, 0.75)
	_glow_rect(tr, Color(c, (0.2 + 0.08 * sin(time * 12.0)) * a))
	for n in 5:
		var x := tr.position.x + tr.size.x * (n + 0.5) / 5.0
		var wob := sin(time * 9.0 + n * 1.7) * 1.5
		draw_line(Vector2(x + wob, tr.position.y + 2), Vector2(x - wob, tr.end.y - 2), Color(c, 0.25 * a), 5.0)
		draw_line(Vector2(x + wob, tr.position.y + 2), Vector2(x - wob, tr.end.y - 2), Color(c.lightened(0.5), 0.85 * a), 1.5)
	# scan line bouncing top to bottom
	var sy := tr.position.y + (0.5 + 0.5 * sin(time * 5.0)) * tr.size.y
	draw_line(Vector2(tr.position.x, sy), Vector2(tr.end.x, sy), Color(1, 1, 1, 0.5 * a), 1.5)
	draw_rect(tr, Color(c, 0.9 * a), false, 2.0)

func _draw_mire(tr: Rect2, a: float, k: Vector2i) -> void:
	var mud := Color(0.32, 0.22, 0.1)
	draw_rect(tr, Color(mud, 0.55 * a))
	# lumpy darker puddles
	for n in 4:
		var p := tr.position + Vector2(tr.size.x * (0.15 + 0.7 * _rnd(k, n)), tr.size.y * (0.3 + 0.45 * _rnd(k, n + 9)))
		draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 14.0 + 10.0 * _rnd(k, n + 3), Color(mud.darkened(0.35), 0.6 * a))
		draw_set_transform(Vector2.ZERO)
	# bubbles swell, then pop
	for n in 3:
		var cyc := fmod(time * 0.9 + _rnd(k, n + 20), 1.0)
		var p := tr.position + Vector2(tr.size.x * (0.2 + 0.6 * _rnd(k, n + 30)), tr.size.y * (0.35 + 0.35 * _rnd(k, n + 40)))
		if cyc < 0.85:
			draw_arc(p, 2.0 + 5.0 * cyc, PI, TAU, 10, Color(0.7, 0.55, 0.3, 0.9 * a), 1.5)
		else:
			for d in 4:
				var ang := d * TAU / 4.0 + 0.4
				draw_circle(p + Vector2.from_angle(ang) * 8.0 * (cyc - 0.85) / 0.15, 1.2, Color(0.7, 0.55, 0.3, a))

func _draw_flood(tr: Rect2, a: float, col: int) -> void:
	var deep := Color(0.12, 0.35, 0.85)
	var top := tr.position.y + 8.0
	# water body below a moving wave line
	var pts := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		var x := tr.position.x + tr.size.x * i / steps
		pts.append(Vector2(x, top + sin(time * 4.0 + x * 0.06) * 3.0))
	var wave := pts.duplicate()
	pts.append(Vector2(tr.end.x, tr.end.y))
	pts.append(Vector2(tr.position.x, tr.end.y))
	draw_colored_polygon(pts, Color(deep, 0.5 * a))
	draw_polyline(wave, Color(0.75, 0.92, 1.0, 0.85 * a), 2.0)
	# glints drifting along with the current
	for n in 3:
		var gx := tr.position.x + fmod(time * 40.0 + n * 50.0 + col * 31.0, tr.size.x)
		var gy := top + 12.0 + n * 9.0
		draw_line(Vector2(gx, gy), Vector2(minf(gx + 14.0, tr.end.x), gy), Color(0.8, 0.95, 1.0, 0.45 * a), 2.0)

func _draw_spores(tr: Rect2, a: float, k: Vector2i) -> void:
	var g := Color(0.45, 0.85, 0.2)
	draw_rect(tr, Color(g, 0.2 * a))
	# hazy clouds
	for n in 3:
		var p := tr.position + Vector2(tr.size.x * (0.2 + 0.6 * _rnd(k, n)), tr.size.y * 0.55)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 16.0 + 4.0 * sin(time * 2.0 + n), Color(g.lightened(0.2), 0.16 * a))
		draw_set_transform(Vector2.ZERO)
	# spores rising and fading
	for n in 7:
		var cyc := fmod(time * (0.35 + 0.2 * _rnd(k, n)) + _rnd(k, n + 7), 1.0)
		var x := tr.position.x + tr.size.x * _rnd(k, n + 14) + sin(time * 2.0 + n) * 5.0
		var y := tr.end.y - cyc * (tr.size.y + 14.0)
		draw_circle(Vector2(x, y), 2.0 + _rnd(k, n + 21) * 1.5, Color(0.8, 1.0, 0.45, 0.9 * a * sin(cyc * PI)))

func _draw_fire(tr: Rect2, a: float, k: Vector2i) -> void:
	var glow := 0.3 + 0.1 * sin(time * 17.0 + k.x)
	draw_rect(tr, Color(1.0, 0.35, 0.05, glow * a))
	# flame tongues along the floor of the tile
	var base := tr.end.y - 3.0
	for n in 5:
		var x := tr.position.x + tr.size.x * (n + 0.5) / 5.0
		var h := 18.0 + 10.0 * sin(time * 11.0 + n * 2.3 + k.y) + 6.0 * _rnd(k, n)
		var w := 9.0
		var tip := Vector2(x + sin(time * 7.0 + n) * 3.0, base - h)
		draw_colored_polygon(PackedVector2Array([Vector2(x - w, base), tip, Vector2(x + w, base)]), Color(1.0, 0.45, 0.1, 0.75 * a))
		draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, base), tip.lerp(Vector2(x, base), 0.35), Vector2(x + w * 0.5, base)]), Color(1.0, 0.85, 0.35, 0.85 * a))
	# embers floating up
	for n in 4:
		var cyc := fmod(time * 0.8 + _rnd(k, n + 5), 1.0)
		var p := Vector2(tr.position.x + tr.size.x * _rnd(k, n + 11) + sin(time * 5.0 + n) * 4.0, base - cyc * 45.0)
		draw_circle(p, 1.6, Color(1.0, 0.75, 0.3, a * (1.0 - cyc)))

## Tide Pool: a clear green-blue pool with rings spreading out from the centre.
func _draw_pool(tr: Rect2, a: float, k: Vector2i) -> void:
	var c := tr.get_center()
	draw_set_transform(c, 0.0, Vector2(1.0, PANEL_H / PANEL_W * 1.6))
	draw_circle(Vector2.ZERO, tr.size.x * 0.45, Color(0.2, 0.75, 0.75, 0.35 * a))
	for n in 3:
		var cyc := fmod(time * 0.6 + n / 3.0 + _rnd(k, n) * 0.1, 1.0)
		draw_arc(Vector2.ZERO, tr.size.x * 0.45 * cyc, 0, TAU, 28, Color(0.7, 1.0, 0.95, 0.7 * a * (1.0 - cyc)), 2.0)
	draw_set_transform(Vector2.ZERO)
	# rising heal sparkles
	for n in 3:
		var cyc := fmod(time * 0.7 + _rnd(k, n + 5), 1.0)
		var p := c + Vector2((_rnd(k, n + 9) - 0.5) * tr.size.x * 0.7, -cyc * 28.0)
		draw_rect(Rect2(p - Vector2(3, 1), Vector2(6, 2)), Color(0.6, 1.0, 0.8, a * (1.0 - cyc)))
		draw_rect(Rect2(p - Vector2(1, 3), Vector2(2, 6)), Color(0.6, 1.0, 0.8, a * (1.0 - cyc)))

## Supply Drop: a crate with a parachute strap and a blinking beacon.
func _draw_crate(tr: Rect2, a: float) -> void:
	var c := tr.get_center() + Vector2(0, 4)
	var box := Rect2(c - Vector2(16, 12), Vector2(32, 22))
	draw_rect(box, Color(0.55, 0.42, 0.22, a))
	draw_rect(box, Color(0.25, 0.18, 0.08, a), false, 2.0)
	draw_line(box.position + Vector2(0, 11), box.position + Vector2(32, 11), Color(0.25, 0.18, 0.08, a), 2.0)
	draw_rect(Rect2(c - Vector2(5, 7), Vector2(10, 10)), Color(0.95, 0.95, 0.95, a))
	draw_rect(Rect2(c - Vector2(1.5, 5), Vector2(3, 6)), Color(0.85, 0.2, 0.2, a))
	draw_rect(Rect2(c - Vector2(3, 3.5), Vector2(6, 3)), Color(0.85, 0.2, 0.2, a))
	if fmod(time, 0.8) < 0.4:
		draw_circle(box.position + Vector2(29, 2), 3.0, Color(0.4, 1.0, 0.5, a))

## Void Orb: a crackling energy line between two bound units.
func _draw_tether(p0: Vector2, p1: Vector2, c: Color, seed_i: int) -> void:
	var pts := PackedVector2Array()
	var n := 10
	var normal := (p1 - p0).orthogonal().normalized()
	for i in n + 1:
		var j := 0.0 if i == 0 or i == n else sin(time * 25.0 + i * 1.9 + seed_i) * 6.0
		pts.append(p0.lerp(p1, float(i) / n) + normal * j)
	draw_polyline(pts, Color(c, 0.25), 7.0)
	draw_polyline(pts, Color(c.lightened(0.4), 0.85), 2.0)
	draw_circle(p0.lerp(p1, 0.5), 5.0 + 1.5 * sin(time * 8.0), Color(c.lightened(0.5), 0.9))
