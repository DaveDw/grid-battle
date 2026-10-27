extends SceneTree
## One-off tool: cuts the characters out of the faction sheets on the Desktop into
## transparent PNGs under res://assets/sprites/<faction>/<name>.png.
## Run: godot --headless --path . -s tools/extract_sprites.gd

const SRC := "C:/Users/ddwig/Desktop/screencaps/faction-sprites/"
const OUT := "res://assets/sprites/"
const TOL := 26.0      # max RGB distance from the sheet background that counts as background
const FRINGE := 48.0   # looser distance for the 1px edge cleanup pass
const INSET := 6

# Banner sheets: six cells in a row. x = cell borders, tops = where the art starts in
# the first two cells (under the faction title) and in the rest, bottom = name bar.
const BANNERS := {
	"terran-partition-authority.png": {"faction": "terran", "x": [13, 354, 675, 1086, 1468, 1827, 2159], "tops": [196, 146], "bottom": 522, "bg": Color8(0, 23, 52),
		"names": ["pathfinder", "standard_guard", "breacher", "siege_rig", "banner_marshal", "claim_lord"]},
	"ascendancy-league.png": {"faction": "ascendancy", "x": [13, 354, 675, 1086, 1468, 1827, 2159], "tops": [196, 146], "bottom": 536, "bg": Color8(0, 23, 52),
		"names": ["field_scholar", "courtesy_android", "protocol_warden", "synapse_brute", "chief_visionary", "director_zero"]},
	"manyworlds-resistance.png": {"faction": "manyworlds", "x": [13, 354, 675, 1086, 1468, 1827, 2159], "tops": [196, 146], "bottom": 536, "bg": Color8(0, 23, 52),
		"names": ["reed_runner", "glasswing", "reef_bulwark", "spore_keeper", "tide_speaker", "prism_elder"]},
	# v2 Long Tomorrow sheet (2000x667), redrawn to match the other factions
	"the-long-tomorrow-v2.webp": {"faction": "long", "x": [10, 326, 625, 1000, 1298, 1625, 1990], "tops": [126, 74], "bottom": 547, "bg": Color8(1, 27, 52), "holes": true,
		"names": ["cinder_scout", "parallax", "red_giant", "deadweight", "mission_mother", "captain_everafter"]},
}

func _initialize() -> void:
	for sheet in BANNERS:
		var img := Image.load_from_file(SRC + sheet)
		var info: Dictionary = BANNERS[sheet]
		var xs: Array = info["x"]
		for i in 6:
			# the faction title runs across the first two cells, so start below it
			var top: int = info["tops"][0] if i < 2 else info["tops"][1]
			var r := Rect2i(xs[i] + INSET, top, xs[i + 1] - xs[i] - INSET * 2, info["bottom"] - top)
			_cut(img, r, info["faction"], info["names"][i], info["bg"], info.get("holes", false))
	quit()

func _dist(a: Color, b: Color) -> float:
	return Vector3(a.r8 - b.r8, a.g8 - b.g8, a.b8 - b.b8).length()

func _cut(sheet: Image, r: Rect2i, faction: String, name: String, bg: Color, holes := false) -> void:
	var img := sheet.get_region(r)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
	# flood-fill background inward from the cell edges, so dark pixels inside the art survive
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var k := p.y * w + p.x
		if seen[k]:
			continue
		seen[k] = 1
		if _dist(img.get_pixelv(p), bg) > TOL:
			continue
		img.set_pixelv(p, Color(0, 0, 0, 0))
		stack.append(p + Vector2i.RIGHT); stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN); stack.append(p + Vector2i.UP)
	# fringe pass: near-background pixels touching transparency
	var fringe: Array[Vector2i] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and _dist(c, bg) < FRINGE:
				for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					if img.get_pixelv(Vector2i(x, y) + d).a == 0.0:
						fringe.append(Vector2i(x, y)); break
	for p in fringe:
		img.set_pixelv(p, Color(0, 0, 0, 0))
	if holes:
		_clear_holes(img, bg)
	_drop_strays(img)
	var used := img.get_used_rect()
	img = img.get_region(used.grow(2).intersection(Rect2i(0, 0, w, h)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + faction))
	img.save_png(OUT + faction + "/" + name + ".png")
	print("cut ", faction, "/", name, " ", img.get_size())

## Removes leftovers from the sheet frame: opaque islands that touch the cell edge
## (grid lines, bits of the faction logo) unless they are the character itself
## (largest island), plus specks under 12 px.
func _drop_strays(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var comps: Array = []  # [pixels: Array[Vector2i], touches_edge: bool]
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or img.get_pixel(x, y).a == 0.0:
				continue
			var pix: Array[Vector2i] = []
			var edge := false
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = comps.size() + 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				pix.append(p)
				if p.x == 0 or p.y == 0 or p.x == w - 1 or p.y == h - 1:
					edge = true
				for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
						continue
					if label[q.y * w + q.x] == 0 and img.get_pixelv(q).a > 0.0:
						label[q.y * w + q.x] = comps.size() + 1
						stack.append(q)
			comps.append([pix, edge])
	var biggest := 0
	for i in comps.size():
		if comps[i][0].size() > comps[biggest][0].size():
			biggest = i
	for i in comps.size():
		if i != biggest and (comps[i][1] or comps[i][0].size() < 12):
			for p in comps[i][0]:
				img.set_pixelv(p, Color(0, 0, 0, 0))

## Background trapped inside the art (e.g. between legs and the ground shadow): clear
## any enclosed patch of background colour bigger than HOLE_MIN pixels.
const HOLE_MIN := 120

func _clear_holes(img: Image, bg: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if seen[y * w + x] or c.a == 0.0 or _dist(c, bg) > TOL:
				continue
			var patch: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				patch.append(p)
				for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q: Vector2i = p + d
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and not seen[q.y * w + q.x]:
						var qc := img.get_pixelv(q)
						if qc.a > 0.0 and _dist(qc, bg) <= TOL:
							seen[q.y * w + q.x] = 1
							stack.append(q)
			if patch.size() >= HOLE_MIN:
				for p in patch:
					img.set_pixelv(p, Color(0, 0, 0, 0))
