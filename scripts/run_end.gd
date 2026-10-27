extends Control
## End of a won run. Two modes:
## - the choice right after claiming the last sector: Complete Run (take the reward)
##   or Infinity and Beyond (keep going; the reward is locked in from this deck);
## - the summary after a run is completed (or an endless run finally falls), showing
##   the card that joined the collection.

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(1.0, 0.8, 0.35)))
	if not Game.run.is_empty() and Game.run.get("phase") == "won":
		_build_choice()
	elif not Game.last_result.is_empty():
		_build_summary()
	else:
		Game.go("res://scenes/main_menu.tscn")

func _label(pos: Vector2, size: int, col: Color, text: String) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(1280, size + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.text = text
	add_child(l)
	return l

func _build_choice() -> void:
	_label(Vector2(0, 70), 54, Color(1.0, 0.85, 0.4), "RUN WON")
	_label(Vector2(0, 150), 18, Color(0.7, 0.8, 0.95), "You claimed %d sectors with %s." % [Game.sectors_claimed(),
		Game.UNITS[Game.leader_by_id(Game.run["leader"])["leader"]]["name"]])
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	row.position = Vector2(0, 240)
	row.custom_minimum_size = Vector2(1280, 0)
	add_child(row)
	var done := _big_button("Complete Run",
		"End the run here. One random card from your deck that wasn't in your starter deck joins your collection.")
	done.pressed.connect(func():
		Game.complete_run()
		Game.go("res://scenes/run_end.tscn"))
	row.add_child(done)
	var more := _big_button("Infinity and Beyond",
		"Keep claiming sectors, getting harder, for no extra reward. Your reward is locked in from this deck. When the run finally ends, it counts as a win.")
	more.pressed.connect(func():
		Game.go_infinite()
		Game.go("res://scenes/sector_map.tscn"))
	row.add_child(more)
	var view := Button.new()
	view.text = "View Deck"
	view.position = Vector2(550, 600)
	view.custom_minimum_size = Vector2(180, 44)
	view.pressed.connect(func():
		var d := DeckView.new()
		d.title = "YOUR WINNING DECK"
		d.groups = [["Deck", Game.run["deck"]]]
		add_child(d)
		d.closed.connect(done.grab_focus))
	add_child(view)
	done.grab_focus()

func _big_button(title: String, text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(380, 240)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 22
	v.offset_right = -22
	v.offset_top = 22
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var d := Label.new()
	d.text = text
	d.autowrap_mode = TextServer.AUTOWRAP_WORD
	d.add_theme_font_size_override("font_size", 16)
	d.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	v.add_child(d)
	return b

func _build_summary() -> void:
	var r := Game.last_result
	_label(Vector2(0, 60), 50, Color(1.0, 0.85, 0.4), "THE END OF INFINITY" if r["infinite"] else "RUN COMPLETE")
	_label(Vector2(0, 135), 18, Color(0.7, 0.8, 0.95), "%s  ·  %d sectors claimed  ·  %d battles won" % [
		Game.UNITS[Game.leader_by_id(r["leader"])["leader"]]["name"], r["sectors"], r["wins"]])
	if r["reward"] != "":
		_label(Vector2(0, 200), 16, Color(0.6, 0.75, 0.95), "JOINS YOUR COLLECTION")
		var c: Dictionary = Game.CARDS[r["reward"]]
		var box := PanelContainer.new()
		box.position = Vector2(470, 235)
		box.custom_minimum_size = Vector2(340, 150)
		add_child(box)
		var v := VBoxContainer.new()
		box.add_child(v)
		var top := HBoxContainer.new()
		v.add_child(top)
		var n := Label.new()
		n.text = c["name"]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.add_theme_font_size_override("font_size", 24)
		top.add_child(n)
		var cost := Label.new()
		cost.text = "%d" % int(c["cost"])
		cost.add_theme_font_size_override("font_size", 24)
		cost.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
		top.add_child(cost)
		var t := Label.new()
		t.text = c["text"]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD
		t.add_theme_font_size_override("font_size", 16)
		t.add_theme_color_override("font_color", Color(0.78, 0.83, 0.92))
		v.add_child(t)
	else:
		_label(Vector2(0, 260), 18, Color(0.7, 0.75, 0.85), "Your deck had no cards beyond your starter deck, so there was nothing new to claim.")
	_label(Vector2(0, 470), 15, Color(0.65, 0.72, 0.85), Game.stats_text(r.get("stats", {})))
	_label(Vector2(0, 420), 16, Color(0.7, 0.85, 0.75), "Collection: %d card(s)  ·  runs won: %d  ·  best: %d sectors  ·  New Game+ %d unlocked" % [
		Game.profile["collection"].size(), int(Game.profile["runs_won"]), int(Game.profile["best_sectors"]), int(Game.profile["ng_unlocked"])])
	var back := Button.new()
	back.text = "Return to Title"
	back.position = Vector2(530, 560)
	back.custom_minimum_size = Vector2(220, 48)
	back.pressed.connect(func():
		Game.last_result = {}
		Game.go("res://scenes/main_menu.tscn"))
	add_child(back)
	back.grab_focus()
