extends Control
func _ready():
	var d := DeckSculpt.new()
	d.leader_id = "banner_marshal"
	d.deck = Game.starter_deck("banner_marshal")
	add_child(d)
