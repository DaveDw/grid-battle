extends Node
## Screenshot: the player fires down a lane while an enemy stands in the lane above,
## captured as the bullet passes that enemy (depth and lane marks).
## godot --path . res://tools/rigs/check/lane.tscn -- <out.png>
## Uses throwaway save slot 99, deleted afterwards.
func _ready() -> void:
	Game.new_run("claim_lord", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = "tide_speaker"
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 20:
		await get_tree().process_frame
	var bf = main.get_node("Battlefield")
	bf.ai["attack_min"] = 99.0
	bf.ai["attack_max"] = 99.0
	bf.ai["move_min"] = 99.0
	bf.ai["move_max"] = 99.0
	bf.ai["dodge"] = 0.0
	for u in bf.enemy_units + bf.player_units:
		u._ai_attack = 99.0
		u._ai_move = 99.0
	var place := func(u: Unit, c: int, r: int):
		u.col = c
		u.row = r
		u.position = bf.panel_center(c, r)
	place.call(bf.player_units[0], 1, 4)
	place.call(bf.player_units[1], 0, 0)
	place.call(bf.player_units[2], 0, 8)
	place.call(bf.enemy_units[0], 4, 3)    # one lane above the shot
	place.call(bf.enemy_units[1], 5, 4)    # the target, at the end of the lane
	place.call(bf.enemy_units[2], 5, 8)
	bf.team_energy[0].value = 100.0
	bf.fire_primary(bf.player_units[0])
	# wait until the bullet is passing the enemy above
	var target_x: float = bf.panel_center(4, 3).x
	for i in 200:
		await get_tree().process_frame
		var b: Array = bf.shots.filter(func(s): return s["team"] == 0)
		if b.is_empty() or b[0]["x"] >= target_x - 10.0:
			break
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()
