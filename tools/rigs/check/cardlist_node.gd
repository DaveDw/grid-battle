extends Node
func _ready():
	for id in Game.CARDS:
		var c: Dictionary = Game.CARDS[id]
		var f: String = Game.card_faction(id)
		print("- `%s` | %s | %s | %d energy | %s" % [id, c["name"], f if f != "" else "neutral", int(c["cost"]), c["text"]])
	get_tree().quit()
