extends Control
func _ready():
	var d := DeckView.new()
	d.title = "DECK"
	d.groups = [["Hand", ["void_orb", "riptide", "firewall"]], ["Draw pile", ["sandbags", "supernova", "spore_bloom", "data_breach", "burn_bright"]]]
	add_child(d)
