extends SceneTree
## Side-by-side close-ups at the same on-screen height, scaled with nearest filtering.
func _initialize():
	var keys := ["terran/pathfinder", "manyworlds/reed_runner", "ascendancy/field_scholar", "long/cinder_scout", "long/parallax"]
	var H := 300
	var sheet := Image.create(keys.size() * 260, H + 20, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.12, 0.18))
	var x := 0
	for k in keys:
		var img := Image.load_from_file("res://assets/sprites/%s.png" % k)
		var s := float(H) / img.get_height()
		img.resize(int(img.get_width() * s), H, Image.INTERPOLATE_NEAREST)
		var crop := img.get_region(Rect2i(maxi(0, img.get_width() / 2 - 125), 0, mini(250, img.get_width()), H))
		sheet.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(x + 5, 10))
		x += 260
	sheet.save_png("C:/Users/ddwig/AppData/Local/Temp/art_compare.png")
	quit()
