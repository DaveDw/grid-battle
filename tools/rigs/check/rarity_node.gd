extends Node
## Rarity: checks starters are Common and leader cards Rare, rolls many draft offers to
## show how often each rarity comes up, and screenshots the draft, the deck view and a
## battle hand. godot --path . res://tools/rigs/check/rarity.tscn -- <out_dir>
## Uses throwaway save slot 99, deleted afterwards.
func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var fails := 0
	for f in Game.STARTERS:
		for c in Game.STARTERS[f]:
			if Game.card_rarity(c) != 0:
				print("FAIL starter %s is not Common" % c)
				fails += 1
	for l in Game.LEADERS:
		if Game.card_rarity(Game.leader_card(l["id"])) != 2:
			print("FAIL leader card %s is not Rare" % Game.leader_card(l["id"]))
			fails += 1
	# odds: Long Tomorrow vs a beaten Terran, 3000 offers
	Game.new_run("captain_everafter", 99, 0, [], "conquest", 1)
	var by_rarity := [0, 0, 0, 0]
	var per_card := {}
	var n := 3000
	for i in n:
		Game.run["enemy"] = "banner_marshal"
		Game.run["phase"] = "battle"
		Game.win_battle()
		for c in Game.run["offer"]:
			by_rarity[Game.card_rarity(c)] += 1
			per_card[c] = per_card.get(c, 0) + 1
	print("offers by rarity over %d drafts: Common %d · Uncommon %d · Rare %d · Legendary %d" % [n, by_rarity[0], by_rarity[1], by_rarity[2], by_rarity[3]])
	print("e.g. Borrowed Time (Common) %d · Collapse (Uncommon) %d · Echo Strike (Rare) %d · Supernova (Legendary) %d" % [per_card.get("borrowed_time", 0), per_card.get("collapse", 0), per_card.get("echo_strike", 0), per_card.get("supernova", 0)])
	if not (per_card.get("supernova", 0) < per_card.get("echo_strike", 0) and per_card.get("echo_strike", 0) < per_card.get("borrowed_time", 0)):
		print("FAIL rarer cards should come up less often")
		fails += 1
	# screenshots
	Game.run["enemy"] = "banner_marshal"
	Game.run["phase"] = "draft"
	Game.run["offer"] = ["supernova", "barrage", "medpod"]
	Game.run["deck"] = ["borrowed_time", "rewind", "rewind", "echo_strike", "regrowth", "medpod", "void_orb", "collapse", "supply_drop"]
	await _shot("res://scenes/draft.tscn", out + "/rarity_draft.png")
	var dv := DeckView.new()
	dv.groups = [["Deck", Game.run["deck"]]]
	add_child(dv)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/rarity_deck.png")
	dv.queue_free()
	Game.run["phase"] = "battle"
	Game.run["mode"] = "evolution"
	Game.run["squad"] = 3
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 20:
		await get_tree().process_frame
	var bf = main.get_node("Battlefield")
	bf.hand.hand = ["rewind", "echo_strike", "supernova"]
	bf.hand.hand_disc = [0.0, 0.0, 0.0]
	bf.hands[1].hand = ["void_orb"]
	bf.hands[1].hand_disc = [0.0]
	bf.team_energy[1].value = 100.0
	bf._enemy_card_t = 999.0
	bf.play_card(1, 0)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/rarity_hand.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	print("FAILS %d" % fails)
	get_tree().quit()

func _shot(scene: String, path: String) -> void:
	var n: Node = load(scene).instantiate()
	add_child(n)
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	n.queue_free()
	await get_tree().process_frame
