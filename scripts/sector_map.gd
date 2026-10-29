extends Control
## Sector map: the sectors claimed so far, and a choice of 2-3 sectors to take next,
## each with a modifier. The column where the run is won is marked (unless the run
## has gone on to Infinity and Beyond). Choosing a sector starts its first battle.

const COL_W := 190.0
const ROW_H := 78.0
const MAP_Y := 270.0
const SHOWN := 6                # columns visible at once

var _map: Control
var _focus := 0
var _options: Array = []

func _ready() -> void:
	if Game.run.is_empty() or Game.run.get("phase") != "map":
		Game.go("res://scenes/main_menu.tscn" if Game.run.is_empty() else Game.resume_scene())
		return
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(0.35, 0.55, 1.0)))
	var title := _label(Vector2(0, 26), 40, Color.WHITE)
	title.text = "SECTOR MAP"
	var sub := _label(Vector2(0, 80), 17, Color(0.6, 0.75, 0.95))
	if Game.run.get("infinite", false):
		sub.text = "INFINITY AND BEYOND  ·  %d sectors claimed" % Game.sectors_claimed()
		sub.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	else:
		sub.text = "Claim %d sectors to win  ·  %d claimed" % [Game.sectors_to_win(), Game.sectors_claimed()]
	if int(Game.run.get("ng", 0)) > 0:
		sub.text = "NEW GAME+%d  ·  " % int(Game.run["ng"]) + sub.text
	_map = Control.new()
	_map.position = Vector2(0, 0)
	_map.size = Vector2(1280, 420)
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.draw.connect(_draw_map)
	add_child(_map)
	var faces := _label(Vector2(40, 404), 13, Color(0.7, 0.78, 0.9))
	faces.size = Vector2(1200, 40)   # wraps to two lines when the faction names are long
	faces.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var names := []
	for f in Game.run["order"]:
		names.append(Game.FACTIONS[f]["name"])
	faces.text = "Sector %d: you face %s, in that order. Choose its conditions:" % [int(Game.run["sector"]), ", then ".join(names)]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.position = Vector2(0, 450)
	row.custom_minimum_size = Vector2(1280, 0)
	add_child(row)
	var col: Array = Game.run["map"][int(Game.run["sector"]) - 1]
	for i in col.size():
		var m: Dictionary = Game.SECTOR_MODS[col[i]["mod"]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(340, 150)
		b.focus_entered.connect(func():
			_focus = i
			_map.queue_redraw())
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_choose.bind(i))
		var pic := TextureRect.new()
		pic.texture = _planet(int(Game.run["sector"]) - 1, i)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(12, 35)
		pic.size = Vector2(80, 80)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pic)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 104
		v.offset_right = -16
		v.offset_top = 14
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var n := Label.new()
		n.text = m["name"]
		n.add_theme_font_override("font", Game.FONT_HEAD)   # narrow header font so long names fit
		n.add_theme_font_size_override("font_size", 24)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD
		v.add_child(n)
		var t := Label.new()
		t.text = m["text"]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD
		t.add_theme_font_size_override("font_size", 12)
		t.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
		v.add_child(t)
		row.add_child(b)
		_options.append(b)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	bar.position = Vector2(0, 630)
	var tip := _label(Vector2(0, 690), 13, Color(0.55, 0.62, 0.75))
	tip.text = Game.random_tip()
	bar.custom_minimum_size = Vector2(1280, 0)
	add_child(bar)
	var view := Button.new()
	view.text = "View Deck"
	view.custom_minimum_size = Vector2(180, 44)
	view.pressed.connect(func():
		var d := DeckView.new()
		d.title = "YOUR DECK"
		d.groups = [["Deck", Game.run["deck"]]]
		add_child(d)
		d.closed.connect(func(): _options[_focus].grab_focus()))
	bar.add_child(view)
	var quit := Button.new()
	quit.text = "Save & Quit"
	quit.custom_minimum_size = Vector2(180, 44)
	quit.pressed.connect(func():
		Game.save_run()
		Game.run = {}
		Game.go("res://scenes/main_menu.tscn"))
	bar.add_child(quit)
	_options[0].grab_focus()

func _label(pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(1280, size + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if size >= 24:
		l.add_theme_font_override("font", Game.FONT_HEAD)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _choose(i: int) -> void:
	Game.choose_sector(i)
	Game.go("res://scenes/main.tscn")

func _node_pos(k: int, j: int, n: int, first: int) -> Vector2:
	# centre the visible columns horizontally
	var shown := mini(Game.run["map"].size() - first, SHOWN)
	var x0 := 640.0 - (shown - 1) * COL_W * 0.5
	return Vector2(x0 + (k - first) * COL_W, MAP_Y + (j - (n - 1) / 2.0) * ROW_H)

## The map: claimed path in the player's faction colour, this sector's choices, and
## a dim look ahead. Columns scroll so the current one stays in view.
func _draw_map() -> void:
	var font := ThemeDB.fallback_font
	var map: Array = Game.run["map"]
	var path: Array = Game.run["path"]
	var cur := int(Game.run["sector"]) - 1
	var first := maxi(0, cur - 3)
	var mine: Color = Game.FACTIONS[Game.leader_by_id(Game.run["leader"])["faction"]]["color"]
	var goal := Game.sectors_to_win() - 1
	var last := mini(map.size(), first + SHOWN)
	for k in range(first, last):
		var col: Array = map[k]
		# links to the next column
		if k + 1 < last:
			var nxt: Array = map[k + 1]
			for j in col.size():
				for j2 in nxt.size():
					var on_path := k < path.size() and int(path[k]) == j and k + 1 < path.size() and int(path[k + 1]) == j2
					var from_claimed := k < path.size() and int(path[k]) == j and k + 1 == cur
					var c := Color(mine, 0.9) if on_path else (Color(1, 1, 1, 0.35) if from_claimed else Color(1, 1, 1, 0.08))
					_map.draw_line(_node_pos(k, j, col.size(), first), _node_pos(k + 1, j2, nxt.size(), first), c, 3.0 if on_path else 1.5)
		var label := "SECTOR %d" % (k + 1)
		_map.draw_string(font, Vector2(_node_pos(k, 0, 1, first).x - 70, MAP_Y - 140), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 13,
			Color(0.9, 0.9, 1.0, 0.9) if k == cur else Color(0.6, 0.65, 0.8, 0.6))
		if k == goal and not Game.run.get("infinite", false):
			_map.draw_string(font, Vector2(_node_pos(k, 0, 1, first).x - 90, MAP_Y - 122), "★ CLAIM TO WIN", HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(1.0, 0.85, 0.4))
		for j in col.size():
			var p := _node_pos(k, j, col.size(), first)
			var m: String = col[j]["mod"]
			var tex := _planet(k, j)
			if k < cur:
				var picked := k < path.size() and int(path[k]) == j
				if picked:
					# claimed: a ring in your faction colour and your flag planted on top
					_map.draw_arc(p, 25.0, 0, TAU, 32, mine, 3.0)
					_draw_planet(tex, p, 40.0, Color.WHITE)
					var top := p + Vector2(4, -14)
					_map.draw_line(top + Vector2(0, 10), top + Vector2(0, -14), Color.WHITE, 2.0)
					_map.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -14), top + Vector2(14, -9), top + Vector2(0, -4)]), mine)
				else:
					_draw_planet(tex, p, 30.0, Color(0.45, 0.45, 0.55, 0.5))
			elif k == cur:
				var lit := j == _focus
				var size := 58.0 if lit else 46.0
				_map.draw_arc(p, size * 0.5 + 6.0, 0, TAU, 40, Color(1.0, 0.85, 0.3) if lit else Color(0.6, 0.85, 1.0, 0.7), 3.0 if lit else 2.0)
				_draw_planet(tex, p, size, Color.WHITE)
			else:
				_draw_planet(tex, p, 32.0, Color(0.7, 0.72, 0.85, 0.7))
			_map.draw_string(Game.FONT_HEAD, p + Vector2(-70, 46), Game.SECTOR_MODS[m]["name"], HORIZONTAL_ALIGNMENT_CENTER, 140, 16,
				Color(0.85, 0.9, 1.0, 0.95 if k == cur else 0.5))

var _planets := {}

func _planet(k: int, j: int) -> Texture2D:
	var n := Game.node_planet(k, j)
	if not _planets.has(n):
		_planets[n] = load("res://assets/planets/planet_%02d.png" % n)
	return _planets[n]

## Draw a planet `size` px tall centred on `p` (ringed planets come out wider).
func _draw_planet(tex: Texture2D, p: Vector2, size: float, tint: Color) -> void:
	var s := size / tex.get_height()
	var w := tex.get_width() * s
	_map.draw_texture_rect(tex, Rect2(p.x - w * 0.5, p.y - size * 0.5, w, size), false, tint)
