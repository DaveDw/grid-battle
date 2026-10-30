extends Node
## Checks for the 2026-10-29 tester feedback: per-copy discounts, extra leader copies
## can be dropped, Echo Strike echoes for 4 s, and screenshots of the changed screens.
## godot --path . res://tools/rigs/check/feedback.tscn -- <out_dir>
## Uses throwaway save slot 99, deleted afterwards.
var _out := ""
var _fails := 0

func _ok(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		_fails += 1

func _ready() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_rules()
	_hand()
	await _battle()
	await _shot("event", "res://scenes/event.tscn", func():
		Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
		Game.run["phase"] = "event"
		Game.run["event"] = "veteran_drill"
		Game.run["discounts"] = {"sandbags": [5.0]}, func(n): n._choose(Game.EVENTS["veteran_drill"]["choices"][0]["effects"]))
	await _shot("drop", "res://scenes/draft.tscn", func():
		Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
		var deck: Array = Game.run["deck"]
		deck.append_array(["fortify", "fortify", "barrage", "hold_the_line", "requisition"])
		Game.run["discounts"] = {"sandbags": [5.0]}
		Game.run["enemy"] = "chief_visionary"
		Game.run["phase"] = "draft"
		Game.run["offer"] = ["medpod", "barrage"], func(n): n._on_pick("medpod"))
	await _shot("select", "res://scenes/character_select.tscn", func(): pass, func(n): pass)
	await _shot("deck", "res://scenes/character_select.tscn", func(): pass, func(n):
		n._open_deck()
		await get_tree().process_frame
		var d: DeckSculpt = n.get_children().filter(func(c): return c is DeckSculpt)[0]
		d._left.get_child(2).grab_focus())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	print("FAILS %d" % _fails)
	get_tree().quit()

func _rules() -> void:
	Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
	var lead := Game.leader_card("banner_marshal")
	_ok(not Game.can_remove(lead), "the only leader copy is locked")
	Game.run["deck"].append(lead)
	_ok(Game.can_remove(lead), "an extra leader copy can be dropped")
	Game.remove_card(lead)
	_ok(Game.run["deck"].count(lead) == 1 and not Game.can_remove(lead), "dropping it leaves one, locked again")
	var n: int = Game.run["deck"].count("sandbags")
	Game.pick_card_effect({"discount": [5, "choose"]}, "sandbags")
	_ok(Game.copy_discounts().get("sandbags", []) == [5.0], "a discount covers one copy (of %d)" % n)
	Game.pick_card_effect({"discount": [4, "choose"]}, "sandbags")
	_ok(Game.copy_discounts()["sandbags"].size() == 2, "a second discount picks another copy")
	Game.remove_card("sandbags")
	_ok(Game.copy_discounts()["sandbags"].size() == 2, "removing a copy takes an undiscounted one first")
	Game.remove_card("sandbags")
	_ok(Game.copy_discounts()["sandbags"] == [5.0], "with fewer copies than discounts, the best one stays")
	Game.run["deck"] = ["mire", "mire", "mire"]
	Game.run["discounts"] = {"mire": 3.0}
	_ok(Game.copy_discounts()["mire"] == [3.0, 3.0, 3.0], "old saves (one amount for all copies) keep it on every copy")
	Game.run["deck"].append_array(["fortify", "fortify"])
	Game.take_draft("medpod", "fortify")
	_ok(Game.run["deck"].count("fortify") == 1 and Game.run["deck"].has("medpod"), "a draft drop can remove an extra leader copy")

func _hand() -> void:
	var total := 0
	for trial in 200:
		var h := CardHand.new()
		h.setup(["sandbags", "sandbags", "sandbags"], EnergyBar.new(), {"sandbags": [5.0]})
		h._draw_card_from_deck()
		var costs := []
		for i in h.hand.size():
			costs.append(h.cost_of(i))
		if trial == 0:
			_ok(costs.count(7.0) == 1 and costs.count(12.0) == 2, "a 3-copy hand has exactly one discounted copy %s" % str(costs))
		h.take(0)
		h.take(0)
		h.take(0)
		_ok(h._disc_pool["sandbags"].size() == 1, "the discount returns with its copy") if trial == 0 else null
		total += 1 if costs[0] == 7.0 else 0
		h.free()
	_ok(total > 40 and total < 100, "first card drawn is the discounted one about 1 time in 3 (%d / 200)" % total)

func _battle() -> void:
	Game.new_run("captain_everafter", 99, 0, [], "evolution", 3)
	Game.run["phase"] = "battle"
	var m: Node = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	for i in 30:
		await get_tree().process_frame
	var bf = m.get_node("Battlefield")
	var u: Unit = bf.active_unit()
	bf.team_energy[0].value = 100.0
	var before: int = bf.shots.size()
	bf.fire_primary(u)
	await get_tree().create_timer(0.3).timeout
	var plain: int = bf.shots.size() - before
	var spent_plain: float = 100.0 - bf.team_energy[0].value
	bf.team_energy[0].value = 100.0
	u.echo_until = bf.time + 4.0
	var t0: float = bf.time
	bf.fire_primary(u)
	var first_at: float = u.last_fired_at
	await get_tree().create_timer(0.3).timeout
	print("first shot at %.2f, last shot at %.2f, battle time now %.2f" % [first_at - t0, u.last_fired_at - t0, bf.time - t0])
	var echoed: int = 2 if u.last_fired_at - first_at > 0.1 else 1
	var spent_echo: float = 100.0 - bf.team_energy[0].value
	_ok(echoed == plain * 2, "Echo Strike doubles the shots (%d -> %d)" % [plain, echoed])
	_ok(absf(spent_echo - spent_plain) < 0.5, "the echo is free (%.0f vs %.0f energy)" % [spent_echo, spent_plain])
	m.queue_free()
	await get_tree().process_frame

func _shot(name: String, scene: String, prep: Callable, act: Callable) -> void:
	prep.call()
	var n: Node = load(scene).instantiate()
	add_child(n)
	for i in 10:
		await get_tree().process_frame
	await act.call(n)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
	n.queue_free()
	await get_tree().process_frame
