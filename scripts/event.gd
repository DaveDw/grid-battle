extends Control
## An event between battles (Game.EVENTS): a short scene and 2-3 choices. A choice
## that removes or discounts a card asks for the card next, from the deck. Then on
## to the battle.

var _ev: Dictionary
var _box: VBoxContainer
var _text: Label
var _fx: Dictionary = {}

func _ready() -> void:
	if Game.run.is_empty() or Game.run.get("phase") != "event":
		Game.go("res://scenes/main_menu.tscn" if Game.run.is_empty() else Game.resume_scene())
		return
	_ev = Game.EVENTS[Game.run["event"]]
	var fac: String = _ev.get("faction", "")
	var tint: Color = Game.FACTIONS[fac]["color"] if fac != "" else Color(0.55, 0.7, 1.0)
	add_child(preload("res://scripts/menu_background.gd").make("space", tint, Game.node_planet(int(Game.run["sector"]) - 1, int(Game.run["path"][-1])) if not Game.run.get("path", []).is_empty() else -1, Vector2(1080, 520), 320.0))
	var panel := PanelContainer.new()
	panel.position = Vector2(160, 110)
	panel.custom_minimum_size = Vector2(760, 0)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var head := Label.new()
	head.text = "SECTOR %d  ·  BEFORE THE NEXT BATTLE" % int(Game.run["sector"])
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", tint)
	v.add_child(head)
	var title := Label.new()
	title.text = _ev["title"]
	title.add_theme_font_override("font", Game.FONT_HEAD)
	title.add_theme_font_size_override("font_size", 36)
	v.add_child(title)
	_text = Label.new()
	_text.text = _ev["text"]
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.custom_minimum_size = Vector2(720, 0)
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	v.add_child(_text)
	var hp := Label.new()
	hp.text = _hp_line()
	hp.add_theme_font_size_override("font_size", 14)
	hp.add_theme_color_override("font_color", Color(0.65, 0.9, 0.7))
	v.add_child(hp)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	v.add_child(_box)
	for c in _ev["choices"]:
		var b := Button.new()
		b.text = c["label"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(720, 50)
		b.pressed.connect(_choose.bind(c["effects"]))
		_box.add_child(b)
	_box.get_child(0).grab_focus()

func _hp_line() -> String:
	var parts := []
	for d in Game.squad_for(Game.run["leader"], false):
		parts.append("%s %d/%d" % [d["name"], Game.starting_hp(d["role"], d["hp"]), d["hp"]])
	return "Squad:  " + "   ·   ".join(parts) + "      Deck: %d / %d" % [Game.run["deck"].size(), Game.DECK_CAP]

func _choose(fx: Dictionary) -> void:
	_fx = fx
	Game.apply_effects(fx)
	if fx.get("remove", "") == "choose" or fx.has("discount"):
		_pick_card()
	else:
		_done()

## Show the deck as buttons for the card-picking effect.
func _pick_card() -> void:
	for c in _box.get_children():
		c.queue_free()
	_text.text = "Choose a card to remove." if _fx.has("remove") else "Choose a card to make %d cheaper (every copy)." % int(_fx["discount"][0])
	var lead := Game.leader_card(Game.run["leader"])
	var seen := {}
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(720, 0)
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	_box.add_child(flow)
	var first: Button = null
	for id in Game.run["deck"]:
		if seen.has(id):
			continue
		seen[id] = true
		var b := Button.new()
		b.text = "%s  (%d)" % [Game.CARDS[id]["name"], int(Game.card_cost(id))]
		b.tooltip_text = Game.CARDS[id]["text"]
		b.custom_minimum_size = Vector2(230, 44)
		b.add_theme_font_override("font", Game.FONT_CARD)
		b.add_theme_font_size_override("font_size", 8)
		Game.card_button_icon(b, id)
		b.disabled = _fx.has("remove") and id == lead
		b.pressed.connect(func():
			Game.pick_card_effect(_fx, id)
			_done())
		flow.add_child(b)
		if first == null and not b.disabled:
			first = b
	if first:
		first.grab_focus.call_deferred()

func _done() -> void:
	Game.finish_event()
	Game.go(Game.resume_scene())
