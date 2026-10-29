extends SceneTree
# Usage: -- <strip.png> <frames> <x> <y> <w> <h> <scale> <out.png>
# Crops one region from every frame, scales it, lays frames side by side,
# and marks pixels that differ from frame 1 in red on a second row.
func _init():
	var a = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	var n := int(a[1])
	var x := int(a[2]); var y := int(a[3]); var w := int(a[4]); var h := int(a[5])
	var s := int(a[6])
	var fw := img.get_width() / n
	var out := Image.create(w * s * n, h * s * 2, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.12, 0.12, 0.14))
	var first := img.get_region(Rect2i(x, y, w, h))
	for f in n:
		var r := img.get_region(Rect2i(f * fw + x, y, w, h))
		for py in h:
			for px in w:
				var c := r.get_pixel(px, py)
				var d := c.is_equal_approx(first.get_pixel(px, py))
				var shown := c if c.a > 0 else Color(0.12, 0.12, 0.14)
				var mark := Color(0.3, 0.3, 0.3) if c.a > 0 else Color(0.12, 0.12, 0.14)
				if not d:
					mark = Color(1, 0.1, 0.1)
				for sy in s:
					for sx in s:
						out.set_pixel(f * w * s + px * s + sx, py * s + sy, shown)
						out.set_pixel(f * w * s + px * s + sx, h * s + py * s + sy, mark)
	out.save_png(a[7])
	quit()
