extends SceneTree
## Turns generated animation art into game-ready frame sheets.
##   godot --headless --path . -s tools/import_frames.gd [-- terran/pathfinder ...]
## Reads art_incoming/<faction>/<unit>_idle.png (8 cells in a row), _attack.png (2 cells)
## and _move_up/_down/_fwd/_back.png (1 cell each), drawn on flat magenta (#FF00FF).
## For each unit it:
##   - keys out the magenta (and the pink fringe around it),
##   - cuts each strip into its cells,
##   - finds each frame's feet (bottom of the art, centre of its lowest rows),
##   - scales everything by one factor so the idle pose matches the height of the
##     existing cut-out sprite (pixel art stays crisp: nearest-neighbour),
##   - writes every frame into one shared cell size with the feet at bottom centre,
## and saves assets/sprites/<faction>/<unit>_idle.png, _attack.png, _move_<dir>.png.
## With no unit arguments it imports every unit that has an _idle.png waiting.

const CELLS := {"idle": 8, "attack": 2, "move_up": 1, "move_down": 1, "move_fwd": 1, "move_back": 1}
const MARGIN := 4
const DASH_HEIGHT := 0.9      # a dash pose is crouched: this much of the standing height

func _initialize() -> void:
	var units: Array = []
	for a in OS.get_cmdline_user_args():
		units.append(a)
	if units.is_empty():
		for f in DirAccess.get_directories_at("res://art_incoming"):
			for file in DirAccess.get_files_at("res://art_incoming/" + f):
				if file.ends_with("_idle.png"):
					units.append(f + "/" + file.trim_suffix("_idle.png"))
	for u in units:
		_import(u)
	quit()

func _load(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img

## Magenta (and anti-aliased pink edges) -> transparent.
func _key(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var pink := minf(c.r, c.b) - c.g          # high for magenta-ish pixels
			if pink > 0.45:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif pink > 0.25:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * (0.45 - pink) / 0.2))

## Bounds of the art, ignoring stray specks the generator leaves on the background:
## only rows/columns with a few opaque pixels count, and the box is the largest
## contiguous run of them (so a lone speck far away can't stretch it).
func _bbox(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var rows := PackedInt32Array()
	rows.resize(h)
	var cols := PackedInt32Array()
	cols.resize(w)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				rows[y] += 1
				cols[x] += 1
	var ry := _span(rows, 3)
	var rx := _span(cols, 3)
	return Rect2i(rx.x, ry.x, rx.y - rx.x, ry.y - ry.x)

## Clear detached bits (slivers of the neighbouring cell, generator specks): any
## connected blob smaller than 3% of the largest one. Muzzle sparks near the gun
## survive because they're within GAP px of the body.
const GAP := 4
func _drop_fragments(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var sizes: Array = []
	for start in w * h:
		if label[start] >= 0 or img.get_pixel(start % w, start / w).a <= 0.3:
			continue
		var id := sizes.size()
		var stack := [start]
		label[start] = id
		var n := 0
		while not stack.is_empty():
			var p: int = stack.pop_back()
			n += 1
			var px := p % w
			var py := p / w
			for dy in range(-GAP, GAP + 1):
				for dx in range(-GAP, GAP + 1):
					var x := px + dx
					var y := py + dy
					if x < 0 or y < 0 or x >= w or y >= h:
						continue
					var q := y * w + x
					if label[q] < 0 and img.get_pixel(x, y).a > 0.3:
						label[q] = id
						stack.append(q)
		sizes.append(n)
	if sizes.size() < 2:
		return
	# which blobs touch the cell's left/right edge (slivers of the neighbouring frame)
	var edge := {}
	for y in h:
		for x in [0, 1, w - 2, w - 1]:
			var l := label[y * w + x]
			if l >= 0:
				edge[l] = true
	var biggest: int = sizes.max()
	for i in w * h:
		var l := label[i]
		if l < 0:
			continue
		# tiny specks anywhere, or edge slivers that aren't the main body; detached parts
		# that belong to the unit (orbiting drones, sparks, a launched shell) stay
		if sizes[l] < biggest * 0.004 or (edge.has(l) and sizes[l] < biggest * 0.15):
			img.set_pixel(i % w, i / w, Color(0, 0, 0, 0))

## How alive the idle loop is: travel of the top of the art across the cycle (% of
## height) and pixels changed between frame 1 and frame 5 (% of the art). Flags loops
## below the bar (top travel 3%, change 3%), which read as a frozen sprite in game.
func _report_motion(unit: String, sheet: Image, cell: Vector2i) -> void:
	var tops: Array = []
	var frames: Array = []
	for i in IDLE_CELLS:
		var f := sheet.get_region(Rect2i(i * cell.x, 0, cell.x, cell.y))
		frames.append(f)
		tops.append(f.get_used_rect().position.y)
	var h := float(cell.y)
	var travel: float = (tops.max() - tops.min()) / h * 100.0
	var a: Image = frames[0]
	var b: Image = frames[4]
	var solid := 0
	var diff := 0
	for y in cell.y:
		for x in cell.x:
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.a > 0.5 or cb.a > 0.5:
				solid += 1
				if absf(ca.a - cb.a) > 0.5 or Vector3(ca.r - cb.r, ca.g - cb.g, ca.b - cb.b).length() > 0.15:
					diff += 1
	var change := 100.0 * diff / maxf(solid, 1)
	var ok := travel >= 3.0 and change >= 3.0
	print("%s idle motion: top travel %.1f%%, frame1-vs-5 change %.1f%%  %s" % [unit, travel, change, "OK" if ok else "TOO STATIC"])

const IDLE_CELLS := 8

## Muzzle = centre of the muzzle flash in attack frame 1 (bright, warm pixels; the
## right-most cluster wins, since the art faces right). Saved as
## assets/sprites/<unit>_frames.json {"muzzle": [x fraction, y fraction up from the
## feet]} for FighterSprite. If no flash is found nothing is written, and the
## hand-set muzzle in Game.UNITS stays.
## Also records "body_h": the character's standing height in pixels. Cells can be much
## taller or wider than the character (a launched shell, a raised flag, a sword thrust),
## so FighterSprite scales by the body, not the cell, to keep units their usual size.
## Units holding something above their head (a flag) would be measured to its tip and
## drawn too small, so their body height is set by hand: top of the head to the feet.
const BODY_H_OVERRIDES := {"terran/banner_marshal": 258}   # measured on the idle frame

func _save_meta(unit: String, sheet, cell: Vector2i, body_h: int) -> void:
	body_h = BODY_H_OVERRIDES.get(unit, body_h)
	var meta := {"body_h": body_h}
	var pts: Array = []
	if sheet:
		for y in cell.y:
			for x in cell.x:
				var c: Color = sheet.get_pixel(x, y)
				if c.a > 0.5 and c.r > 0.92 and c.g > 0.7 and c.b < 0.75 and c.r + c.g > 1.75:
					pts.append(Vector2(x, y))
	if pts.size() >= 6:
		var max_x: float = pts.map(func(p): return p.x).max()
		var near := pts.filter(func(p): return p.x > max_x - cell.x * 0.12)
		var sum := Vector2.ZERO
		for p in near:
			sum += p
		var m: Vector2 = sum / near.size()
		meta["muzzle"] = [snappedf(m.x / cell.x, 0.001), snappedf((cell.y - m.y) / cell.y, 0.001)]
	else:
		print("%s: no muzzle flash found in attack frame 1" % unit)
	var f := FileAccess.open(ProjectSettings.globalize_path("res://assets/sprites/%s_frames.json" % unit), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta))
	print("%s: meta %s" % [unit, meta])

## Longest run of entries >= `need` (allowing gaps of up to 80, so detached parts like
## orbiting drones count; fragments are already cleared) as [start, end).
func _span(counts: PackedInt32Array, need: int) -> Vector2i:
	var best := Vector2i(0, 0)
	var start := -1
	var last := -1
	for i in counts.size():
		if counts[i] >= need:
			if start < 0 or i - last > 80:
				start = i
			last = i
			if last + 1 - start > best.y - best.x:
				best = Vector2i(start, last + 1)
	return best

## Feet: x centre of the opaque pixels in the lowest 12% of the art, y = bottom row.
func _feet(img: Image, box: Rect2i) -> Vector2:
	var y0 := box.end.y - maxi(2, int(box.size.y * 0.12))
	var sx := 0.0
	var n := 0
	for y in range(y0, box.end.y):
		for x in range(box.position.x, box.end.x):
			if img.get_pixel(x, y).a > 0.5:
				sx += x
				n += 1
	return Vector2(sx / n if n > 0 else box.get_center().x, box.end.y)

func _import(unit: String) -> void:
	var frames := {}          # kind -> [Image...]
	for kind in CELLS:
		var img := _load("res://art_incoming/%s_%s.png" % [unit, kind])
		if img == null:
			continue
		_key(img)
		var n: int = CELLS[kind]
		var cw := img.get_width() / n
		var list: Array = []
		for i in n:
			var cell_img := img.get_region(Rect2i(i * cw, 0, cw, img.get_height()))
			_drop_fragments(cell_img)   # on the whole cell, so neighbour slivers sit at its edges
			list.append(cell_img)
		frames[kind] = list
	if not frames.has("idle"):
		push_error("%s: no idle strip" % unit)
		return
	# The generator draws each image at its own scale, so each strip gets its own
	# factor: standing poses (idle, attack) match the existing sprite's height; dash
	# poses are crouched, so they're set to DASH_HEIGHT of it.
	var still := _load("res://assets/sprites/%s.png" % unit)
	var boxes := {}
	var target_h := 0
	for kind in frames:
		boxes[kind] = frames[kind].map(func(f): return _bbox(f))
	if still:
		target_h = _bbox(still).size.y
	else:
		target_h = boxes["idle"].map(func(b): return b.size.y).max()
	var scales := {}
	for kind in frames:
		var tallest: int = boxes[kind].map(func(b): return b.size.y).max()
		var want := target_h * (DASH_HEIGHT if kind.begins_with("move") else 1.0)
		scales[kind] = want / maxf(tallest, 1.0)

	# measure every frame around its feet, at its strip's scale
	var left := 0.0
	var right := 0.0
	var up := 0.0
	var placed: Array = []    # [kind, index, scaled image, feet]
	for kind in frames:
		var s: float = scales[kind]
		var i := 0
		for f in frames[kind]:
			var box: Rect2i = boxes[kind][i]
			if box.size.x == 0:
				i += 1
				continue
			var crop: Image = f.get_region(box)
			crop.resize(maxi(1, int(round(box.size.x * s))), maxi(1, int(round(box.size.y * s))), Image.INTERPOLATE_NEAREST)
			var feet := (_feet(f, box) - Vector2(box.position)) * s
			left = maxf(left, feet.x)
			right = maxf(right, crop.get_width() - feet.x)
			up = maxf(up, feet.y)
			placed.append([kind, i, crop, feet])
			i += 1
	var half := int(ceil(maxf(left, right))) + MARGIN
	var cell := Vector2i(half * 2, int(ceil(up)) + MARGIN)
	var out := {}
	for kind in frames:
		var sheet := Image.create(cell.x * CELLS[kind], cell.y, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))
		out[kind] = sheet
	for p in placed:
		var crop: Image = p[2]
		var feet: Vector2 = p[3]
		var dst := Vector2i(p[1] * cell.x + half - int(round(feet.x)), cell.y - int(round(feet.y)))
		out[p[0]].blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), dst)
	_report_motion(unit, out["idle"], cell)
	_save_meta(unit, out.get("attack"), cell, target_h)
	for kind in out:
		var path := "res://assets/sprites/%s_%s.png" % [unit, kind]
		out[kind].save_png(ProjectSettings.globalize_path(path))
		print("%s -> %s  (%dx%d)" % [unit, path, out[kind].get_width(), out[kind].get_height()])
