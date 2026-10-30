class_name DeckView
extends Control
## Read-through of a deck: groups of cards (e.g. Hand / Draw pile / Used, or the
## starter deck), each card shown once with its count, cost and text. Draw-pile order
## is never shown. Used by the pause menu and leader select. Back / Esc / B closes.

signal closed

const CARD_W := 300.0
const CARD_H := 84.0

var groups: Array = []          # [[title, [card ids]], ...]
var title := "DECK"
var note := ""                  # shown instead of "—" for an empty group
var _scroll: ScrollContainer

## Only Back takes focus, so a controller scrolls the cards with the D-pad or either stick.
func _process(delta: float) -> void:
	var dir := Input.get_axis("ui_up", "ui_down") + Input.get_axis("aim_up", "aim_down")
	if absf(dir) > 0.1:
		_scroll.scroll_vertical += int(signf(dir) * minf(absf(dir), 1.0) * 700.0 * delta)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.theme   # may live under a CanvasLayer, which blocks theme inheritance
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(150, 50)
	panel.custom_minimum_size = Vector2(980, 620)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := Label.new()
	head.text = title
	head.add_theme_font_override("font", Game.FONT_HEAD)
	head.add_theme_font_size_override("font_size", 28)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.custom_minimum_size = Vector2(940, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(920, 0)
	scroll.add_child(body)
	for g in groups:
		var ids: Array = g[1]
		var gl := Label.new()
		gl.text = "%s  (%d)" % [g[0].to_upper(), ids.size()]
		gl.add_theme_font_size_override("font_size", 15)
		gl.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
		body.add_child(gl)
		if ids.is_empty():
			var none := Label.new()
			none.text = note if note != "" else "—"
			none.autowrap_mode = TextServer.AUTOWRAP_WORD
			none.custom_minimum_size = Vector2(900, 0)
			none.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			body.add_child(none)
			continue
		var counts := {}
		for id in ids:
			counts[id] = counts.get(id, 0) + 1
		var names := counts.keys()
		names.sort_custom(func(a, b): return Game.CARDS[a]["name"] < Game.CARDS[b]["name"])
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		body.add_child(flow)
		for id in names:
			flow.add_child(_card(id, counts[id]))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(160, 42)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(close)
	v.add_child(back)
	back.grab_focus()

func _card(id: String, count: int) -> Control:
	var c: Dictionary = Game.CARDS[id]
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(CARD_W, CARD_H)
	Game.rarity_frame(box, id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(Game.card_icon(id, 64))   # the card's art at 2x
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var n := Label.new()
	n.text = ("%d× " % count if count > 1 else "") + c["name"]
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_theme_font_override("font", Game.FONT_CARD)
	n.add_theme_font_size_override("font_size", 10)
	top.add_child(n)
	var cost := Label.new()
	cost.text = "%d" % int(Game.card_cost(id))
	var note := Game.discount_note(id) if Game.run.get("deck", []).has(id) else ""
	if note != "":
		cost.text += "  (%s)" % note
	cost.add_theme_font_override("font", Game.FONT_CARD)
	cost.add_theme_font_size_override("font_size", 10)
	cost.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
	top.add_child(cost)
	var t := Label.new()
	t.text = c["text"].replace("/", "/" + char(0x2060))   # word joiner: never break "HP/s" after the slash
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	t.custom_minimum_size = Vector2(CARD_W - 110, 0)
	t.add_theme_font_override("font", Game.FONT_CARD)
	t.add_theme_font_size_override("font_size", 8)
	t.add_theme_constant_override("line_spacing", 4)
	t.add_theme_color_override("font_color", Color(0.7, 0.76, 0.88))
	v.add_child(t)
	return box

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	closed.emit()
	queue_free()
