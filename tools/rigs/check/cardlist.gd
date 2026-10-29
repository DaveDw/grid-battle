extends SceneTree
func _init():
	var g = load("res://scripts/game.gd")
	var cards: Dictionary = g.CARDS
	var node = g.new()
	var lines := []
	for id in cards:
		var c: Dictionary = cards[id]
		var f: String = node.card_faction(id)
		lines.append("- `%s` | %s | %s | %d energy | %s" % [id, c["name"], f if f != "" else "neutral", int(c["cost"]), c["text"]])
	print("\n".join(lines))
	node.free()
	quit()
