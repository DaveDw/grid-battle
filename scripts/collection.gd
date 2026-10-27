extends Control
## The collection: every card earned from won runs (with copies owned), plus profile
## stats. Collected cards can be swapped into a starting deck on New Game+ runs.

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(1.0, 0.75, 0.3), 12, Vector2(140, 620), 260.0))
	var p := Game.profile
	var d := DeckView.new()
	d.title = "COLLECTION"
	var empty_note := "Win a run to claim your first card. Collected cards can be swapped into your starting deck on New Game+ runs."
	d.groups = [["Runs won: %d  ·  best run: %d sectors  ·  New Game+ unlocked: %d  ·  cards" % [int(p["runs_won"]), int(p["best_sectors"]), int(p["ng_unlocked"])],
		p["collection"]]]
	if p["collection"].is_empty():
		d.note = empty_note
	add_child(d)
	d.closed.connect(func(): Game.go("res://scenes/main_menu.tscn"))
