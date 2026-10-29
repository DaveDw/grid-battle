class_name HealthBar
extends Control
## Fighting-game style health bar for one unit: portrait, name, a slanted fill with a
## red damage trail that catches up after a hit. `mirrored` bars (enemy side) drain
## toward the centre of the screen. The controlled unit's bar is lit and marked.

const TRAIL_HOLD := 0.35
const TRAIL_SPEED := 0.9        # fraction of the bar per second
const SLANT := 10.0

var unit: Unit
var mirrored := false
var _shown := 1.0               # displayed hp fraction
var _trail := 1.0
var _trail_hold := 0.0
var _hit := 0.0
var _portrait: Texture2D

func bind(u: Unit, mirror: bool) -> void:
	unit = u
	mirrored = mirror
	_portrait = u.sprite.get_texture() if u.sprite else null
	u.hp_changed.connect(_on_hp_changed)
	_shown = float(u.hp) / u.max_hp   # start at carried-over HP, no damage trail
	_trail = _shown
	custom_minimum_size = Vector2(440, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # the battlefield handles clicks/taps on bars

func _on_hp_changed(_u: Unit) -> void:
	_trail = maxf(_trail, _shown)
	_trail_hold = TRAIL_HOLD
	_hit = 0.2

func _process(delta: float) -> void:
	if unit == null:
		return
	_shown = float(unit.hp) / unit.max_hp
	if _trail_hold > 0.0:
		_trail_hold -= delta
	else:
		_trail = move_toward(_trail, _shown, TRAIL_SPEED * delta)
	_hit = maxf(_hit - delta, 0.0)
	queue_redraw()

## Slanted bar polygon covering `frac` of the bar, filling from the outer edge.
func _bar_poly(r: Rect2, frac: float) -> PackedVector2Array:
	var w := r.size.x * frac
	if mirrored:
		var x0 := r.end.x - w
		return PackedVector2Array([Vector2(x0, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - SLANT, r.end.y), Vector2(x0 - SLANT, r.end.y)])
	return PackedVector2Array([Vector2(r.position.x + SLANT, r.position.y), Vector2(r.position.x + w + SLANT, r.position.y), Vector2(r.position.x + w, r.end.y), Vector2(r.position.x, r.end.y)])

func _draw() -> void:
	if unit == null:
		return
	var font := ThemeDB.fallback_font
	var lit := unit.active
	var dead := not unit.is_alive()
	var ph := size.y
	# portrait box on the outer edge
	var pbox := Rect2(size.x - ph, 0, ph, ph) if mirrored else Rect2(0, 0, ph, ph)
	draw_rect(pbox, Color(0.12, 0.15, 0.22))
	if _portrait:
		var ts := _portrait.get_size()
		var src := Rect2(ts.x * 0.15, 0, ts.x * 0.7, ts.x * 0.7)  # head and shoulders
		draw_texture_rect_region(_portrait, pbox.grow(-2), src, Color(0.4, 0.4, 0.4) if dead else Color.WHITE)
	draw_rect(pbox, Color(0.5, 0.95, 1.0) if lit else Color(0.4, 0.45, 0.55), false, 2.0 if lit else 1.0)
	var bar := Rect2(ph + 8, ph * 0.42, size.x - ph - 16, ph * 0.58)
	if mirrored:
		bar.position.x = 8
	var role_tag: String = {"leader": "LDR", "heavy": "HVY", "light": "LGT"}.get(unit.role, "")
	var label := "%s  %s" % [unit.unit_name.to_upper(), role_tag]
	if lit:
		label = "> " + label
	var tcol := Color(0.6, 0.95, 1.0) if lit else Color(0.75, 0.78, 0.85)
	if dead:
		label = unit.unit_name.to_upper() + "  DOWN"
		tcol = Color(0.55, 0.5, 0.5)
	draw_string(font, Vector2(bar.position.x, ph * 0.36), label, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT, bar.size.x, 13, tcol)
	draw_colored_polygon(_bar_poly(bar, 1.0), Color(0.07, 0.08, 0.12))
	if _trail > _shown:
		draw_colored_polygon(_bar_poly(bar, _trail), Color(0.9, 0.2, 0.2))
	if _shown > 0.0:
		var c := Color(0.95, 0.85, 0.2).lerp(Color(0.3, 0.95, 0.4), clampf((_shown - 0.25) / 0.5, 0.0, 1.0))
		if _hit > 0.0:
			c = c.lerp(Color.WHITE, _hit / 0.2)
		draw_colored_polygon(_bar_poly(bar, _shown), c)
	var outline := _bar_poly(bar, 1.0)
	outline.append(outline[0])
	draw_polyline(outline, Color(0.5, 0.95, 1.0) if lit else Color(0.45, 0.5, 0.6), 2.0 if lit else 1.0)
	draw_string(Game.FONT_NUM, Vector2(bar.position.x + 14, bar.end.y - 3), "%d" % unit.hp, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT, bar.size.x - 28, 8, Color(0, 0, 0, 0.75))
