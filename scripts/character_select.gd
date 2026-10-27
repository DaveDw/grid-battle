extends Control
## Leader select. Only leaders are picked; each brings its bundled heavy and light,
## shown in the detail panel. Cards are grouped by faction. Begin Run creates the run in
## the chosen save slot and starts the first battle.

var _selected := 0              # the leader chosen (stays highlighted)...
var _shown := 0                 # ...and the one in the detail panel (follows the cursor)
var _cards: Array[Button] = []
var _detail: Dictionary = {}    # widgets in the detail panel
var _slot_pick: OptionButton
var _begin: Button
var _big: FighterSprite
var _deck: Array = []           # starting deck for the selected leader (sculpted on NG+)
var _deck_leader := ""
var _ng_pick: OptionButton
var _squad_sprites: Array = []
var _bg: Control                # backdrop, tinted to the browsed leader's faction

func _ready() -> void:
	_bg = preload("res://scripts/menu_background.gd").make("grid", Color(0.3, 0.5, 0.9))
	add_child(_bg)
	var title := Label.new()
	title.text = "CHOOSE YOUR LEADER"
	title.add_theme_font_size_override("font_size", 38)
	title.position = Vector2(40, 22)
	add_child(title)
	var sub := Label.new()
	sub.text = "Each leader brings a heavy and a light. Your squad fights as three."
	sub.add_theme_color_override("font_color", Color(0.55, 0.7, 0.9))
	sub.add_theme_font_size_override("font_size", 15)
	sub.position = Vector2(42, 72)
	add_child(sub)
	_build_grid()
	_build_detail()
	_build_footer()
	_choose(0, false)
	_cards[0].grab_focus()

# --- leader cards ------------------------------------------------------------

func _build_grid() -> void:
	var fi := 0
	for fid in Game.FACTIONS:
		var f: Dictionary = Game.FACTIONS[fid]
		var x := 40.0 + fi * 152.0
		var head := Label.new()
		head.text = _short_faction(fid)
		head.add_theme_color_override("font_color", f["color"])
		head.add_theme_font_size_override("font_size", 14)
		head.position = Vector2(x, 106)
		add_child(head)
		var row := 0
		for i in Game.LEADERS.size():
			var l: Dictionary = Game.LEADERS[i]
			if l["faction"] != fid:
				continue
			var card := Button.new()
			card.position = Vector2(x, 132 + row * 252)
			card.size = Vector2(142, 240)
			card.set_meta("leader", i)
			# browsing previews a leader; pressing chooses it, and the choice stays lit
			card.focus_entered.connect(_preview.bind(i))
			card.focus_exited.connect(_on_card_focus_exited)
			card.mouse_entered.connect(card.grab_focus)
			card.pressed.connect(_choose.bind(i))
			var pic := TextureRect.new()
			pic.texture = Game.sprite_texture(l["leader"])
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.position = Vector2(8, 10)
			pic.size = Vector2(126, 180)
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(pic)
			var name_l := Label.new()
			name_l.text = Game.UNITS[l["leader"]]["name"]
			name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
			name_l.position = Vector2(4, 192)
			name_l.size = Vector2(134, 44)
			name_l.add_theme_font_size_override("font_size", 15)
			name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(name_l)
			add_child(card)
			_cards.append(card)
			row += 1
		fi += 1

func _short_faction(fid: String) -> String:
	return {"terran": "TERRAN", "ascendancy": "ASCENDANCY", "manyworlds": "MANYWORLDS", "long": "LONG TOMORROW"}[fid]

# --- detail panel ------------------------------------------------------------

func _build_detail() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(670, 96)
	panel.custom_minimum_size = Vector2(580, 540)
	add_child(panel)
	var root := Control.new()
	root.custom_minimum_size = Vector2(540, 500)
	panel.add_child(root)
	_big = FighterSprite.new()
	_big.height = 270.0
	_big.max_width = 210.0
	_big.feet_y = 0.0
	_big.position = Vector2(105, 295)
	root.add_child(_big)
	_detail["name"] = _label(root, Vector2(220, 0), 28, Color.WHITE)
	_detail["title"] = _label(root, Vector2(220, 38), 16, Color(0.7, 0.8, 0.95))
	_detail["faction"] = _label(root, Vector2(220, 62), 13, Color.WHITE)
	_detail["style"] = _label(root, Vector2(220, 84), 13, Color(0.85, 0.88, 0.95))
	_detail["difficulty"] = _label(root, Vector2(220, 104), 13, Color(0.6, 0.7, 0.85))
	var blurb := _label(root, Vector2(220, 128), 14, Color(0.72, 0.77, 0.88))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD
	blurb.size = Vector2(320, 90)
	_detail["blurb"] = blurb
	_detail["deck_head"] = _label(root, Vector2(220, 222), 13, Color(0.45, 0.75, 1.0))
	_detail["deck"] = _label(root, Vector2(220, 242), 14, Color(0.8, 0.85, 0.95))
	_detail["deck"].autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail["deck"].size = Vector2(330, 72)
	_label(root, Vector2(0, 318), 14, Color(0.45, 0.75, 1.0)).text = "SQUAD"
	for k in 3:
		var slot := Control.new()
		slot.position = Vector2(k * 182, 340)
		root.add_child(slot)
		var bg := Panel.new()
		bg.size = Vector2(172, 150)
		slot.add_child(bg)
		var s := FighterSprite.new()
		s.height = 96.0
		s.max_width = 150.0
		s.feet_y = 0.0
		s.position = Vector2(86, 108)
		slot.add_child(s)
		var n := _label(slot, Vector2(6, 112), 14, Color.WHITE)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.size = Vector2(160, 20)
		var r := _label(slot, Vector2(6, 130), 12, Color(0.6, 0.7, 0.85))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.size = Vector2(160, 18)
		_squad_sprites.append({"sprite": s, "name": n, "role": r})

func _label(parent: Node, pos: Vector2, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

## Lock in leader `i`: it keeps its faction-coloured frame wherever the cursor goes,
## and Begin Run / Deck use it. `to_begin` moves focus on to Begin Run.
func _choose(i: int, to_begin := true) -> void:
	if _deck_leader != Game.LEADERS[i]["id"]:
		_deck_leader = Game.LEADERS[i]["id"]
		_deck = Game.starter_deck(_deck_leader)
	_selected = i
	_restyle()
	_preview(i)
	if to_begin:
		_begin.grab_focus()

func _restyle() -> void:
	for c in _cards:
		var k: int = c.get_meta("leader")
		var fc: Color = Game.FACTIONS[Game.LEADERS[k]["faction"]]["color"]
		var chosen := k == _selected
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.2, 0.3, 0.98) if chosen else Color(0.1, 0.13, 0.2, 0.92)
		sb.border_color = fc if chosen else Color(0.25, 0.32, 0.45)
		sb.set_border_width_all(4 if chosen else 1)
		sb.set_corner_radius_all(6)
		# the cursor: a light frame (on the chosen card, a brighter faction frame)
		var fb: StyleBoxFlat = sb.duplicate()
		fb.border_color = fc.lightened(0.35) if chosen else Color(0.85, 0.92, 1.0)
		fb.set_border_width_all(4 if chosen else 2)
		fb.bg_color = sb.bg_color.lightened(0.06)
		for st in ["normal", "pressed", "disabled"]:
			c.add_theme_stylebox_override(st, sb)
		for st in ["hover", "focus", "hover_pressed"]:
			c.add_theme_stylebox_override(st, fb)
		c.text = ""
		var tag: Label = c.get_node_or_null("Chosen")
		if tag == null:
			tag = Label.new()
			tag.name = "Chosen"
			tag.text = "✓ CHOSEN"
			tag.position = Vector2(6, 4)
			tag.add_theme_font_size_override("font_size", 12)
			tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			tag.add_theme_constant_override("outline_size", 4)
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(tag)
		tag.add_theme_color_override("font_color", fc.lightened(0.3))
		tag.visible = chosen

## Leaving the leader grid (to the footer, a dialog...) puts the chosen leader back
## in the detail panel.
func _on_card_focus_exited() -> void:
	(func():
		if not is_inside_tree():
			return   # leaving the screen
		var f := get_viewport().gui_get_focus_owner()
		if not (f in _cards) and _shown != _selected:
			_preview(_selected)).call_deferred()

## Show leader `i` in the detail panel (the chosen one's deck may be sculpted).
func _preview(i: int) -> void:
	_shown = i
	var l: Dictionary = Game.LEADERS[i]
	var f: Dictionary = Game.FACTIONS[l["faction"]]
	_bg.set_tint(f["color"])
	_detail["name"].text = Game.UNITS[l["leader"]]["name"]
	_detail["title"].text = "\"%s\"" % l["title"]
	_detail["faction"].text = f["name"].to_upper()
	_detail["faction"].add_theme_color_override("font_color", f["color"])
	_detail["blurb"].text = l["blurb"]
	_detail["style"].text = l["style"]
	var diff: int = l["difficulty"]
	_detail["difficulty"].text = "DIFFICULTY  %s%s  %s" % ["●".repeat(diff), "○".repeat(3 - diff), ["", "Straightforward", "Moderate", "Advanced"][diff]]
	_show_deck()
	_set_sprite(_big, l["leader"])
	var k := 0
	for role in ["leader", "heavy", "light"]:
		var e: Dictionary = _squad_sprites[k]
		_set_sprite(e["sprite"], l[role])
		e["name"].text = Game.UNITS[l[role]]["name"]
		e["role"].text = "%s  ·  %d HP" % [role.to_upper(), Game.ROLES[role]["hp"]]
		k += 1

## The starting deck for the selected leader (sculpted on NG+), counted per card.
func _show_deck() -> void:
	var id: String = Game.LEADERS[_shown]["id"]
	var deck: Array = _deck if id == _deck_leader else Game.starter_deck(id)
	var counts := {}
	for c in deck:
		counts[c] = counts.get(c, 0) + 1
	var lc := Game.leader_card(id)
	var lines := []
	for c in counts:
		lines.append("%d× %s%s" % [counts[c], Game.CARDS[c]["name"], " ★" if c == lc else ""])
	_detail["deck"].text = "   ·   ".join(lines)
	_detail["deck_head"].text = "STARTING DECK" + ("  ·  SCULPTED" if deck != Game.starter_deck(id) else "")

func _ng() -> int:
	return _ng_pick.get_selected_id() if _ng_pick and _ng_pick.visible else 0

func _set_sprite(s: FighterSprite, key: String) -> void:
	s.set_art("res://assets/sprites/%s.png" % key)

# --- footer ------------------------------------------------------------------

func _build_footer() -> void:
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(40, 650)
	back.custom_minimum_size = Vector2(140, 44)
	back.pressed.connect(_back)
	add_child(back)
	var rnd := Button.new()
	rnd.text = "Random Leader"
	rnd.position = Vector2(196, 650)
	rnd.custom_minimum_size = Vector2(180, 44)
	rnd.pressed.connect(func():
		_choose(_cards[randi() % _cards.size()].get_meta("leader")))
	add_child(rnd)
	var view := Button.new()
	view.text = "Deck"
	view.position = Vector2(392, 650)
	view.custom_minimum_size = Vector2(140, 44)
	view.pressed.connect(func():
		var d := DeckSculpt.new()
		d.leader_id = _deck_leader
		d.deck = _deck.duplicate()
		d.editable = _ng() >= 1 and not Game.profile["collection"].is_empty()
		if Game.profile["collection"].is_empty():
			d.reason = "Win a run to start a collection. On New Game+ runs you can swap collected cards into your starting deck."
		elif _ng() < 1:
			d.reason = "Choose a New Game+ level to swap collected cards into your starting deck."
		add_child(d)
		d.done.connect(func(new_deck):
			_deck = new_deck
			_show_deck()
			view.grab_focus()))
	add_child(view)
	# New Game+ level: shown once unlocked; NG+ runs are harder and need more sectors
	_ng_pick = OptionButton.new()
	_ng_pick.position = Vector2(548, 650)
	_ng_pick.custom_minimum_size = Vector2(152, 44)
	_ng_pick.add_item("Standard", 0)
	for n in range(1, int(Game.profile["ng_unlocked"]) + 1):
		_ng_pick.add_item("NG+%d" % n, n)
	_ng_pick.tooltip_text = "New Game+: tougher from the start, ramps faster, more sectors to claim. Lets you sculpt your starting deck."
	_ng_pick.visible = int(Game.profile["ng_unlocked"]) > 0
	_ng_pick.item_selected.connect(func(_i):
		if _ng() == 0:
			_deck = Game.starter_deck(_deck_leader)
			_show_deck())
	add_child(_ng_pick)
	_slot_pick = OptionButton.new()
	_slot_pick.position = Vector2(716, 650)
	_slot_pick.custom_minimum_size = Vector2(314, 44)
	for s in Game.SLOTS:
		var d := Game.read_slot(s)
		var txt := "Slot %d (empty)" % (s + 1) if d.is_empty() else "Slot %d: replace %s" % [s + 1, Game.UNITS[Game.leader_by_id(d["leader"])["leader"]]["name"]]
		_slot_pick.add_item(txt, s)
	var free := Game.first_free_slot()
	_slot_pick.select(free if free >= 0 else 0)
	add_child(_slot_pick)
	_begin = Button.new()
	_begin.text = "Begin Run  ▶"
	_begin.position = Vector2(1046, 650)
	_begin.custom_minimum_size = Vector2(204, 44)
	_begin.pressed.connect(_on_begin)
	add_child(_begin)

func _on_begin() -> void:
	var id: String = Game.LEADERS[_selected]["id"]
	var start: Array = _deck if _ng() >= 1 and Game.valid_start_deck(id, _deck) else []
	Game.new_run(id, _slot_pick.get_selected_id(), _ng(), start)
	Game.go(Game.resume_scene())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()

func _back() -> void:
	Game.go("res://scenes/main_menu.tscn")
