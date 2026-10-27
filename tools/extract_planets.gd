extends SceneTree
## One-off tool: cuts the 20 planets (5 x 4 grid) out of the planet sheet on the
## Desktop into res://assets/planets/planet_NN.png (row-major, 00-19).
## Run: godot --headless --path . -s tools/extract_planets.gd

const SRC := "C:/Users/ddwig/Desktop/screencaps/planets.webp"
const OUT := "res://assets/planets/"
const COLS := 5
const ROWS := 4
const TOL := 30.0
const RINGED := [9, 16]   # ringed planets keep the flood-fill cut; the rest are masked to a circle

func _initialize() -> void:
	var sheet := Image.load_from_file(SRC)
	sheet.convert(Image.FORMAT_RGBA8)
	var bg := sheet.get_pixel(3, 3)
	print("sheet ", sheet.get_size(), " bg ", bg.to_html(false))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var cw := float(sheet.get_width()) / COLS
	var ch := float(sheet.get_height()) / ROWS
	for r in ROWS:
		for c in COLS:
			# cells overlap a little: some planets poke past their grid cell
			var rect := Rect2i(int(c * cw), int(r * ch), int(cw), int(ch)).grow(24).intersection(Rect2i(Vector2i.ZERO, sheet.get_size()))
			var img := sheet.get_region(rect)
			var original := img.duplicate()
			_clear_background(img, bg)
			_keep_largest(img)
			if not (r * COLS + c) in RINGED:
				_circle_mask(img, original)
			var used := img.get_used_rect()
			img = img.get_region(used.grow(2).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
			var n := r * COLS + c
			img.save_png(OUT + "planet_%02d.png" % n)
			print("planet ", n, " ", img.get_size())
	quit()

func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r8 - b.r8, a.g8 - b.g8, a.b8 - b.b8).length()

## Flood-fill background from the cell edges.
func _clear_background(img: Image, bg: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x]:
			continue
		seen[p.y * w + p.x] = 1
		if _dist(img.get_pixelv(p), bg) > TOL:
			continue
		img.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append(p + Vector2i.RIGHT); stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN); stack.append(p + Vector2i.UP)

## Keep only the planet (largest opaque island); drops bits of neighbours' rings.
func _keep_largest(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var sizes := [0]
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or img.get_pixel(x, y).a == 0.0:
				continue
			var id := sizes.size()
			var count := 0
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = id
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				count += 1
				for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q: Vector2i = p + d
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and label[q.y * w + q.x] == 0 and img.get_pixelv(q).a > 0.0:
						label[q.y * w + q.x] = id
						stack.append(q)
			sizes.append(count)
	var best := 1
	for i in range(1, sizes.size()):
		if sizes[i] > sizes[best]:
			best = i
	for y in h:
		for x in w:
			if label[y * w + x] != best and label[y * w + x] != 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

## Round planets: dark rims can be close to the background colour and get eaten by
## the flood fill, so fit a circle to what's left and keep every original pixel in it.
func _circle_mask(img: Image, original: Image) -> void:
	var used := img.get_used_rect()
	var center := Vector2(used.position) + Vector2(used.size) * 0.5
	var radius := maxf(used.size.x, used.size.y) * 0.5
	# if a side was eaten, the box is short on that side: re-centre on the intact axis
	if used.size.x < used.size.y:
		var eaten_right := img.get_pixel(used.end.x - 2, int(center.y)).a == 0.0
		center.x = used.position.x + radius if eaten_right else used.end.x - radius
	for y in img.get_height():
		for x in img.get_width():
			var inside := Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius
			img.set_pixel(x, y, original.get_pixel(x, y) if inside else Color(0, 0, 0, 0))
