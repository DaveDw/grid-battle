class_name LastCard
extends PanelContainer
## The last card a side played, shown beside the board (yours on the left, the enemy's
## on the right) so it's clear what just happened. It flashes when a new card lands and
## stays until the next one.

var team := 0
var _head: Label
var _icon: TextureRect
var _name: Label
var _cost: Label
var _text: Label
var _flash: Tween

func setup(for_team: int) -> void:
	team = for_team
	custom_minimum_size = Vector2(172, 0)
	size = Vector2(172, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 0.85)
	sb.border_color = Color(0.45, 0.8, 1.0) if team == 0 else Color(1.0, 0.55, 0.35)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(8)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_head = _label(8, sb.border_color)
	_head.text = "YOU PLAYED" if team == 0 else "ENEMY PLAYED"
	v.add_child(_head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_icon = Game.card_icon("", 32)
	row.add_child(_icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 2)
	row.add_child(names)
	_name = _label(8, Color(0.95, 0.97, 1.0))
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name.custom_minimum_size = Vector2(110, 0)
	names.add_child(_name)
	_cost = _label(8, Color(0.45, 0.8, 1.0))
	names.add_child(_cost)
	_text = _label(8, Color(0.78, 0.83, 0.92))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.custom_minimum_size = Vector2(156, 0)
	_text.add_theme_constant_override("line_spacing", 3)
	v.add_child(_text)
	visible = false

func _label(px: int, c: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", Game.FONT_CARD)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## A new card from this side: fill in and flash.
func show_card(id: String, cost: float) -> void:
	var c: Dictionary = Game.CARDS[id]
	_icon.texture = Game.card_art(id)
	_name.text = c["name"]
	_name.add_theme_color_override("font_color", Game.rarity_color(id))
	_cost.text = "%d energy" % int(cost)
	_text.text = c["text"].replace("/", "/" + char(0x2060))
	size = Vector2(172, 0)   # shrink to the new text
	visible = true
	if _flash:
		_flash.kill()
	modulate = Color(2.0, 2.0, 2.0)
	scale = Vector2(1.06, 1.06)
	_flash = create_tween().set_parallel()
	_flash.tween_property(self, "modulate", Color.WHITE, 0.35)
	_flash.tween_property(self, "scale", Vector2.ONE, 0.2)
