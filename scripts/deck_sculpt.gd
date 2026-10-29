class_name DeckSculpt
extends Control
## Starting-deck editor for New Game+ runs: pick a card in the starting deck, then a
## collected card to swap in. The deck stays the starter deck's size, the leader card
## is locked, and each collected card can be used as many times as it's owned.
## Opened read-only (with `reason`) when sculpting isn't available.

signal done(deck: Array)

var leader_id := ""
var deck: Array = []
var editable := false
var reason := ""

var _slot := -1
var _left: VBoxContainer
var _right: VBoxContainer
var _hint: Label
var _ok: Button
var _refocus := -1              # deck index to put focus back on after a rebuild

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.theme
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(140, 40)
	panel.custom_minimum_size = Vector2(1000, 640)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = "STARTING DECK  —  %s" % Game.UNITS[Game.leader_by_id(leader_id)["leader"]]["name"].to_upper()
	title.add_theme_font_override("font", Game.FONT_HEAD)
	title.add_theme_font_size_override("font_size", 26)
	v.add_child(title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint.custom_minimum_size = Vector2(960, 0)
	_hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.9))
	v.add_child(_hint)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	cols.custom_minimum_size = Vector2(960, 470)
	v.add_child(cols)
	_left = VBoxContainer.new()
	_left.custom_minimum_size = Vector2(440, 0)
	cols.add_child(_left)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true      # controller focus scrolls the collection
	cols.add_child(scroll)
	_right = VBoxContainer.new()
	_right.custom_minimum_size = Vector2(460, 0)
	scroll.add_child(_right)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	bar.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bar)
	if editable:
		var reset := Button.new()
		reset.text = "Reset to Starter"
		reset.custom_minimum_size = Vector2(190, 42)
		reset.pressed.connect(func():
			deck = Game.starter_deck(leader_id)
			_slot = -1
			_refresh())
		bar.add_child(reset)
	var ok := Button.new()
	ok.text = "Done"
	ok.custom_minimum_size = Vector2(150, 42)
	ok.pressed.connect(_close)
	bar.add_child(ok)
	_ok = ok
	_refresh()
	ok.grab_focus()

## Copies of `id` still free to add (owned minus those already used beyond the starter).
func _available(id: String) -> int:
	var extra := deck.duplicate()
	for c in Game.starter_deck(leader_id):
		extra.erase(c)
	return int(Game.collection_counts().get(id, 0)) - extra.count(id)

func _refresh() -> void:
	for c in _left.get_children() + _right.get_children():
		c.queue_free()
	if not editable:
		_hint.text = reason
	elif _slot < 0:
		_hint.text = "Pick a card in your starting deck to replace. Your leader card stays."
	else:
		_hint.text = "Now pick a collected card to put in place of %s." % Game.CARDS[deck[_slot]]["name"]
	_header(_left, "STARTING DECK  (%d)" % deck.size())
	var lead := Game.leader_card(leader_id)
	var lead_seen := false
	for i in deck.size():
		var id: String = deck[i]
		var locked := id == lead and not lead_seen
		if locked:
			lead_seen = true
		var b := _card_button(id, ("  ·  leader, locked" if locked else ""))
		b.disabled = locked or not editable
		if i == _slot:
			b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			b.add_theme_color_override("font_focus_color", Color(1.0, 0.85, 0.3))
		b.pressed.connect(func():
			_slot = -1 if _slot == i else i
			_refocus = i
			_refresh())
		_left.add_child(b)
	var owned := Game.collection_counts()
	_header(_right, "COLLECTION  (%d)" % Game.profile["collection"].size())
	if owned.is_empty():
		var none := Label.new()
		none.text = "No collected cards yet. Win a run to claim one."
		none.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		_right.add_child(none)
	for id in owned:
		var free := _available(id)
		var b := _card_button(id, "  ·  %d of %d free" % [free, owned[id]])
		b.disabled = not editable or _slot < 0 or free <= 0
		b.pressed.connect(func():
			_refocus = _slot
			deck[_slot] = id
			_slot = -1
			_refresh())
		_right.add_child(b)
	_restore_focus.call_deferred()

## Rebuilding frees the focused button, so a controller would lose its place: after
## picking a deck card, focus the first collected card that can replace it; after a
## swap (or cancelling), go back to that deck slot.
func _restore_focus() -> void:
	if _refocus < 0:
		return
	var target: Control = null
	if _slot >= 0:
		for b in _right.get_children():
			if b is Button and not b.disabled and not b.is_queued_for_deletion():
				target = b
				break
	else:
		var buttons := _left.get_children().filter(func(b): return b is Button and not b.is_queued_for_deletion())
		if _refocus < buttons.size() and not buttons[_refocus].disabled:
			target = buttons[_refocus]
	if target == null:
		target = _ok
	target.grab_focus()

func _header(box: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
	box.add_child(l)

func _card_button(id: String, suffix: String) -> Button:
	var c: Dictionary = Game.CARDS[id]
	var b := Button.new()
	b.text = "%s  (%d)%s" % [c["name"], int(c["cost"]), suffix]
	b.tooltip_text = c["text"]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_override("font", Game.FONT_CARD)
	b.add_theme_font_size_override("font_size", 8)
	Game.card_button_icon(b, id)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _slot >= 0:
			_refocus = _slot
			_slot = -1
			_refresh()
		else:
			_close()

func _close() -> void:
	done.emit(deck)
	queue_free()
