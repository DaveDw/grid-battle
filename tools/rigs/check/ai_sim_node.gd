extends Node
## Enemy AI bench: simulated battles against player units that wander and never shoot
## (with HP too high to die). Per faction and level, compares the AI as it was ("old":
## no smart moves, no aim) with the current one. Reports damage dealt, damage per energy
## spent (accuracy) and HP enemies lost to their own hazards.
## godot --path . res://tools/rigs/check/ai_sim.tscn -- [seconds per battle]
## Uses throwaway save slot 99, deleted afterwards.
const ENEMIES := {"terran": "claim_lord", "ascendancy": "director_zero", "manyworlds": "tide_speaker", "long": "mission_mother"}
const LEVELS := [0, 2, 5]

func _ready() -> void:
	var secs := 40.0
	if OS.get_cmdline_user_args().size() > 0:
		secs = float(OS.get_cmdline_user_args()[0])
	Engine.time_scale = 6.0
	print("faction     lvl  AI    dmg   dmg/energy")
	for fac in ENEMIES:
		for lvl in LEVELS:
			for mode in ["old", "new"]:
				var r: Dictionary = await _battle(ENEMIES[fac], fac, lvl, mode, secs)
				print("%-11s %3d  %-4s %5d   %.2f" % [fac, lvl, mode, r["dmg"], r["eff"]])
	Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()

func _battle(enemy: String, fac: String, lvl: int, mode: String, secs: float) -> Dictionary:
	seed(1234 + lvl)
	Game.new_run("banner_marshal", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = enemy
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var bf = main.get_node("Battlefield")
	bf.ai = Game.ai_params(lvl, fac, false)
	if mode == "old":
		bf.ai["smart"] = 0.0
		bf.ai["aim"] = 0.0
	for u in bf.player_units:
		u.max_hp = 100000
		u.hp = 100000
	var start_hp := 0
	for u in bf.player_units:
		start_hp += u.hp
	var spent := 0.0
	var prev: float = bf.team_energy[1].value
	var t := 0.0
	var wander := 0.0
	while t < secs:
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		var v: float = bf.team_energy[1].value
		spent += maxf(prev - v, 0.0)
		prev = v
		wander -= dt
		if wander <= 0.0:
			wander = 1.2
			for u in bf.player_units:
				var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
				var d: Vector2i = dirs[randi() % 4]
				if bf.can_move(u, u.col + d.x, u.row + d.y):
					bf.try_move(u, d)
				bf.team_stamina[0].value = float(bf.team_stamina[0].SEGMENTS)
	var hp := 0
	for u in bf.player_units:
		hp += u.hp
	var dmg := start_hp - hp
	main.queue_free()
	await get_tree().process_frame
	return {"dmg": dmg, "eff": dmg / maxf(spent, 1.0)}
