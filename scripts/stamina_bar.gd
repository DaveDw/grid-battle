class_name StaminaBar
extends Control
## Shared squad stamina: SEGMENTS chunks that refill one at a time, all the time.
## Every move spends one chunk, which breaks off the bar as tumbling shards.
## Trying to move with no full chunk shakes the bar red.

const SEGMENTS := 6
const REFILL_TIME := 0.75       # seconds to refill one segment (default)
const GAP := 6.0
const FULL_COLOR := Color(0.36, 1.0, 0.62)
const FILL_COLOR := Color(0.2, 0.62, 0.42)
const EMPTY_COLOR := Color(0.1, 0.13, 0.18)
const EDGE_COLOR := Color(0.6, 1.0, 0.8, 0.5)

var value := float(SEGMENTS)    # in segments; fractional part is the one refilling
var refill_time := REFILL_TIME  # sector modifiers can change it
var refill_clock := RefillClock.new()
var _shards: Array = []         # {pos, vel, rot, spin, life, size, color}
var _pops: Array = []           # [segment index, time left] glow when a segment completes
var _shake := 0.0
var _deny := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(360, 34)

## Spend one segment for a move. Returns false (and shakes) if none is full.
func try_spend() -> bool:
	if value < 1.0:
		deny()
		return false
	var idx := int(ceil(value)) - 1
	value -= 1.0
	_break_segment(idx)
	return true

## Give back `n` chunks (e.g. Pathfinder's Steady Aim), with the completion glow.
func refund(n: int) -> void:
	var before := int(value)
	value = minf(value + n, SEGMENTS)
	for i in range(before, int(value)):
		_pops.append([i, 0.25])

## Take chunks without the full-chunk check (Void Orb drag). Returns chunks taken.
func force_spend(n: int) -> int:
	var taken := 0
	for k in n:
		if value >= 1.0:
			var idx := int(ceil(value)) - 1
			value -= 1.0
			_break_segment(idx)
			taken += 1
	return taken

func is_full() -> bool:
	return value >= SEGMENTS

func deny() -> void:
	if is_visible_in_tree():
		Sfx.denied()
	_shake = 0.3
	_deny = 0.3

func _seg_rect(i: int) -> Rect2:
	var w := (size.x - GAP * (SEGMENTS - 1)) / SEGMENTS
	return Rect2(i * (w + GAP), 16.0, w, size.y - 16.0)

func _break_segment(i: int) -> void:
	var r := _seg_rect(i)
	# 6 shards from the segment, flung up and outward
	for k in 6:
		var fx := (k % 3 + 0.5) / 3.0
		var fy := (k / 3 + 0.5) / 2.0
		_shards.append({
			"pos": r.position + Vector2(r.size.x * fx, r.size.y * fy),
			"vel": Vector2(randf_range(-90, 90) + (fx - 0.5) * 140.0, randf_range(-260, -150)),
			"rot": 0.0,
			"spin": randf_range(-12, 12),
			"life": 0.7,
			"size": Vector2(r.size.x / 3.0, r.size.y / 2.0) * randf_range(0.8, 1.05),
			"color": FULL_COLOR,
		})

func _process(delta: float) -> void:
	var refill_delta := refill_clock.tick(delta)
	if value < SEGMENTS:
		var before := int(value)
		value = minf(value + refill_delta / refill_time, SEGMENTS)
		if int(value) > before:
			_pops.append([before, 0.25])
	for s in _shards:
		s["vel"].y += 900.0 * delta
		s["pos"] += s["vel"] * delta
		s["rot"] += s["spin"] * delta
		s["life"] -= delta
	_shards = _shards.filter(func(s): return s["life"] > 0.0)
	for p in _pops:
		p[1] -= delta
	_pops = _pops.filter(func(p): return p[1] > 0.0)
	_shake = maxf(_shake - delta, 0.0)
	_deny = maxf(_deny - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var off := Vector2(sin(_shake * 80.0) * 6.0 * (_shake / 0.3), 0.0)
	draw_string(font, off + Vector2(0, 12), "STAMINA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 1.0, 0.85))
	draw_string(Game.FONT_NUM, off + Vector2(size.x - 40, 12), "%d/%d" % [int(value), SEGMENTS], HORIZONTAL_ALIGNMENT_RIGHT, 40, 8, Color(0.7, 1.0, 0.85))
	for i in SEGMENTS:
		var r := _seg_rect(i)
		r.position += off
		draw_rect(r, EMPTY_COLOR)
		var fill := clampf(value - i, 0.0, 1.0)
		if fill >= 1.0:
			draw_rect(r, FULL_COLOR)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(1, 1, 1, 0.35))  # top shine
		elif fill > 0.0:
			draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), FILL_COLOR)
		draw_rect(r, EDGE_COLOR, false, 1.5)
		if _deny > 0.0:
			draw_rect(r, Color(1.0, 0.25, 0.25, _deny / 0.3 * 0.6))
	for p in _pops:
		var r := _seg_rect(p[0]).grow(6.0 * (1.0 - p[1] / 0.25))
		draw_rect(r, Color(0.8, 1.0, 0.9, p[1] / 0.25 * 0.8), false, 2.0)
	for s in _shards:
		var a: float = clampf(s["life"] / 0.7, 0.0, 1.0)
		var c: Color = s["color"]
		draw_set_transform(s["pos"], s["rot"])
		draw_rect(Rect2(-s["size"] * 0.5, s["size"]), Color(c.r, c.g, c.b, a))
		draw_rect(Rect2(-s["size"] * 0.5, s["size"]), Color(1, 1, 1, a * 0.6), false, 1.0)
	draw_set_transform(Vector2.ZERO)
