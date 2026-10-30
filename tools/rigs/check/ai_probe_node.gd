extends Node
## Enemy AI behaviour probes (kb/proposals/codex-enemy-ai.md, implementation checks).
## godot --path . --headless res://tools/rigs/check/ai_probe.tscn
## Uses throwaway save slot 99, deleted afterwards.
var _fails := 0
var bf

func _ok(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	Engine.time_scale = 3.0
	await _empty_lane()
	await _mortar()
	await _resting()
	await _refraction()
	await _recovery()
	await _volley()
	await _dodge_once()
	await _cards()
	await _bursts()
	await _lanes()
	Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	print("FAILS %d" % _fails)
	get_tree().quit()

## A 3v3 battle against `enemy` at difficulty `lvl`, everyone rooted and spread out.
func _battle(enemy: String, lvl: int) -> Node:
	Game.new_run("banner_marshal", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = enemy
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	bf = main.get_node("Battlefield")
	bf.ai = Game.ai_params(lvl, Game.leader_by_id(enemy)["faction"], false)
	bf.ai["card_min"] = 999.0
	bf.ai["card_max"] = 999.0
	bf._enemy_card_t = 999.0
	for u in bf.player_units + bf.enemy_units:
		u.rooted_until = 9999.0
		u.max_hp = 5000
		u.hp = 5000
	return main

func _place(u: Unit, c: int, r: int) -> void:
	u.col = c
	u.row = r
	u.prev_col = c
	u.prev_row = r
	u.position = bf.panel_center(c, r)

func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout

func _done(main: Node) -> void:
	main.queue_free()
	await get_tree().process_frame

func _enemy(key_part: String) -> Unit:
	for u in bf.enemy_units:
		if u.key.ends_with(key_part):
			return u
	return null

func _empty_lane() -> void:
	var main: Node = await _battle("claim_lord", 1)
	var e := _enemy("claim_lord")
	_place(e, 4, 0)
	for i in bf.player_units.size():
		_place(bf.player_units[i], 0, 3 + i * 2)
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	var before: float = e.last_fired_at
	await _wait(4.0)
	_ok(e.last_fired_at == before, "no shots into an empty lane")
	_place(bf.player_units[0], 1, 0)
	await _wait(5.0)
	_ok(e.last_fired_at != before, "fires once someone is in its row")
	await _done(main)

func _mortar() -> void:
	var main: Node = await _battle("banner_marshal", 1)
	var e := _enemy("siege_rig")
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	_place(e, 5, 4)                      # the shell lands on column 2
	_place(bf.player_units[0], 0, 4)     # same row, wrong column
	_place(bf.player_units[1], 0, 0)
	_place(bf.player_units[2], 0, 8)
	var before: float = e.last_fired_at
	await _wait(4.0)
	_ok(e.last_fired_at == before, "Siege Rig holds the mortar when nobody's on the landing tile")
	_place(bf.player_units[0], 2, 4)
	await _wait(5.0)
	_ok(e.last_fired_at != before, "Siege Rig fires when someone is on the landing tile")
	await _done(main)

func _resting() -> void:
	var main: Node = await _battle("mission_mother", 1)
	var e := _enemy("red_giant")
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	_place(e, 4, 4)
	_place(bf.player_units[0], 1, 4)
	e.max_hp = 180
	e.hp = 40                            # 22%
	var before: float = e.last_fired_at
	await _wait(4.0)
	_ok(e.last_fired_at == before, "Red Giant holds fire at 22% HP")
	e.hp = 90                            # 50%
	await _wait(5.0)
	_ok(e.last_fired_at != before, "Red Giant resumes above 35% HP")
	await _done(main)

func _refraction() -> void:
	var main: Node = await _battle("prism_elder", 2)
	var e := _enemy("prism_elder")
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	e.rooted_until = -1.0
	_place(e, 4, 1)
	_place(bf.player_units[0], 0, 2)
	_place(bf.player_units[1], 0, 4)
	_place(bf.player_units[2], 0, 8)
	bf.team_stamina[1].value = float(bf.team_stamina[1].SEGMENTS)
	e._ai_step(bf.ai)
	_ok(e._plan_dir == Vector2i.DOWN, "Prism Elder starts a two-step Refraction setup toward the targets")
	await _wait(0.8)
	_ok(e.refract_ready and e.row == 3, "the second step arms Refraction (row %d, ready %s)" % [e.row, e.refract_ready])
	await _done(main)

func _recovery() -> void:
	var main: Node = await _battle("claim_lord", 3)
	for i in bf.enemy_units.size():
		_place(bf.enemy_units[i], 4, i * 3)
		_place(bf.player_units[i], 1, i * 3)
	bf.team_energy[1].value = 10.0
	var fired_low := false
	var t := 0.0
	var last := {}
	for u in bf.enemy_units:
		last[u] = u.last_fired_at
	while t < 4.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		for u in bf.enemy_units:
			if u.last_fired_at != last[u] and bf._ai_recover[1]:
				fired_low = true
			last[u] = u.last_fired_at
	_ok(not fired_low, "no shots while the squad lets its energy refill")
	await _done(main)

func _volley() -> void:
	var main: Node = await _battle("director_zero", 2)
	for i in bf.enemy_units.size():
		_place(bf.enemy_units[i], 4, i * 3)
		_place(bf.player_units[i], 1, i * 3)
		bf.enemy_units[i]._ai_attack = 5.0
	bf._after_enemy_card("containment")
	var soon: Array = bf.enemy_units.filter(func(u): return u._ai_attack <= 0.7)
	_ok(soon.size() == 3, "a Containment combo lines up a staggered volley (%d of 3)" % soon.size())
	await _done(main)

func _dodge_once() -> void:
	var main: Node = await _battle("tide_speaker", 3)
	var e: Unit = bf.enemy_units[0]
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	e.rooted_until = -1.0
	_place(e, 5, 4)
	_place(bf.player_units[0], 0, 4)
	_place(bf.player_units[1], 0, 0)
	_place(bf.player_units[2], 0, 8)
	bf.ai["dodge"] = 1.0
	bf.ai["move_min"] = 99.0
	bf.ai["move_max"] = 99.0
	e._ai_move = 99.0
	bf.team_stamina[1].value = float(bf.team_stamina[1].SEGMENTS)
	bf.team_energy[0].value = 100.0
	bf.fire_primary(bf.player_units[0])
	var seen_at := -1.0
	var moved_at := -1.0
	var t := 0.0
	while t < 2.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if seen_at < 0.0 and e._react_t >= 0.0:
			seen_at = bf.time
		if moved_at < 0.0 and e.row != 4:
			moved_at = bf.time
	_ok(moved_at > 0.0, "a dodging enemy sidesteps a visible shot")
	_ok(seen_at > 0.0 and moved_at - seen_at >= 0.25, "only after its reaction delay (%.2fs)" % (moved_at - seen_at))
	_ok(e._threat_seen.size() == 1, "and reacts to that shot once")
	await _done(main)

func _give(id: String) -> void:
	var h: CardHand = bf.hands[1]
	h.hand = [id]
	h.hand_disc = [0.0]
	bf.team_energy[1].value = 100.0
	bf._ai_plans.clear()

func _cards() -> void:
	var main: Node = await _battle("mission_mother", 2)
	var hurt: Unit = bf.enemy_units[2]
	for i in bf.enemy_units.size():
		_place(bf.enemy_units[i], 4, i * 3)
		_place(bf.player_units[i], 1, i * 3)
	hurt.hp = int(hurt.max_hp * 0.3)
	_give("medpod")
	var v: float = bf._ai_card_score("medpod")
	bf.play_card(1, 0)
	_ok(v > 0.0 and hurt.heal_until > bf.time, "Medpod goes to the unit it was scored for (the hurt one)")
	# Flood from the ally in the busiest player row
	_place(bf.player_units[1], 1, 6)
	_place(bf.player_units[1], 2, 6)
	_place(bf.player_units[0], 0, 6)
	_place(bf.player_units[2], 1, 3)
	_give("flood")
	bf._ai_card_score("flood")
	bf.play_card(1, 0)
	_ok(bf.floods.size() > 0 and bf.floods[-1]["row"] == 6, "Flood aims from the ally in the busiest row (row %s)" % (bf.floods[-1]["row"] if bf.floods.size() > 0 else "none"))
	# useless cards are held
	for o in bf.enemy_units:
		if o != hurt:
			o.hp = 0
	_give("collapse")
	_ok(bf._ai_card_score("collapse") < 0.0, "Collapse is never played by the last unit standing")
	for f in bf.player_units:
		_place(f, 0, 8)
	_place(hurt, 4, 0)
	_give("supernova")
	_ok(bf._ai_card_score("supernova") < 0.0, "Supernova is held with nobody in the row")
	await _done(main)

func _bursts() -> void:
	var main: Node = await _battle("chief_visionary", 2)
	var e := _enemy("field_scholar")
	for o in bf.enemy_units:
		if o != e:
			o.hp = 0
	_place(e, 4, 4)
	_place(bf.player_units[0], 1, 4)
	_place(bf.player_units[1], 0, 0)
	_place(bf.player_units[2], 0, 8)
	bf.ai["attack_min"] = 3.0
	bf.ai["attack_max"] = 3.0
	e._ai_attack = 0.1
	var shots := []
	var last: float = e.last_fired_at
	var t := 0.0
	while t < 5.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		if e.last_fired_at != last:
			shots.append(e.last_fired_at)
			last = e.last_fired_at
		bf.team_energy[1].value = 100.0
	var gaps := []
	for i in range(1, mini(shots.size(), 3)):
		gaps.append(snappedf(shots[i] - shots[i - 1], 0.01))
	_ok(shots.size() >= 3 and gaps.all(func(g): return absf(g - 1.4) < 0.15), "Field Scholar fires a mark burst 1.4s apart (gaps %s)" % str(gaps))
	await _done(main)
	# Captain leaves an Interval-marked target to detonate
	main = await _battle("captain_everafter", 2)
	var c := _enemy("captain_everafter")
	for o in bf.enemy_units:
		if o != c:
			o.hp = 0
	_place(c, 4, 4)
	_place(bf.player_units[0], 1, 4)
	_place(bf.player_units[1], 0, 0)
	_place(bf.player_units[2], 0, 8)
	bf.player_units[0].marks["interval"] = {"until": 9999.0, "team": 1, "accum": 0.0}
	var before: float = c.last_fired_at
	await _wait(4.0)
	_ok(c.last_fired_at == before, "Captain Everafter doesn't reset a waiting Interval Mark")
	await _done(main)

func _lanes() -> void:
	var main: Node = await _battle("claim_lord", 3)
	for i in bf.enemy_units.size():
		_place(bf.enemy_units[i], 3 + i, 4)
	_place(bf.player_units[0], 1, 4)
	_place(bf.player_units[1], 1, 0)
	_place(bf.player_units[2], 1, 8)
	var u: Unit = bf.enemy_units[2]
	var crowded: float = bf.ai_tile_score(u, u.col, 4)
	bf.ai["level"] = 2
	var early: float = bf.ai_tile_score(u, u.col, 4)
	_ok(crowded < early, "level 3+: a third ally on the same lane scores lower (%.1f vs %.1f)" % [crowded, early])
	await _done(main)
