extends Node
## Card set 2 acceptance probe. Staged battles, both teams, disposable save slot 99.
## Extended as each implementation step lands; one result per rule and per new card.
var _fails := 0
var bf: Node2D
var _main: Node
const REUSED_CARDS := ["quick_march", "field_repairs", "spotter_flare", "creeping_barrage", "smoke_screen", "volley_fire",
	"calibrate", "efficiency_pass", "signal_jam", "neural_link", "quarantine", "wave_rider", "brine_splash", "sap_poultice",
	"barnacle_shell", "tsunami", "overgrowth", "spare_parts", "slow_burn", "afterglow", "lifeline", "red_shift",
	"cinder_trail", "second_wind", "time_debt", "heat_death"]

const BOARD_CARDS := ["razor_wire", "pulse_mine", "thornvine", "overwatch", "annex", "orbital_strike", "holo_decoy",
	"mirror_shield", "phase_shift", "perfect_model", "maelstrom", "pollen_cloud", "worldshaper", "event_horizon"]

func _ok(condition: bool, what: String) -> void:
	print(("PASS " if condition else "FAIL ") + what)
	if not condition:
		_fails += 1

func _ready() -> void:
	await _rules()
	for id in REUSED_CARDS:
		var both := true
		for team in 2:
			await _battle()
			both = _reused_card(team, id) and both
		_ok(both, "CARD %s: main effect and limits, both teams" % id)
	for id in BOARD_CARDS:
		var both := true
		for team in 2:
			await _battle()
			both = _board_card(team, id) and both
		_ok(both, "CARD %s: board effect, both teams" % id)
	await _done()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	print("FAILS %d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _battle() -> void:
	await _done()
	Game.new_run("banner_marshal", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = "chief_visionary"
	Game.run["phase"] = "battle"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await get_tree().process_frame
	bf = _main.get_node("Battlefield")
	bf.set_process(false)
	bf.time = 10.0
	bf.ai["doctrine"] = ""
	bf.shots.clear()
	for team in 2:
		bf.hands[team].set_process(false)
		bf.team_energy[team].set_process(false)
		bf.team_stamina[team].set_process(false)
		for i in bf.units_of(team).size():
			var u: Unit = bf.units_of(team)[i]
			u.set_process(false)
			u.passive = ""
			u.primary = "standard"
			u.alt_primary = ""
			u.max_hp = 1000
			u.hp = 800
			u.place(0 if team == 0 else 5, 2 + i * 2)
	bf._set_active(0)

func _done() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
		await get_tree().process_frame
	_main = null

func _give(team: int, id: String) -> CardHand:
	var h: CardHand = bf.hands[team]
	h.setup(["sandbags", "sandbags", "sandbags", id], bf.team_energy[team])
	h.hold = false
	bf.team_energy[team].value = 100.0
	bf._ai_plans.clear()
	return h

func _play(team: int, id: String, u: Unit, tile := Vector2i(-1, -1)) -> bool:
	var h := _give(team, id)
	if team == 0:
		bf._set_active(bf.player_units.find(u))
	else:
		bf._ai_plans[id] = {"unit": u, "tile": tile, "value": 2.0}
	return bf.play_card(team, h.hand.find(id), tile)

func _rules() -> void:
	var copies_ok := true
	var locks_ok := true
	var draws_ok := true
	var alt_ok := true
	var pushes_ok := true
	for team in 2:
		await _battle()
		var u: Unit = bf.units_of(team)[0]
		var h: CardHand = bf.hands[team]
		h.setup(["deploy_drone", "deploy_drone"], bf.team_energy[team], {"deploy_drone": [5.0]})
		var first := h.copy_mark(0)
		var other := h.copy_mark(1)
		var price := h.cost_of(0)
		for i in 2:
			bf.team_energy[team].value = 100.0
			if team == 1:
				bf._ai_plans["deploy_drone"] = {"unit": u}
			copies_ok = bf.play_card(team, 0) and copies_ok
		copies_ok = copies_ok and first != other and bf.drones[team].size() == 2 and Game.card_cost("deploy_drone") == 40.0
		var unchanged: Dictionary = bf.drones[team][other].duplicate()
		u.place(0 if team == 0 else 5, 7)
		h._draw_card_from_deck()
		h._draw_card_from_deck()
		var slot := 0 if h.copy_mark(0) == first else 1
		copies_ok = copies_ok and h.cost_of(slot) == price
		bf.team_energy[team].value = 100.0
		bf.play_card(team, slot)
		bf.time += 120.0
		bf._update_board(0.0)
		copies_ok = copies_ok and bf.drones[team].size() == 2 and bf.drones[team][first]["row"] == 7 and bf.drones[team][other]["col"] == unchanged["col"] and bf.drones[team][other]["row"] == unchanged["row"]

		await _battle()
		u = bf.units_of(team)[0]
		var origin := Vector2i(u.col, u.row)
		bf.fields[origin] = {"team": 1 - team, "until": bf.time + 20.0}
		bf.mires[origin] = bf.time + 20.0
		u.rooted_until = bf.time + 20.0
		bf.team_stamina[team].value = 0.0
		locks_ok = _play(team, "flash_forward", u) and locks_ok
		locks_ok = locks_ok and absi(u.col - origin.x) == 2 and bf.team_stamina[team].value == 0.0 and u.rooted_until == bf.time + 1.5

		await _battle()
		u = bf.units_of(team)[0]
		for id in ["requisition", "recompile"]:
			draws_ok = _play(team, id, u) and draws_ok
			h = bf.hands[team]
			h.draw_time = 100.0
			h._process(2.0)
			draws_ok = draws_ok and is_equal_approx(h._draw_t, 3.0)
			h._process(5.0)
			draws_ok = draws_ok and is_equal_approx(h._draw_t, 10.0) and h.draw_boost_left == 0.0

		await _battle()
		u = bf.units_of(team)[0]
		u.alt_primary = "standard"
		u.alt_role = "heavy"
		bf.team_energy[team].value = 100.0
		alt_ok = bf.fire_alt(u) and alt_ok
		var energy_before: float = bf.team_energy[team].value
		alt_ok = not bf.fire_alt(u) and alt_ok and bf.team_energy[team].value == energy_before
		bf.time += 1.5
		alt_ok = bf.fire_alt(u) and alt_ok
		bf.time += 1.5
		u.alt_primary = "charge"
		u.charging_alt = true
		bf.charges[u.get_instance_id()] = 10.0
		bf.release_charge(u)
		alt_ok = alt_ok and is_equal_approx(u.alt_ready_at, bf.time + 1.5)
		u.charging_alt = true
		bf.charge_tick(u, 0.5)
		alt_ok = alt_ok and not bf.charges.has(u.get_instance_id())
		if team == 0:
			bf._update_hud()
			alt_ok = alt_ok and "1.5s" in bf.primary_label.text

		await _battle()
		u = bf.units_of(team)[0]
		var hp := u.hp
		pushes_ok = not bf.force_move(u, Vector2i(-1, u.row)) and pushes_ok
		pushes_ok = pushes_ok and u.hp == hp - 8 and is_equal_approx(u.stunned_until, bf.time + 0.5)
		pushes_ok = not bf.try_move(u, Vector2i.DOWN) and not bf.fire_primary(u) and pushes_ok
		bf.time += 0.51
		pushes_ok = bf.try_move(u, Vector2i.DOWN) and bf.fire_primary(u) and pushes_ok
	_ok(copies_ok, "RULE MK copies: both teams, independent lasting drones, stable marks and discounts on reshuffle")
	_ok(locks_ok, "RULE card movement: both teams escape fields, roots and mud without stamina")
	_ok(draws_ok, "RULE draw boost: Requisition/Recompile draw at 1.5x for exactly 6s, both teams")
	_ok(alt_ok, "RULE alternate fire: 1.5s cooldown, charge release, energy protection and HUD hint")
	_ok(pushes_ok, "RULE blocked push: 8 HP, 0.5s stun, movement/fire blocked then restored, both teams")

func _reused_card(team: int, id: String) -> bool:
	var u: Unit = bf.units_of(team)[0]
	var foe: Unit = bf.units_of(1 - team)[0]
	var tile := Vector2i(foe.col, foe.row)
	var hp := u.hp
	var enemy_hp := foe.hp
	var base: int = Game.ROLES[u.role]["shot_dmg"]
	var own: Array = bf.units_of(team)
	var enemies: Array = bf.units_of(1 - team)
	if id == "quick_march":
		bf.team_stamina[team].value = 1.25
	if id == "field_repairs":
		u.last_moved_at = bf.time - 2.0
	if id == "volley_fire":
		own[1].primary = "charge"
		own[2].primary = "mortar"
	if id == "wave_rider":
		u.rooted_until = bf.time + 20.0
		bf.fields[Vector2i(u.col, u.row)] = {"team": 1 - team, "until": bf.time + 20.0}
		tile = Vector2i(u.col, u.row - 2)
		bf.team_stamina[team].value = 0.0
	if id == "sap_poultice":
		var here := Vector2i(u.col, u.row)
		bf.fires[here] = {"until": bf.time + 8.0, "next": bf.time + 1.0}
		bf.spores = {"team": team, "tiles": {here: true}, "until": bf.time + 9.0, "next_spread": bf.time + 3.0, "next_tick": bf.time + 1.0}
	if id == "tsunami":
		enemies[1].place(4 if team == 0 else 1, 4)
	if id == "second_wind":
		u.hp = 200
	if id == "heat_death":
		for a: Unit in own:
			a.hp = 50
		for i in enemies.size():
			enemies[i].hp = 30 + 10 * i
	if not _play(team, id, u, tile):
		print("DETAIL play rejected: %s team %d" % [id, team])
		return false
	match id:
		"quick_march":
			return is_equal_approx(bf.team_stamina[team].value, 3.25)
		"field_repairs":
			if u.hp != hp + 25:
				return false
			u.last_moved_at = bf.time
			return _play(team, id, u) and u.hp == hp + 40
		"spotter_flare":
			bf.damage(foe, 20, null)
			if foe.hp != enemy_hp - 25:
				return false
			bf.time += 4.01
			bf.damage(foe, 20, null)
			return foe.hp == enemy_hp - 45
		"creeping_barrage":
			if bf.shots.size() != bf.rows:
				return false
			for r in bf.rows:
				if bf.shots[r]["dmg"] != 10 or bf.shots[r]["tr"] != r or not is_equal_approx(bf.shots[r]["t"], -0.3 * r):
					return false
			bf._update_shots(1.51)
			return foe.hp == enemy_hp - 10
		"smoke_screen":
			bf.fire_primary(foe)
			var shot: Dictionary = bf.shots.back()
			bf._bullet_hit(shot, u)
			if u.hp != hp - int(round(float(shot["dmg"]) * 0.5)):
				return false
			hp = u.hp
			var drone_shot: Dictionary = bf._bullet(null, foe.position, u.row, 10)
			drone_shot["team"] = 1 - team
			bf._bullet_hit(drone_shot, u)
			return u.hp == hp - 5
		"volley_fire":
			return bf.shots.size() == 3 and is_equal_approx(bf.team_energy[team].value, 74.0) and own.all(func(a): return a.last_fired_at == bf.time)
		"calibrate":
			for i in 4:
				bf.fire_primary(u)
				if bf.shots.back()["dmg"] != base + (3 if i < 3 else 0):
					return false
			if u.calibrate_left != 0:
				return false
			bf.shots.clear()
			u.calibrate_left = 1
			u.primary = "refraction"
			u.refract_ready = true
			bf.team_energy[team].value = 100.0
			bf.fire_primary(u)
			bf._update_shots(0.3)
			return bf.shots.size() == 3 and bf.shots[1]["dmg"] == bf.REFRACT_SPLIT_DMG + 3 and bf.shots[2]["dmg"] == bf.REFRACT_SPLIT_DMG + 3
		"efficiency_pass":
			var energy_before: float = bf.team_energy[team].value
			for a: Unit in own:
				bf.fire_primary(a)
			if bf.team_energy[team].value != energy_before or not own.all(func(a): return a.free_shots == 0):
				return false
			bf.fire_primary(u)
			return bf.team_energy[team].value < energy_before
		"signal_jam":
			var h := _give(1 - team, "requisition")
			if bf.play_card(1 - team, h.hand.find("requisition")) or h.hand.size() != 2:
				return false
			bf.time += 5.0
			return bf.play_card(1 - team, h.hand.find("requisition"))
		"neural_link":
			bf.fire_primary(u)
			bf._bullet_hit(bf.shots.back(), foe)
			return foe.marks.has("analysis") and foe.marks["analysis"]["team"] == team
		"quarantine":
			return bf.fields.size() == 4 and not bf.try_move(foe, Vector2i.UP) and bf.fields.values().all(func(f): return is_equal_approx(f["until"], bf.time + 3.0))
		"wave_rider":
			return u.row == tile.y and u.rooted_until < bf.time and bf.team_stamina[team].value == 0.0
		"brine_splash":
			return foe.row == tile.y - 1 and foe.forced_at == bf.time
		"sap_poultice":
			bf.time += 3.0
			bf._update_units(3.0)
			return u.hp == hp + 12 and not bf.fires.has(Vector2i(u.col, u.row)) and not bf.spores["tiles"].has(Vector2i(u.col, u.row))
		"barnacle_shell":
			if u.barrier != 10.0:
				return false
			bf.time += 5.0
			bf._update_units(5.0)
			bf.time += 1.0
			bf._update_units(1.0)
			return is_equal_approx(u.barrier, 25.0)
		"tsunami":
			return foe.hp == enemy_hp - 8 and enemies[1].col == (5 if team == 0 else 0) and foe.stunned_until > bf.time
		"overgrowth":
			return bf.spores["tiles"].size() == 4 and foe.rooted_until == bf.time + 2.0 and bf.spores["until"] == bf.time + 9.0
		"spare_parts":
			return u.hp == hp - 10 and bf.hands[team].hand.size() == 2 and bf.hands[team].draw_boost_left == 6.0
		"slow_burn":
			if bf.fires[tile]["until"] != bf.time + 6.0:
				return false
			bf.time += 1.01
			bf._update_board(1.01)
			return foe.hp == enemy_hp - bf.FIRE_DPS
		"afterglow":
			bf.fire_primary(u)
			bf.time += 6.01
			bf.fire_primary(u)
			return u.hp == hp + 3
		"lifeline":
			bf.damage(u, 80, foe)
			u.take_damage(80)
			if u.hp != hp - 30:
				return false
			bf.time += 6.01
			bf.damage(u, 80, foe)
			return u.hp == hp - 110
		"red_shift":
			bf.fire_primary(u)
			return bf.shots.back()["dmg"] == base + 3 and is_equal_approx(bf.shots.back()["speed"], bf.SHOT_SPEED * 1.5)
		"cinder_trail":
			bf.fire_primary(u)
			bf._bullet_hit(bf.shots.back(), foe)
			return bf.fires.has(tile) and bf.fires[tile]["until"] == bf.time + bf.EMBER_TIME
		"second_wind":
			if u.hp != 500:
				return false
			u.heal(100)
			if u.hp != 500:
				return false
			bf.time += 15.0
			u.heal(100)
			return u.hp == 600 and not _play(team, id, u)
		"time_debt":
			var e: EnergyBar = bf.team_energy[team]
			var s: StaminaBar = bf.team_stamina[team]
			e._delay = 0.0
			e.value = 0.0
			s.value = 0.0
			s.refill_time = 1.0
			e._process(1.0)
			s._process(1.0)
			if e.value != 60.0 or s.value != 2.0:
				return false
			e._process(3.0)
			s._process(3.0)
			e.value = 0.0
			s.value = 0.0
			e._process(3.0)
			s._process(3.0)
			if e.value != 0.0 or s.value != 0.0:
				return false
			e._process(0.5)
			s._process(0.5)
			return e.value == 15.0 and s.value == 0.5
		"heat_death":
			return own.all(func(a): return a.hp == 40) and enemies[0].hp == 24 and enemies[1].hp == 32 and enemies[2].hp == 40 and bf.team_energy[team].value == 76.0
	return false


## Advance the paused battle clock and run the board update once.
func _tick(secs: float) -> void:
	bf.time += secs
	bf._update_set2_board()

func _board_card(team: int, id: String) -> bool:
	var own: Array = bf.units_of(team)
	var enemies: Array = bf.units_of(1 - team)
	var u: Unit = own[0]
	var foe: Unit = enemies[0]
	var fwd := 1 if team == 0 else -1
	var back_foe := 5 if team == 0 else 0     # the foe's back column
	var near := Vector2i(foe.col, foe.row + 1)  # an empty foe-side tile beside it
	var hp := foe.hp
	match id:
		"razor_wire", "pulse_mine":
			if not _play(team, id, u, near):
				return false
			var st: float = bf.team_stamina[1 - team].value
			foe.move_to(near.x, near.y)
			if id == "razor_wire":
				return foe.hp == hp - 10 and bf.team_stamina[1 - team].value < st
			return foe.hp == hp - 15 and not bf.traps.has(near)
		"thornvine":
			if not _play(team, id, u, Vector2i(foe.col, foe.row)):
				return false
			_tick(1.05)
			return foe.hp == hp - 4
		"overwatch":
			if not _play(team, id, u):
				return false
			foe.place(foe.col, u.row + 1)   # start outside the watched row
			var shots: int = bf.shots.size()
			foe.move_to(foe.col, u.row)
			return bf.shots.size() > shots and u.overwatch_left == 2
		"annex":
			var t1 := Vector2i(3 if team == 0 else 2, 1)
			var t2 := Vector2i(3 if team == 0 else 2, 7)
			if not _play(team, id, u, t1) or not bf.holds(team, t1.x, t1.y):
				return false
			_tick(60.0)
			if not bf.holds(team, t1.x, t1.y):
				return false   # lasts until replayed
			_play(team, id, u, t2)
			return bf.holds(team, t2.x, t2.y) and not bf.holds(team, t1.x, t1.y)
		"orbital_strike":
			enemies[1].place(foe.col, foe.row + 1)
			var hp2: int = enemies[1].hp
			if not _play(team, id, u, Vector2i(foe.col, foe.row)):
				return false
			_tick(1.0)
			if foe.hp != hp:
				return false   # not before the warning ends
			_tick(0.6)
			return foe.hp == hp - 45 and enemies[1].hp == hp2 - 15
		"holo_decoy":
			var t := Vector2i(u.col + fwd, u.row)
			if not _play(team, id, u, t):
				return false
			return not bf.decoys[team].is_empty() and not bf.can_move(own[1], t.x, t.y) \
				and bf.barricades.any(func(b): return b.get("decoy", false) and b["team"] == team)
		"mirror_shield":
			if not _play(team, id, u):
				return false
			var before: int = u.hp
			var shots: int = bf.shots.size()
			bf.damage(u, 8, foe, {"team": 1 - team})
			return u.hp == before and bf.shots.size() == shots + 1 and bf.shots[-1]["team"] == team
		"phase_shift":
			var dt := Vector2i(u.col + fwd, 0)
			bf.decoys[team] = {"col": dt.x, "row": dt.y, "until": bf.time + 6.0}
			var here := Vector2i(u.col, u.row)
			if not _play(team, id, u):
				return false
			return u.col == dt.x and u.row == dt.y and bf.decoys[team]["col"] == here.x and bf.decoys[team]["row"] == here.y
		"perfect_model":
			if not _play(team, id, u):
				return false
			u.place(u.col, 3)   # no enemy in row 3
			var b: Dictionary = bf._bullet(u, u.position, 3, 8)
			return b["dmg"] == 12 and b["ty"] != b["yb"]
		"maelstrom":
			if not _play(team, id, u, near):
				return false
			_tick(1.05)
			return foe.row == near.y
		"pollen_cloud":
			if not _play(team, id, u, Vector2i(foe.col, foe.row)):
				return false
			var before: int = u.hp
			bf.damage(u, 10, foe, {"team": 1 - team})
			return u.hp == before - 7
		"worldshaper":
			foe.place(back_foe, foe.row)
			if not _play(team, id, u):
				return false
			return foe.col == back_foe - fwd and bf.flooded_col(1 - team, back_foe)
		"event_horizon":
			if not _play(team, id, u, Vector2i(foe.col, foe.row)):
				return false
			var other: Unit = enemies[1]
			other.move_to(foe.col, foe.row + 1)
			return foe.rooted_until > bf.time and other.rooted_until > bf.time
	return false
