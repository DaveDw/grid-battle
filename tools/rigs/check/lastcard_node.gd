extends Node
## Screenshot of the last-card panels: each side plays a card, then the battle is captured.
## godot --path . res://tools/rigs/check/lastcard.tscn -- <out.png>
## Uses throwaway save slot 99, deleted afterwards.
func _ready() -> void:
	Game.new_run("claim_lord", 99, 0, [], "evolution", 3)
	Game.run["enemy"] = "tide_speaker"
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 30:
		await get_tree().process_frame
	var bf = main.get_node("Battlefield")
	bf._enemy_card_t = 999.0
	for team in 2:
		var h: CardHand = bf.hands[team]
		h.hand = ["hold_the_line"] if team == 0 else ["undertow_surge"]
		h.hand_disc = [0.0]
		bf.team_energy[team].value = 100.0
		bf._ai_plans.clear()
		bf.play_card(team, 0)
	for i in 40:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()
