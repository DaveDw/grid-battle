extends Control
## Animated backdrop for menus and battles. Two looks:
##   "grid":  dark gradient, a receding battle grid scrolling toward the viewer, motes,
##            and (optionally) a planet rising over the horizon.
##   "space": starfield with twinkling stars, soft nebula clouds in `tint`, and
##            (optionally) a large planet slowly drifting.
## `planet` is an index into assets/planets (-1 = none). `tint` colours the grid lines,
## nebulae and motes; set_tint() fades to a new colour (leader select follows the
## browsed faction).

var style := "grid"
var tint := Color(0.3, 0.5, 0.9)
var planet := -1
var planet_pos := Vector2(1040, 470)
var planet_size := 300.0
var dim := 0.0                  # extra darkening (battles keep the grid readable)

var _t := 0.0
var _motes: Array = []
var _stars: Array = []
var _clouds: Array = []
var _tex: Texture2D
var _target_tint := Color()
var _soft: GradientTexture2D    # white centre fading to clear, for glows and nebulae

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_tint = tint
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	_soft = GradientTexture2D.new()
	_soft.gradient = g
	_soft.fill = GradientTexture2D.FILL_RADIAL
	_soft.fill_from = Vector2(0.5, 0.5)
	_soft.fill_to = Vector2(1.0, 0.5)
	_soft.width = 128
	_soft.height = 128
	for i in 60:
		_motes.append([Vector2(randf() * 1280.0, randf() * 720.0), randf_range(8, 30), randf_range(1.0, 2.5), randf()])
	for i in 140:
		_stars.append([Vector2(randf() * 1280.0, randf() * 720.0), randf_range(0.6, 1.8), randf() * TAU, randf_range(0.5, 2.5)])
	for i in 7:
		_clouds.append([Vector2(randf() * 1280.0, randf() * 720.0), randf_range(160, 320), randf(), randf_range(-6, 6)])
	if planet >= 0:
		_tex = load("res://assets/planets/planet_%02d.png" % planet)

## A configured backdrop, ready to add_child().
static func make(look: String, col: Color, planet_index := -1, pos := Vector2(1040, 470), planet_px := 300.0) -> Control:
	var b = load("res://scripts/menu_background.gd").new()
	b.style = look
	b.tint = col
	b.planet = planet_index
	b.planet_pos = pos
	b.planet_size = planet_px
	return b

## Fade the backdrop's colour to `c`.
func set_tint(c: Color) -> void:
	_target_tint = c

## The planet's average colour (for tinting a backdrop to match it).
static func planet_color(index: int) -> Color:
	var img: Image = load("res://assets/planets/planet_%02d.png" % index).get_image()
	if img.is_compressed():
		img.decompress()
	var sum := Vector3.ZERO
	var n := 0
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				sum += Vector3(c.r, c.g, c.b)
				n += 1
	if n == 0:
		return Color(0.3, 0.5, 0.9)
	sum /= n
	return Color(sum.x, sum.y, sum.z).lightened(0.15)

func _process(delta: float) -> void:
	_t += delta
	tint = tint.lerp(_target_tint, minf(delta * 3.0, 1.0))
	for m in _motes:
		m[0].y -= m[1] * delta
		m[0].x += sin(_t * 0.5 + m[3] * 10.0) * 6.0 * delta
		if m[0].y < -5.0:
			m[0] = Vector2(randf() * 1280.0, 725.0)
	for c in _clouds:
		c[0].x = fposmod(c[0].x + c[3] * delta, 1600.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color(0.03, 0.035, 0.07)
	var bottom := Color(0.06, 0.08, 0.15).lerp(tint.darkened(0.75), 0.35)
	for i in 12:
		var y0 := h * i / 12.0
		draw_rect(Rect2(0, y0, w, h / 12.0 + 1.0), top.lerp(bottom, float(i) / 11.0))
	if style == "space":
		_draw_space(w, h)
	else:
		_draw_grid(w, h)
	if dim > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, dim))

func _draw_space(w: float, h: float) -> void:
	# nebula: big soft blobs in the tint (a radial gradient, so no visible rings)
	for c in _clouds:
		var p: Vector2 = c[0] - Vector2(160, 0)
		var col := tint.lerp(Color(0.6, 0.3, 0.9), c[2] * 0.4)
		var r: float = c[1] * 1.3
		draw_texture_rect(_soft, Rect2(p - Vector2(r, r * 0.7), Vector2(r * 2.0, r * 1.4)), false, Color(col, 0.16))
	for s in _stars:
		var a := 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * s[3] + s[2]))
		draw_circle(s[0], s[1], Color(0.85, 0.9, 1.0, a * 0.8))
		if s[1] > 1.6:   # the brightest get a cross glint
			draw_line(s[0] - Vector2(4, 0), s[0] + Vector2(4, 0), Color(1, 1, 1, a * 0.35), 1.0)
			draw_line(s[0] - Vector2(0, 4), s[0] + Vector2(0, 4), Color(1, 1, 1, a * 0.35), 1.0)
	if _tex:
		var bob := Vector2(sin(_t * 0.15) * 6.0, sin(_t * 0.21) * 4.0)
		var s := planet_size / _tex.get_height()
		var sz := Vector2(_tex.get_width() * s, planet_size)
		var c := planet_pos + bob
		# atmosphere glow behind the planet
		var halo := planet_size * 0.85
		draw_texture_rect(_soft, Rect2(c - Vector2(halo, halo), Vector2(halo, halo) * 2.0), false, Color(tint, 0.3))
		draw_texture_rect(_tex, Rect2(c - sz * 0.5, sz), false)

func _draw_grid(w: float, h: float) -> void:
	var horizon := h * 0.55
	for s in _stars:
		if s[0].y < horizon:
			draw_circle(s[0], s[1] * 0.8, Color(0.85, 0.9, 1.0, 0.25 + 0.3 * sin(_t * s[3] + s[2])))
	# a planet rising behind the horizon (drawn before the floor so the floor cuts it)
	if _tex:
		var s := planet_size / _tex.get_height()
		var sz := Vector2(_tex.get_width() * s, planet_size)
		var c := Vector2(planet_pos.x, horizon - planet_size * 0.18 + sin(_t * 0.2) * 4.0)
		var halo := planet_size * 0.85
		draw_texture_rect(_soft, Rect2(c - Vector2(halo, halo), Vector2(halo, halo) * 2.0), false, Color(tint, 0.3))
		draw_texture_rect(_tex, Rect2(c - sz * 0.5, sz), false)
		draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.04, 0.05, 0.1))
	# receding grid floor: horizon at 55% height
	var vp := Vector2(w * 0.5, horizon - 60.0)
	for i in range(-12, 13):
		var bx := w * 0.5 + i * 130.0
		draw_line(Vector2(bx, h), vp.lerp(Vector2(bx, h), 0.18), Color(tint, 0.12), 1.5)
	var scroll := fmod(_t * 0.35, 1.0)
	for k in 14:
		var f := (float(k) + scroll) / 14.0
		var y := horizon + (h - horizon) * f * f
		draw_line(Vector2(0, y), Vector2(w, y), Color(tint, 0.04 + 0.14 * f), 1.5)
	draw_line(Vector2(0, horizon), Vector2(w, horizon), Color(tint, 0.25), 2.0)
	for m in _motes:
		var a := 0.25 + 0.25 * sin(_t * 2.0 + m[3] * 6.0)
		draw_circle(m[0], m[2], Color(tint.lightened(0.4), a))
