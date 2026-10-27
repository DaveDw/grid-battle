extends SceneTree
## Contact sheet for reviewing animation art: one row per unit that has frames,
## showing idle frames 1, 3, 5, 7, both attack frames and the four move poses, each
## scaled to ROW_H. Writes screenshots/frames_preview.png.
##   godot --headless --path . -s tools/frames_preview.gd

const ROW_H := 96
const CELL_W := 110

func _initialize() -> void:
	var rows: Array = []
	for f in ["terran", "ascendancy", "manyworlds", "long"]:
		for file in DirAccess.get_files_at("res://assets/sprites/" + f):
			if file.ends_with("_idle.png"):
				rows.append(f + "/" + file.trim_suffix("_idle.png"))
	var cols := 4 + 2 + 4
	var sheet := Image.create(CELL_W * cols + 150, ROW_H * maxi(rows.size(), 1), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.13, 0.17))
	for r in rows.size():
		var u: String = rows[r]
		var cells: Array = []
		var idle := _img("res://assets/sprites/%s_idle.png" % u)
		for i in [0, 2, 4, 6]:
			cells.append(_cell(idle, 8, i))
		var atk := _img("res://assets/sprites/%s_attack.png" % u)
		for i in 2:
			cells.append(_cell(atk, 2, i))
		for d in ["up", "down", "fwd", "back"]:
			cells.append(_cell(_img("res://assets/sprites/%s_move_%s.png" % [u, d]), 1, 0))
		for c in cells.size():
			var img: Image = cells[c]
			if img == null:
				continue
			var s := float(ROW_H - 4) / img.get_height()
			img.resize(maxi(1, int(img.get_width() * s)), ROW_H - 4, Image.INTERPOLATE_NEAREST)
			var w := mini(img.get_width(), CELL_W - 4)
			sheet.blend_rect(img, Rect2i((img.get_width() - w) / 2, 0, w, img.get_height()), Vector2i(150 + c * CELL_W + 2, r * ROW_H + 2))
		# a light rule between rows, and a tint band so each unit's row reads apart
		sheet.fill_rect(Rect2i(0, r * ROW_H, 146, ROW_H - 1), Color(0.2, 0.22, 0.3) if r % 2 == 0 else Color(0.17, 0.19, 0.26))
	sheet.save_png(ProjectSettings.globalize_path("res://screenshots/frames_preview.png"))
	print("preview: %d units" % rows.size())
	for r in rows.size():
		print("  row %d: %s" % [r + 1, rows[r]])
	quit()

func _img(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img

func _cell(img: Image, n: int, i: int) -> Image:
	if img == null:
		return null
	var w := img.get_width() / n
	return img.get_region(Rect2i(i * w, 0, w, img.get_height()))
