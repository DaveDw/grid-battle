extends SceneTree
## Every sprite with a red dot where its shots leave the art (Game.UNITS muzzle; y is
## measured up from the feet), to check muzzle points.
func _initialize():
	run()
func run():
	await process_frame
	var G = root.get_node("Game")
	var sheet := Image.create(6 * 250, 4 * 270, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.14, 0.2))
	var fi := 0
	for fac in ["terran", "ascendancy", "manyworlds", "long"]:
		var i := 0
		for key in G.UNITS:
			if not key.begins_with(fac + "/"):
				continue
			var img := Image.load_from_file("res://assets/sprites/%s.png" % key)
			var s := minf(240.0 / img.get_width(), 250.0 / img.get_height())
			img.resize(int(img.get_width() * s), int(img.get_height() * s))
			var at := Vector2i(i * 250 + 5, fi * 270 + 5)
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
			var m: Vector2 = G.UNITS[key]["muzzle"]
			var p := at + Vector2i(int(m.x * img.get_width()), int((1.0 - m.y) * img.get_height()))
			for dy in range(-6, 7):
				for dx in range(-6, 7):
					if dx * dx + dy * dy <= 36:
						var q := p + Vector2i(dx, dy)
						if q.x >= 0 and q.y >= 0 and q.x < sheet.get_width() and q.y < sheet.get_height():
							sheet.set_pixelv(q, Color(1, 0.1, 0.1))
			i += 1
		fi += 1
	sheet.save_png("C:/Users/ddwig/AppData/Local/Temp/muzzles.png")
	quit()
