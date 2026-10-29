extends Control
## Post-battle draft: pick 1 of the offered cards (must take one). If the deck is at
## the cap, the next step is choosing a card to drop (the leader card is locked).
## The offer lives in the run save, so quitting here can't reroll it.

var _choices: HBoxContainer
var _title: Label
var _sub: Label
var _deck_label: Label
var _picked := ""

func _ready() -> void:
	if Game.run.is_empty() or not Game.run.has("offer"):
		Game.go("res://scenes/main_menu.tscn")
		return
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(1.0, 0.8, 0.35)))
	_title = _label(Vector2(0, 60), 44, Color.WHITE)
	_sub = _label(Vector2(0, 120), 17, Color(0.6, 0.75, 0.95))
	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", 30)
	_choices.position = Vector2(0, 180)
	_choices.custom_minimum_size = Vector2(1280, 0)
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_choices)
	_deck_label = _label(Vector2(0, 545), 15, Color(0.6, 0.68, 0.8))
	_label(Vector2(0, 575), 14, Color(0.75, 0.85, 0.7)).text = _hp_text()
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.position = Vector2(0, 620)
	bar.custom_minimum_size = Vector2(1280, 0)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bar)
	var view := Button.new()
	view.text = "View Deck"
	view.custom_minimum_size = Vector2(180, 44)
	view.pressed.connect(func():
		var d := DeckView.new()
		d.title = "YOUR DECK"
		d.groups = [["Deck", Game.run["deck"]]]
		add_child(d)
		d.closed.connect(_focus_first))
	bar.add_child(view)
	var quit := Button.new()
	quit.text = "Save & Quit"
	quit.custom_minimum_size = Vector2(180, 44)
	quit.pressed.connect(func():
		Game.save_run()
		Game.run = {}
		Game.go("res://scenes/main_menu.tscn"))
	bar.add_child(quit)
	_show_offer()

func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(1280, size + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if size >= 24:
		l.add_theme_font_override("font", Game.FONT_HEAD)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

## What the squad's HP will be next battle (it carries over within a sector).
func _hp_text() -> String:
	if int(Game.run["stage"]) + 1 >= Game.STAGES_PER_SECTOR:
		return "Sector cleared: your squad will be fully healed."
	var parts := []
	for d in Game.squad_for(Game.run["leader"], false):
		var h := Game.starting_hp(d["role"], d["hp"])
		var fell := int(Game.run.get("hp", {}).get(d["role"], 1)) <= 0
		parts.append("%s %d/%d%s" % [d["name"], h, d["hp"], " (fell)" if fell else ""])
	return "HP carries into the next battle:  " + "   ·   ".join(parts)

func _stage_text() -> String:
	return "Sector %d  ·  stage %d of %d cleared" % [int(Game.run["sector"]), int(Game.run["stage"]) + 1, Game.STAGES_PER_SECTOR]

func _show_offer() -> void:
	_picked = ""
	_title.text = "VICTORY"
	_sub.text = _stage_text() + "  ·  choose a card for your deck"
	for c in _choices.get_children():
		c.queue_free()
	for id in Game.run["offer"]:
		_choices.add_child(_card_button(id, _on_pick.bind(id)))
	_update_deck_label()
	_focus_first.call_deferred()

func _update_deck_label() -> void:
	var n: int = Game.run["deck"].size()
	_deck_label.text = "Deck  %d / %d" % [n, Game.DECK_CAP] + ("  ·  full: taking a card means dropping one" if n >= Game.DECK_CAP else "")

func _focus_first() -> void:
	for c in _choices.get_children():
		if c is Button and not c.disabled and not c.is_queued_for_deletion():
			c.grab_focus()
			return

## A big card button: name, cost, what it targets, text and the faction it comes from.
func _card_button(id: String, cb: Callable, count := 0, locked := false) -> Button:
	var c: Dictionary = Game.CARDS[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 260) if count == 0 else Vector2(230, 120)
	b.pressed.connect(cb)
	b.disabled = locked
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_top = 14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var name_l := Label.new()
	name_l.text = ("%d× " % count if count > 1 else "") + c["name"]
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.add_theme_font_override("font", Game.FONT_CARD)
	name_l.add_theme_font_size_override("font_size", 16 if count == 0 else 8)
	if count > 0:   # small cards (drop-a-card grid): icon beside the name; big cards get it below
		top.add_child(Game.card_icon(id, 32))
	top.add_child(name_l)
	var cost := Label.new()
	cost.text = "%d" % int(Game.card_cost(id))
	cost.add_theme_font_override("font", Game.FONT_CARD)
	cost.add_theme_font_size_override("font_size", 16 if count == 0 else 8)
	cost.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
	top.add_child(cost)
	var fac := Game.card_faction(id)
	var tag := Label.new()
	var fac_name: String = Game.FACTIONS[fac]["name"] if fac != "" else ""
	# short faction name ("Terran", "Long Tomorrow") so the tag fits the card
	fac_name = fac_name.trim_prefix("The ") if fac_name.begins_with("The ") else fac_name.split(" ")[0]
	if count > 0:
		tag.text = "LOCKED · leader card" if locked else fac_name
	else:
		tag.text = "%s  ·  %s" % [fac_name, {"unit": "selected unit", "tile": "aimed at a tile", "none": "no target"}[c["target"]]]
	tag.clip_text = true
	tag.add_theme_font_override("font", Game.FONT_CARD)
	tag.add_theme_font_size_override("font_size", 8)
	tag.add_theme_color_override("font_color", Game.FACTIONS[fac]["color"] if fac != "" else Color(0.7, 0.7, 0.8))
	v.add_child(tag)
	var t := Label.new()
	t.text = c["text"].replace("/", "/" + char(0x2060))   # word joiner: never break "HP/s" after the slash
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	t.add_theme_font_override("font", Game.FONT_CARD)
	t.add_theme_font_size_override("font_size", 10 if count == 0 else 8)
	t.add_theme_constant_override("line_spacing", 4)
	t.add_theme_color_override("font_color", Color(0.78, 0.83, 0.92))
	v.add_child(t)
	if count == 0 and fac != "":
		_card_art(b, id, Game.FACTIONS[fac]["color"])
	return b

## Lower half of a big card: the unit the card belongs to (or a faction unit), faded
## over a glow in the faction colour, with a tag for what the card does.
func _card_art(b: Button, id: String, col: Color) -> void:
	b.clip_contents = true
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_top = 130
	art.offset_left = 8
	art.offset_right = -8
	art.offset_bottom = -8
	art.show_behind_parent = false
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.4))
	g.set_color(1, Color(col, 0.0))
	var glow := GradientTexture2D.new()
	glow.gradient = g
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	art.draw.connect(func():
		var c := Rect2(Vector2.ZERO, art.size).get_center() + Vector2(0, 20)
		art.draw_texture_rect(glow, Rect2(c - Vector2(110, 90), Vector2(220, 180)), false))
	b.add_child(art)
	b.move_child(art, 0)   # behind the text
	var pic := TextureRect.new()
	var card_pic := Game.card_art(id)
	pic.texture = card_pic if card_pic else Game.sprite_texture(Game.card_art_unit(id))
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# the card's own icon shows at its native 128 px (4x) so the pixels stay square;
	# cards without one yet fall back to a faded unit sprite
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if card_pic else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.modulate = Color.WHITE if card_pic else Color(1, 1, 1, 0.55)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(pic)
	var kind := Label.new()
	kind.text = String(Sfx.CARD_KIND.get(id, "power")).to_upper()
	kind.add_theme_font_size_override("font_size", 11)
	kind.add_theme_color_override("font_color", col.lightened(0.3))
	kind.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	kind.add_theme_constant_override("outline_size", 4)
	kind.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	kind.position = art.size - Vector2(60, 20)
	kind.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	kind.grow_vertical = Control.GROW_DIRECTION_BEGIN
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(kind)

func _on_pick(id: String) -> void:
	if not Game.deck_full():
		_finish(id, "")
		return
	# deck at the cap: pick a card to drop
	_picked = id
	_title.text = "DECK FULL"
	_sub.text = "Adding %s. Choose a card to drop (your leader card stays)." % Game.CARDS[id]["name"]
	for c in _choices.get_children():
		c.queue_free()
	var counts := {}
	for d in Game.run["deck"]:
		counts[d] = counts.get(d, 0) + 1
	var lead := Game.leader_card(Game.run["leader"])
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_choices.add_child(grid)
	for d in counts:
		grid.add_child(_card_button(d, _finish.bind(id, d), counts[d], d == lead))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 44)
	back.pressed.connect(_show_offer)
	_choices.add_child(back)
	(func():
		for b in grid.get_children():
			if not b.disabled:
				b.grab_focus()
				return).call_deferred()

func _finish(id: String, drop: String) -> void:
	var cleared := Game.take_draft(id, drop)
	for c in _choices.get_children():
		c.queue_free()
	_title.text = "SECTOR CLEARED" if cleared else "ADDED: %s" % Game.CARDS[id]["name"].to_upper()
	if Game.run.get("phase") == "won":
		_sub.text = "Every sector claimed. The run is yours."
	elif cleared:
		_sub.text = "%d sectors claimed. Choose the next one on the map." % Game.sectors_claimed()
	else:
		_sub.text = "Next: %s" % Game.FACTIONS[Game.leader_by_id(Game.run["enemy"])["faction"]]["name"]
	_update_deck_label()
	var tw := create_tween()
	tw.tween_interval(1.4 if cleared else 0.8)
	tw.tween_callback(func(): Game.go(Game.resume_scene()))

func _unhandled_input(event: InputEvent) -> void:
	if _picked != "" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_offer()
