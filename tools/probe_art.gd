extends SceneTree
## Measures each sprite: size, colour count, mean saturation/brightness, and the
## typical run length of identical pixels (a proxy for "pixel size").
func _initialize():
	for k in ["terran/pathfinder", "terran/breacher", "ascendancy/synapse_brute", "manyworlds/reef_bulwark", "manyworlds/reed_runner", "long/cinder_scout", "long/red_giant", "long/captain_everafter", "long/parallax"]:
		var img := Image.load_from_file("res://assets/sprites/%s.png" % k)
		var cols := {}
		var sat := 0.0
		var val := 0.0
		var n := 0
		var runs := 0
		var run_total := 0
		for y in range(0, img.get_height(), 2):
			var run := 1
			var prev := Color(0, 0, 0, 0)
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.5:
					if run > 1: runs += 1; run_total += run
					run = 1
					prev = c
					continue
				cols[c.to_rgba32() >> 8] = true
				sat += c.s
				val += c.v
				n += 1
				if c.is_equal_approx(prev):
					run += 1
				else:
					runs += 1; run_total += run
					run = 1
				prev = c
		print("%-28s %s colours=%d sat=%.2f val=%.2f avg_run=%.2f" % [k, img.get_size(), cols.size(), sat / n, val / n, float(run_total) / runs])
	quit()
