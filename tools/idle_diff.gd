extends SceneTree
## Review sheet for an idle strip: frame 1, then frames 3, 5 and 7, each next to a motion
## map against frame 1. The map splits the art into 12 px blocks and finds how far each
## block moved (search +-4 px):
##   grey   = unchanged
##   colour = moved as a whole (hue = direction, so a rigid part is one flat colour)
##   red    = changed shape (warped, bent or repainted). Fine for glows, flame and flag cloth only.
## Prints the share of art blocks in each class.
## usage: godot --headless --path . -s tools/idle_diff.gd -- <faction>/<unit> <out.png>

const N := 8
const B := 12
const R := 4

func _initialize():
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(ProjectSettings.globalize_path("res://art_incoming/%s_idle.png" % a[0]))
	src.convert(Image.FORMAT_RGBA8)
	var cw := src.get_width() / N
	var ch := src.get_height()
	var frames: Array[Image] = []
	for i in N:
		frames.append(src.get_region(Rect2i(i * cw, 0, cw, ch)))
	var picks := [2, 4, 6]
	var out := Image.create(cw * (1 + picks.size() * 2), ch, false, Image.FORMAT_RGBA8)
	out.blit_rect(frames[0], Rect2i(0, 0, cw, ch), Vector2i.ZERO)
	var x := cw
	for p in picks:
		out.blit_rect(frames[p], Rect2i(0, 0, cw, ch), Vector2i(x, 0))
		out.blit_rect(_motion(frames[0], frames[p], p + 1), Rect2i(0, 0, cw, ch), Vector2i(x + cw, 0))
		x += cw * 2
	out.save_png(a[1])
	quit()

func _bg(c: Color) -> bool:
	return c.a < 0.1 or (c.r > 0.85 and c.g < 0.2 and c.b > 0.85)

func _px(img: Image, x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return Color(1, 0, 1)
	return img.get_pixel(x, y)

func _err(f: Image, g: Image, bx: int, by: int, dx: int, dy: int) -> float:
	var e := 0.0
	for y in range(by, by + B):
		for x in range(bx, bx + B):
			var c1 := f.get_pixel(x, y)
			var c2 := _px(g, x + dx, y + dy)
			var b1 := _bg(c1)
			if b1 != _bg(c2):
				e += 1.0
			elif not b1:
				e += minf(1.0, (absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b)) * 2.0)
	return e / float(B * B)

func _motion(f: Image, g: Image, label: int) -> Image:
	var d := Image.create(f.get_width(), f.get_height(), false, Image.FORMAT_RGBA8)
	d.fill(Color.BLACK)
	var still := 0
	var moved := 0
	var warped := 0
	for by in range(0, f.get_height() - B + 1, B):
		for bx in range(0, f.get_width() - B + 1, B):
			var art := 0
			for y in range(by, by + B, 3):
				for x in range(bx, bx + B, 3):
					if not _bg(f.get_pixel(x, y)):
						art += 1
			if art < 4:
				continue
			var best := _err(f, g, bx, by, 0, 0)
			var bd := Vector2i.ZERO
			if best > 0.03:
				for dy in range(-R, R + 1):
					for dx in range(-R, R + 1):
						var e := _err(f, g, bx, by, dx, dy)
						if e < best - 0.001:
							best = e
							bd = Vector2i(dx, dy)
			var col: Color
			if best > 0.12:
				col = Color(0.95, 0.1, 0.1)
				warped += 1
			elif bd == Vector2i.ZERO:
				col = Color(0.45, 0.45, 0.45)
				still += 1
			else:
				col = Color.from_hsv(fposmod(atan2(bd.y, bd.x) / TAU, 1.0) * 0.8 + 0.15, 0.7, 0.5 + 0.12 * bd.length())
				moved += 1
			d.fill_rect(Rect2i(bx, by, B - 1, B - 1), col)
	var t: int = max(still + moved + warped, 1)
	print("frame %d vs 1: still %d%%  moved-rigid %d%%  changed-shape %d%%" % [label, 100 * still / t, 100 * moved / t, 100 * warped / t])
	return d
