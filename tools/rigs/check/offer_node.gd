extends Node
func _ready():
	Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
	var bad := 0
	var counts := {2: 0, 3: 0}
	for i in 200:
		var three := i % 2 == 1
		Game.run["draft_bonus"] = 1 if three else 0
		Game.run["enemy"] = ["chief_visionary", "tide_speaker", "mission_mother", "claim_lord"][i % 4]
		Game.win_battle()
		var o: Array = Game.run["offer"]
		var mine: String = Game.leader_by_id(Game.run["leader"])["faction"]
		var theirs: String = Game.leader_by_id(Game.run["enemy"])["faction"]
		counts[o.size()] = counts.get(o.size(), 0) + 1
		var unique := {}
		for c in o: unique[c] = true
		if Game.card_faction(o[0]) != mine or Game.card_faction(o[1]) != theirs or unique.size() != o.size():
			bad += 1
			print("BAD ", o, " mine ", mine, " theirs ", theirs)
		if i < 4:
			print("sample vs ", theirs, ": ", o, " -> ", o.map(func(c): return Game.card_faction(c)))
	print("offer sizes ", counts, "  bad ", bad)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()
