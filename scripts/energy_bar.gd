class_name EnergyBar
extends Control
## Shared squad energy. Abilities shave it down; it starts recharging once no ability
## has been used for RECHARGE_DELAY seconds. A spend leaves a white "ghost" of the lost
## amount that drains away, and throws sparks off the cut edge. Not enough energy
## shakes the bar red.

const MAX := 100.0
const RECHARGE_DELAY := 1.5     # default; sector modifiers can change recharge_delay
const RECHARGE_RATE := 30.0     # per second once recharging
const BAR_COLOR := Color(0.25, 0.7, 1.0)
const BAR_HI := Color(0.6, 0.9, 1.0)
const EMPTY_COLOR := Color(0.08, 0.11, 0.18)

var value := MAX
var recharge_delay := RECHARGE_DELAY
var _ghost := MAX               # trails behind value after a spend
var _ghost_hold := 0.0
var _delay := 0.0
var _sparks: Array = []         # {pos, vel, life}
var _shake := 0.0
var _deny := 0.0
var _flash := 0.0
var _t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(360, 34)

## Pay `cost` for an ability. Returns false (and shakes) if there isn't enough.
func try_spend(cost: float) -> bool:
	if value < cost:
		deny()
		return false
	_ghost = maxf(_ghost, value)
	_ghost_hold = 0.3
	value -= cost
	_delay = recharge_delay
	_flash = 0.15
	var edge := _bar_rect().position + Vector2(_bar_rect().size.x * value / MAX, _bar_rect().size.y * 0.5)
	for k in 14:
		_sparks.append({"pos": edge + Vector2(0, randf_range(-8, 8)), "vel": Vector2(randf_range(20, 220), randf_range(-160, 60)), "life": randf_range(0.25, 0.5)})
	return true

## Continuous spend (held Charge Beam): takes up to `amount`, returns what it got.
## Holds off the recharge like a normal spend.
func drain(amount: float) -> float:
	var got := minf(amount, value)
	if got <= 0.0:
		return 0.0
	_ghost = maxf(_ghost, value)
	_ghost_hold = 0.3
	value -= got
	_delay = recharge_delay
	return got

## Give energy back (e.g. Analysis refunds). Does not interrupt the recharge delay.
func refund(amount: float) -> void:
	value = minf(value + amount, MAX)
	_flash = 0.1

func deny() -> void:
	if is_visible_in_tree():
		Sfx.denied()
	_shake = 0.3
	_deny = 0.3

func is_recharging() -> bool:
	return _delay <= 0.0 and value < MAX

func _bar_rect() -> Rect2:
	return Rect2(0, 16, size.x, size.y - 16)

func _process(delta: float) -> void:
	_t += delta
	if _delay > 0.0:
		_delay -= delta
	elif value < MAX:
		value = minf(value + RECHARGE_RATE * delta, MAX)
	if _ghost_hold > 0.0:
		_ghost_hold -= delta
	else:
		_ghost = move_toward(_ghost, value, 120.0 * delta)
	_ghost = maxf(_ghost, value)
	for s in _sparks:
		s["vel"].y += 500.0 * delta
		s["pos"] += s["vel"] * delta
		s["life"] -= delta
	_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
	_shake = maxf(_shake - delta, 0.0)
	_deny = maxf(_deny - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var off := Vector2(sin(_shake * 80.0) * 6.0 * (_shake / 0.3), 0.0)
	var r := _bar_rect()
	r.position += off
	var status := "RECHARGING" if is_recharging() else ("" if value >= MAX else "recharge in %.1fs" % maxf(_delay, 0.0))
	draw_string(font, off + Vector2(0, 12), "ENERGY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, BAR_HI)
	draw_string(font, off + Vector2(70, 12), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.75, 0.9, 0.8))
	draw_string(font, off + Vector2(size.x - 60, 12), "%d/%d" % [int(value), int(MAX)], HORIZONTAL_ALIGNMENT_RIGHT, 60, 13, BAR_HI)
	draw_rect(r, EMPTY_COLOR)
	# ghost of the shaved-off energy
	draw_rect(Rect2(r.position, Vector2(r.size.x * _ghost / MAX, r.size.y)), Color(1, 1, 1, 0.85))
	var fill := Rect2(r.position, Vector2(r.size.x * value / MAX, r.size.y))
	draw_rect(fill, BAR_COLOR.lerp(Color.WHITE, _flash / 0.15 * 0.6))
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 4)), Color(1, 1, 1, 0.3))
	if is_recharging():
		# shimmer sweeping along the filled part
		var x := fmod(_t * 220.0, maxf(fill.size.x, 1.0))
		draw_rect(Rect2(fill.position + Vector2(maxf(x - 18.0, 0.0), 0), Vector2(minf(18.0, x), fill.size.y)), Color(1, 1, 1, 0.3))
	# quarter ticks
	for q in range(1, 4):
		var tx := r.position.x + r.size.x * q / 4.0
		draw_line(Vector2(tx, r.position.y), Vector2(tx, r.end.y), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(r, Color(0.6, 0.85, 1.0, 0.5), false, 1.5)
	if _deny > 0.0:
		draw_rect(r, Color(1.0, 0.25, 0.25, _deny / 0.3 * 0.6))
	for s in _sparks:
		var a: float = clampf(s["life"] / 0.4, 0.0, 1.0)
		draw_line(s["pos"], s["pos"] - s["vel"] * 0.03, Color(0.8, 0.95, 1.0, a), 2.0)
