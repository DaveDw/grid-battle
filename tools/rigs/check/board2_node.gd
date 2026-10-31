extends Node
## Screenshot of the card set 2 board effects: wire, mine, thorns, a strike warning, a
## whirlpool, pollen, Event Horizon, the flooded back column, a Holo Decoy and Annex MK II.
## godot --path . res://tools/rigs/check/board2.tscn -- <out.png>
## Uses throwaway save slot 99, deleted afterwards.
func _ready() -> void:
	Game.new_run("claim_lord", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = "tide_speaker"
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 10:
		await get_tree().process_frame
	var bf = main.get_node("Battlefield")
	for u in bf.enemy_units + bf.player_units:
		u.set_process(false)
	bf._enemy_card_t = 999.0
	var t: float = bf.time
	bf.traps[Vector2i(3, 1)] = {"kind": "wire", "team": 0, "until": t + 99.0, "next": INF}
	bf.traps[Vector2i(4, 2)] = {"kind": "mine", "team": 0, "until": t + 99.0, "next": INF}
	bf.traps[Vector2i(3, 7)] = {"kind": "thorn", "team": 0, "until": t + 99.0, "next": t + 99.0}
	bf.strikes.append({"team": 0, "tile": Vector2i(4, 5), "at": t + 99.0})
	bf.whirls.append({"team": 0, "tile": Vector2i(3, 4), "until": t + 99.0, "next": t + 99.0})
	bf.pollens.append({"team": 0, "col": 4, "row": 7, "until": t + 99.0})
	bf.horizons.append({"team": 1, "tile": Vector2i(1, 2), "until": t + 99.0})
	bf.flood_cols.append({"team": 1, "col": 5, "until": t + 99.0})
	bf.decoys[0] = {"col": 2, "row": 6, "until": t + 99.0}
	bf.barricades.append({"team": 0, "row": 6, "x": bf.panel_center(2, 6).x, "hits": 1, "until": t + 99.0, "decoy": true})
	bf.stakes[Vector2i(3, 0)] = {"team": 0, "until": INF, "annex": 2}
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()
