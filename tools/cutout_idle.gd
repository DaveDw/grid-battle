extends SceneTree
## Cut-out idle builder: Claude's version of the method Codex uses for the idle redo
## (kb/protocols/cutout-idle.md). Frame 1 of the source strip is the master. Every other
## frame is the master with whole parts shifted (or turned a few degrees), the 1-3 px seams
## they uncover filled from the neighbouring pixels, and light effects (tint, glints,
## particles, an afterimage) layered on. Parts never change shape.
## The rig is a JSON file: tools/rigs/<faction>/<unit>.json.
## usage: godot --headless --path . -s tools/cutout_idle.gd -- <faction>/<unit> [--grid] [--publish]
##   default    writes art_incoming/claude/<faction>/<unit>_idle.png, _parts.png, _contact.png,
##              _small.png and _check.json
##   --grid     only writes _parts.png (master + part colours + 10/50 px grid + stray blobs)
##   --publish  also writes art_incoming/<faction>/<unit>_idle.png (what import_frames reads)

const N := 8
const PRESETS := {
	"still": [0, 0, 0, 0, 0, 0, 0, 0],
	"breath": [0, 1, 1, 2, 2, 1, 1, 0],
	"dip": [0, 0, 2, 2, 2, 0, 0, 0],
	"float": [0, -1, -3, -4, -4, -3, -1, 0],
	"pulse": [0, 0, 0.35, 0.85, 1, 0.45, 0, 0],
}
const PART_COLOURS := [Color(0.2, 0.85, 0.95), Color(1, 0.72, 0.2), Color(0.85, 0.4, 1),
	Color(1, 0.35, 0.35), Color(0.4, 0.55, 1), Color(1, 1, 0.3), Color(1, 0.5, 0.8)]

var W := 0
var H := 0
var master: Image
var base: Image
var base_off := Vector2i.ZERO
var owner := PackedInt32Array()  # per master pixel: -1 empty, 0 fixed, i + 1 = part i
var parts: Array = []            # {name, z, dx[], dy[], rot[], pivot, bbox}
var report := {}


func _initialize():
	var args := OS.get_cmdline_user_args()
	var unit: String = args[0]
	var rig_path := "res://tools/rigs/%s.json" % unit
	var rig: Variant = JSON.parse_string(FileAccess.get_file_as_string(rig_path))
	if typeof(rig) != TYPE_DICTIONARY:
		push_error("cannot read rig " + rig_path)
		quit(1)
		return
	var out_dir := "res://art_incoming/claude/%s/" % unit.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var stem := out_dir + unit.get_file()
	_load_master(unit, rig)
	_claim_parts(rig)
	_stray_blobs()
	_parts_sheet(stem + "_parts.png")
	if "--grid" in args:
		print("grid sheet: ", ProjectSettings.globalize_path(stem + "_parts.png"))
		quit()
		return
	var frames: Array[Image] = []
	for f in N:
		frames.append(_build_frame(f, rig))
	_checks(frames, rig)
	var strip := Image.create(W * N, H, false, Image.FORMAT_RGBA8)
	for f in N:
		strip.blit_rect(frames[f], Rect2i(0, 0, W, H), Vector2i(f * W, 0))
	strip.save_png(ProjectSettings.globalize_path(stem + "_idle.png"))
	_contact(frames, stem)
	if "--publish" in args:
		strip.save_png(ProjectSettings.globalize_path("res://art_incoming/%s_idle.png" % unit))
		report["published"] = true
	var fa := FileAccess.open(ProjectSettings.globalize_path(stem + "_check.json"), FileAccess.WRITE)
	fa.store_string(JSON.stringify(report, "  "))
	fa.close()
	print(JSON.stringify(report, "  "))
	quit()


# ---------------------------------------------------------------- master and parts

func _load_master(unit: String, rig: Dictionary) -> void:
	var src_path: String = rig.get("source", "res://assets/sprites/%s_idle.png" % unit)
	var strip := Image.load_from_file(ProjectSettings.globalize_path(src_path))
	strip.convert(Image.FORMAT_RGBA8)
	W = strip.get_width() / N
	H = strip.get_height()
	master = strip.get_region(Rect2i(0, 0, W, H))
	var bp := ProjectSettings.globalize_path("res://assets/sprites/%s.png" % unit)
	if FileAccess.file_exists(bp):
		base = Image.load_from_file(bp)
		base.convert(Image.FORMAT_RGBA8)
		var o: Array = rig.get("base_offset", [0, 0])
		base_off = Vector2i(int(o[0]), int(o[1]))
	if rig.get("master", "") == "base":
		master = Image.create(W, H, false, Image.FORMAT_RGBA8)
		master.blit_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), base_off)
	# Clean-up of the master: stray pixels carried over from older art.
	var cleaned := 0
	for c in rig.get("clean", []):
		var m := _shape(c)
		var from_base: bool = c.get("fill", "clear") == "base"
		for i in W * H:
			if not m[i]:
				continue
			var x := i % W
			var y := i / W
			var col := Color(0, 0, 0, 0)
			if from_base and base:
				var b := Vector2i(x, y) - base_off
				if b.x >= 0 and b.y >= 0 and b.x < base.get_width() and b.y < base.get_height():
					col = base.get_pixelv(b)
			master.set_pixel(x, y, col)
			cleaned += 1
	report["master"] = {"source": src_path, "frame_size": [W, H], "cleaned_pixels": cleaned}


func _claim_parts(rig: Dictionary) -> void:
	owner.resize(W * H)
	for i in W * H:
		owner[i] = 0 if master.get_pixel(i % W, i / W).a > 0.0 else -1
	var by_name := {}
	var specs: Array = rig.get("parts", [])
	for pi in specs.size():
		var s: Dictionary = specs[pi]
		var m := _shape(s)
		var box := Rect2i()
		var first := true
		for i in W * H:
			if m[i] and owner[i] == 0:
				owner[i] = pi + 1
				var p := Vector2i(i % W, i / W)
				if first:
					box = Rect2i(p, Vector2i.ONE)
					first = false
				else:
					box = box.expand(p).expand(p + Vector2i.ONE)
		var part := {"name": s.get("name", "part%d" % pi), "z": int(s.get("z", 1)), "bbox": box,
			"dx": _track(s.get("dx", "still")), "dy": _track(s.get("dy", "still")),
			"rot": _track(s.get("rot", "still")), "rigid": bool(s.get("rigid", true))}
		var pv: Array = s.get("pivot", [box.get_center().x, box.get_center().y])
		part["pivot"] = Vector2(float(pv[0]), float(pv[1]))
		by_name[part.name] = part
		parts.append(part)
		if first:
			push_warning("part %s claims no pixels" % part.name)
	# Second pass, since small parts are listed (and claim pixels) before the part they ride on:
	# copy the lead part's motion, optionally some frames later, and add our own on top.
	for pi in specs.size():
		var s: Dictionary = specs[pi]
		if not s.has("follow"):
			continue
		var part: Dictionary = parts[pi]
		var lead: Dictionary = by_name[s.follow]
		var delay := int(s.get("delay", 0))
		for k in ["dx", "dy", "rot"]:
			var own: Array = part[k]
			var src: Array = lead[k]
			var t := []
			for f in N:
				t.append(float(src[(f - delay + N) % N]) + float(own[f]))
			part[k] = t


func _track(v: Variant) -> Array:
	if typeof(v) == TYPE_STRING:
		return PRESETS[v].duplicate()
	var a: Array = v
	assert(a.size() == N, "motion tracks need 8 values")
	return a.duplicate()


# A shape is any mix of "rect" [x0,y0,x1,y1] (end exclusive), "rects", "poly" [[x,y],...],
# "polys", "circle" [cx,cy,r]; no region means the whole frame. "select" keeps only pixels of
# one colour family; "minus" cuts out another shape.
func _shape(s: Dictionary) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(W * H)
	var any := false
	var rects: Array = s.get("rects", [])
	if s.has("rect"):
		rects = rects + [s.rect]
	for r in rects:
		for y in range(maxi(0, int(r[1])), mini(H, int(r[3]))):
			for x in range(maxi(0, int(r[0])), mini(W, int(r[2]))):
				m[y * W + x] = 1
		any = true
	var polys: Array = s.get("polys", [])
	if s.has("poly"):
		polys = polys + [s.poly]
	for p in polys:
		var pts := PackedVector2Array()
		for q in p:
			pts.append(Vector2(float(q[0]), float(q[1])))
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		for y in range(maxi(0, int(box.position.y)), mini(H, int(box.end.y) + 1)):
			for x in range(maxi(0, int(box.position.x)), mini(W, int(box.end.x) + 1)):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
					m[y * W + x] = 1
		any = true
	if s.has("circle"):
		var c: Array = s.circle
		var r := float(c[2])
		for y in range(maxi(0, int(c[1] - r)), mini(H, int(c[1] + r) + 1)):
			for x in range(maxi(0, int(c[0] - r)), mini(W, int(c[0] + r) + 1)):
				if Vector2(x + 0.5 - c[0], y + 0.5 - c[1]).length() <= r:
					m[y * W + x] = 1
		any = true
	if not any:
		m.fill(1)
	# "select" is one colour family or a list of them (a pixel may match any).
	var sv: Variant = s.get("select", "any")
	var sels: Array = sv if typeof(sv) == TYPE_ARRAY else [sv]
	for i in W * H:
		if not m[i]:
			continue
		var c := master.get_pixel(i % W, i / W)
		var keep := false
		for sel in sels:
			keep = keep or _select(c, sel)
		if not keep:
			m[i] = 0
	if s.has("minus"):
		var cut := _shape(s.minus)
		for i in W * H:
			if cut[i]:
				m[i] = 0
	return m


func _select(c: Color, sel: String) -> bool:
	if c.a <= 0.0:
		return false
	match sel:
		"cyan": return c.g > 0.24 and c.g > c.r * 1.35 and c.b > c.r * 1.35
		"red": return c.r > 0.18 and c.r > c.g * 1.4 and c.r > c.b * 1.2
		"orange": return c.r > 0.5 and c.r > c.b * 1.6 and c.g > c.b * 1.1
		"yellow": return c.r > 0.55 and c.g > 0.5 and c.b < c.g * 0.7
		"green": return c.g > 0.2 and c.g > c.r * 1.2 and c.g > c.b * 1.1
		"purple": return c.b > 0.2 and c.r > c.g * 1.2 and c.b > c.g * 1.2
		"blue": return c.b > 0.3 and c.b > c.r * 1.4 and c.b > c.g * 1.1
		"bright": return minf(c.r, minf(c.g, c.b)) > 0.45
		"dark": return maxf(c.r, maxf(c.g, c.b)) < 0.25
		"grey": return maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b)) < 0.16
	return true


# ---------------------------------------------------------------- frames

func _build_frame(f: int, rig: Dictionary) -> Image:
	var src := master.duplicate() as Image
	var effects: Array = rig.get("effects", [])
	# Tints change colour only, in master space, so they ride along with their part.
	for e in effects:
		if e.type == "tint":
			_tint(src, e, f)
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var writer := PackedInt32Array()
	writer.resize(W * H)
	writer.fill(-1)
	for e in effects:
		if e.type == "ghost":
			_ghost(out, e, f)
	var layers := [{"id": 0, "z": 0}]
	for i in parts.size():
		layers.append({"id": i + 1, "z": parts[i].z})
	layers.sort_custom(func(a, b): return a.z < b.z or (a.z == b.z and a.id < b.id))
	for l in layers:
		if l.id == 0:
			for i in W * H:
				if owner[i] == 0:
					_put(out, writer, i % W, i / W, src.get_pixel(i % W, i / W), 0)
		else:
			_draw_part(out, writer, src, l.id, f)
	var seams := _fill_seams(out, writer, f)
	for e in effects:
		match e.type:
			"glint": _glint(out, e, f)
			"particles": _particles(out, e, f)
	report["frame%d" % (f + 1)] = {"seam_pixels": seams}
	return out


func _offset(p: Dictionary, f: int) -> Vector2i:
	return Vector2i(roundi(float(p.dx[f])), roundi(float(p.dy[f])))


func _draw_part(out: Image, writer: PackedInt32Array, src: Image, id: int, f: int) -> void:
	var p: Dictionary = parts[id - 1]
	var d := _offset(p, f)
	var rot := float(p.rot[f])
	var box: Rect2i = p.bbox
	var pad := 2 + int(ceil(absf(deg_to_rad(rot)) * maxf(box.size.x, box.size.y)))
	var area := box.grow(pad)
	area.position += d
	area = area.intersection(Rect2i(0, 0, W, H))
	var piv: Vector2 = p.pivot
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var sx := x - d.x
			var sy := y - d.y
			if rot != 0.0:
				# Inverse-map so a turned part keeps its own pixels (nearest neighbour).
				var v := (Vector2(sx, sy) - piv).rotated(deg_to_rad(-rot)) + piv
				sx = roundi(v.x)
				sy = roundi(v.y)
			if sx < 0 or sy < 0 or sx >= W or sy >= H or owner[sy * W + sx] != id:
				continue
			_put(out, writer, x, y, src.get_pixel(sx, sy), id)


func _put(out: Image, writer: PackedInt32Array, x: int, y: int, c: Color, id: int) -> void:
	if c.a <= 0.0:
		return
	out.set_pixel(x, y, c if c.a >= 0.999 else out.get_pixel(x, y).blend(c))
	writer[y * W + x] = id


# A pixel a moved part left empty is filled from the nearest opaque pixel within 3 px on the
# side the part moved away from (that extends the fixed joint behind it). Pixels with nothing
# there, like the space above a dipping head, stay transparent.
func _fill_seams(out: Image, writer: PackedInt32Array, f: int) -> int:
	var filled := 0
	var holes: Array[Vector2i] = []
	for i in W * H:
		var id := owner[i]
		if id <= 0 or writer[i] != -1:
			continue
		holes.append(Vector2i(i % W, i / W))
	for h in holes:
		var p: Dictionary = parts[owner[h.y * W + h.x] - 1]
		var d := _offset(p, f)
		var dirs: Array[Vector2i] = []
		if d.y != 0:
			dirs.append(Vector2i(0, -signi(d.y)))
		if d.x != 0:
			dirs.append(Vector2i(-signi(d.x), 0))
		if float(p.rot[f]) != 0.0:
			dirs.append_array([Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)])
		for dir in dirs:
			var done := false
			for k in range(1, 4):
				var q := h + dir * k
				if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H:
					break
				if writer[q.y * W + q.x] != -1:
					out.set_pixelv(h, out.get_pixelv(q))
					filled += 1
					done = true
					break
			if done:
				break
	return filled


# ---------------------------------------------------------------- effects

func _amount(e: Dictionary, f: int) -> float:
	var a: Array = _track(e.get("amount", "pulse"))
	return float(a[f])


func _rgb(v: Variant) -> Color:
	var a: Array = v
	return Color8(int(a[0]), int(a[1]), int(a[2]))


# tint: lerp the selected pixels toward "color" by amount[f] (glow up), and/or multiply by
# mul[f] (dim, or 0.05 to blink a light off).
func _tint(img: Image, e: Dictionary, f: int) -> void:
	var m := _shape(e.get("shape", {}))
	var amt := _amount(e, f) if e.has("color") else 0.0
	var mul := 1.0
	if e.has("mul"):
		var mt: Array = _track(e.mul)
		mul = float(mt[f])
	if amt == 0.0 and mul == 1.0:
		return
	var col := _rgb(e.get("color", [255, 255, 255]))
	for i in W * H:
		if not m[i]:
			continue
		var c := img.get_pixel(i % W, i / W)
		var r := Color(c.r * mul, c.g * mul, c.b * mul, c.a).lerp(Color(col, c.a), amt)
		img.set_pixel(i % W, i / W, r)


# glint: a small bright plus-shaped sparkle at "at", following "part", alpha = amount[f].
func _glint(out: Image, e: Dictionary, f: int) -> void:
	var a := _amount(e, f)
	if a <= 0.0:
		return
	var at: Array = e.at
	var pos := Vector2i(int(at[0]), int(at[1]))
	if e.has("part"):
		for p in parts:
			if p.name == e.part:
				pos += _offset(p, f)
	var s := int(e.get("size", 4))
	var col := _rgb(e.get("color", [255, 255, 255]))
	for k in range(-s, s + 1):
		var fade := 1.0 - absf(k) / float(s + 1)
		for q in [pos + Vector2i(k, 0), pos + Vector2i(0, k)]:
			if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H:
				out.set_pixelv(q, out.get_pixelv(q).blend(Color(col, a * fade)))
	for q in [pos, pos + Vector2i(1, 0), pos + Vector2i(0, 1), pos + Vector2i(1, 1)]:
		if q.x < W and q.y < H:
			out.set_pixelv(q, out.get_pixelv(q).blend(Color(col, a)))


# particles: square specks that start inside "rect" between frames "from".."to" (1-based),
# rise "rise" px per frame with a little sideways drift, and fade out. Seeded, so every run
# is identical, and all are gone by frame 8 so the loop is clean.
func _particles(out: Image, e: Dictionary, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(e.get("seed", 1))
	var r: Array = e.rect
	var span: Array = e.get("frames", [2, 7])
	var life := int(e.get("life", 4))
	var col := _rgb(e.get("color", [255, 200, 120]))
	var size := int(e.get("size", 3))
	for n in int(e.get("count", 6)):
		var start := rng.randi_range(int(span[0]) - 1, maxi(int(span[0]) - 1, int(span[1]) - life))
		var x0 := rng.randf_range(float(r[0]), float(r[2]))
		var y0 := rng.randf_range(float(r[1]), float(r[3]))
		var drift := rng.randf_range(-1.0, 1.0) * float(e.get("drift", 1))
		var age := f - start
		if age < 0 or age >= life:
			continue
		var a := 1.0 - float(age) / life
		var p := Vector2i(roundi(x0 + drift * age), roundi(y0 - float(e.get("rise", 4)) * age))
		for yy in size:
			for xx in size:
				var q := p + Vector2i(xx, yy)
				if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H:
					out.set_pixelv(q, out.get_pixelv(q).blend(Color(col, a)))


# ghost: a translucent tinted copy of the whole master, drawn behind the unit at dx/dy[f]
# with alpha amount[f] (Parallax's afterimage).
func _ghost(out: Image, e: Dictionary, f: int) -> void:
	var a := _amount(e, f) * float(e.get("opacity", 0.35))
	if a <= 0.0:
		return
	var d := Vector2i(roundi(float(_track(e.get("dx", "still"))[f])), roundi(float(_track(e.get("dy", "still"))[f])))
	var col := _rgb(e.get("color", [120, 170, 255]))
	for y in H:
		for x in W:
			var c := master.get_pixel(x, y)
			var q := Vector2i(x, y) + d
			if c.a > 0.0 and q.x >= 0 and q.y >= 0 and q.x < W and q.y < H:
				out.set_pixelv(q, out.get_pixelv(q).blend(Color(c.lerp(col, 0.6), c.a * a)))


# ---------------------------------------------------------------- checks and sheets

func _checks(frames: Array[Image], rig: Dictionary) -> void:
	var problems: Array = []
	var f1_same := frames[0].get_data() == master.get_data()
	if not f1_same:
		problems.append("frame 1 differs from the master (fine only if a part is offset on frame 1)")
	var feet_y := int(rig.get("feet_y", -1))
	if feet_y >= 0:
		for f in N:
			var bad := 0
			for y in range(feet_y, H):
				for x in W:
					if frames[f].get_pixel(x, y) != master.get_pixel(x, y):
						bad += 1
			if bad:
				problems.append("frame %d: %d pixels changed below feet_y %d" % [f + 1, bad, feet_y])
	var motion := {}
	for p in parts:
		var biggest := 0
		for f in N:
			var d := _offset(p, f)
			biggest = maxi(biggest, maxi(absi(d.x), absi(d.y)))
			var nxt := _offset(p, (f + 1) % N)
			if maxi(absi(nxt.x - d.x), absi(nxt.y - d.y)) > 2:
				problems.append("%s jumps %s px between frames %d and %d" % [p.name, nxt - d, f + 1, (f + 1) % N + 1])
			if absf(float(p.rot[f])) > 6.0:
				problems.append("%s turns %s deg on frame %d (brief allows 4)" % [p.name, p.rot[f], f + 1])
		motion[p.name] = {"max_shift_px": biggest, "dy": p.dy, "dx": p.dx, "rot": p.rot}
	report["motion"] = motion
	report["frame_1_is_master"] = f1_same
	report["problems"] = problems


# Small opaque islands not joined to the unit: usually particles frozen from older art.
func _stray_blobs() -> void:
	var seen := PackedByteArray()
	seen.resize(W * H)
	var blobs: Array = []
	for i in W * H:
		if seen[i] or master.get_pixel(i % W, i / W).a <= 0.1:
			continue
		var stack := [i]
		seen[i] = 1
		var count := 0
		var box := Rect2i(i % W, i / W, 1, 1)
		while stack:
			var j: int = stack.pop_back()
			count += 1
			var p := Vector2i(j % W, j / W)
			box = box.expand(p).expand(p + Vector2i.ONE)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + d
				if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H:
					continue
				var k := q.y * W + q.x
				if not seen[k] and master.get_pixel(q.x, q.y).a > 0.1:
					seen[k] = 1
					stack.append(k)
		if count < 150:
			blobs.append({"px": count, "rect": [box.position.x, box.position.y, box.end.x, box.end.y]})
	report["stray_blobs"] = blobs
	if blobs.size():
		push_warning("%d small detached blobs in the master; check _parts.png (red boxes) and clean them if they are leftovers" % blobs.size())


func _parts_sheet(path: String) -> void:
	var sheet := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.14, 0.17))
	var tinted := Image.create(W, H, false, Image.FORMAT_RGBA8)
	tinted.fill(Color(0.12, 0.14, 0.17))
	for i in W * H:
		var c := master.get_pixel(i % W, i / W)
		if owner[i] > 0:
			c = Color(c.lerp(PART_COLOURS[(owner[i] - 1) % PART_COLOURS.size()], 0.55), c.a)
		elif owner[i] == 0:
			c = Color(c.lerp(Color(0.3, 0.9, 0.4), 0.3), c.a)
		tinted.set_pixel(i % W, i / W, Color(0.12, 0.14, 0.17).blend(c))
	sheet.blend_rect(master, Rect2i(0, 0, W, H), Vector2i.ZERO)
	sheet.blit_rect(tinted, Rect2i(0, 0, W, H), Vector2i(W, 0))
	# Grid: faint every 10 px, bright every 50, red every 100, so polygons can be read off.
	for side in 2:
		for x in range(0, W, 10):
			var c := Color(1, 0.2, 0.2, 0.7) if x % 100 == 0 else (Color(1, 1, 1, 0.35) if x % 50 == 0 else Color(1, 1, 1, 0.1))
			for y in H:
				var q := Vector2i(side * W + x, y)
				sheet.set_pixelv(q, sheet.get_pixelv(q).blend(c))
		for y in range(0, H, 10):
			var c := Color(1, 0.2, 0.2, 0.7) if y % 100 == 0 else (Color(1, 1, 1, 0.35) if y % 50 == 0 else Color(1, 1, 1, 0.1))
			for x in W:
				var q := Vector2i(side * W + x, y)
				sheet.set_pixelv(q, sheet.get_pixelv(q).blend(c))
	for b in report.get("stray_blobs", []):
		var r: Array = b.rect
		for x in range(int(r[0]) - 2, int(r[2]) + 2):
			for y in [int(r[1]) - 2, int(r[3]) + 1]:
				if x >= 0 and y >= 0 and x < W and y < H:
					sheet.set_pixel(x, y, Color.RED)
		for y in range(int(r[1]) - 2, int(r[3]) + 2):
			for x in [int(r[0]) - 2, int(r[2]) + 1]:
				if x >= 0 and y >= 0 and x < W and y < H:
					sheet.set_pixel(x, y, Color.RED)
	sheet.save_png(ProjectSettings.globalize_path(path))


func _contact(frames: Array[Image], stem: String) -> void:
	var bg := Color(0.12, 0.14, 0.17)
	var sheet := Image.create(W * 4, H * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(bg)
	for f in N:
		sheet.blend_rect(frames[f], Rect2i(0, 0, W, H), Vector2i(f % 4 * W, f / 4 * H))
	sheet.save_png(ProjectSettings.globalize_path(stem + "_contact.png"))
	# Game size: units render at about 0.37, so the beat must read here.
	var sw := roundi(W * 0.37)
	var sh := roundi(H * 0.37)
	var small := Image.create(sw * N, sh, false, Image.FORMAT_RGBA8)
	small.fill(bg)
	for f in N:
		var s := frames[f].duplicate() as Image
		s.resize(sw, sh, Image.INTERPOLATE_BILINEAR)
		small.blend_rect(s, Rect2i(0, 0, sw, sh), Vector2i(f * sw, 0))
	small.save_png(ProjectSettings.globalize_path(stem + "_small.png"))
