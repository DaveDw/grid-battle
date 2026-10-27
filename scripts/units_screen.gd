extends Control
## Unit roster: all 24 units by faction, each playing its idle animation. Focusing
## one (mouse, keys or controller) shows its kit; pressing it plays its attack.

var _detail: Label
var _name: Label
var _big: FighterSprite
var _first: Button

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(0.4, 0.55, 0.95)))
	var title := Label.new()
	title.text = "UNITS"
	title.add_theme_font_size_override("font_size", 38)
	title.position = Vector2(40, 18)
	add_child(title)
	var y := 78.0
	for fid in Game.FACTIONS:
		var head := Label.new()
		head.text = Game.FACTIONS[fid]["name"].to_upper()
		head.add_theme_font_size_override("font_size", 13)
		head.add_theme_color_override("font_color", Game.FACTIONS[fid]["color"])
		head.position = Vector2(40, y)
		add_child(head)
		var x := 40.0
		for l in Game.LEADERS:
			if l["faction"] != fid:
				continue
			for role in ["leader", "heavy", "light"]:
				var key: String = l[role]
				var b := Button.new()
				b.position = Vector2(x, y + 18)
				b.size = Vector2(110, 112)
				b.focus_entered.connect(_show.bind(key, role))
				b.mouse_entered.connect(b.grab_focus)
				b.pressed.connect(func(): _big.play_attack())
				var s := FighterSprite.new()
				s.sprite_path = "res://assets/sprites/%s.png" % key
				s.height = 84.0
				s.max_width = 100.0
				s.feet_y = 0.0
				s.position = Vector2(55, 100)
				b.add_child(s)
				add_child(b)
				if _first == null:
					_first = b
				x += 116.0
			x += 10.0
		y += 140.0
	var panel := PanelContainer.new()
	panel.position = Vector2(830, 70)
	panel.custom_minimum_size = Vector2(420, 560)
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(400, 300)
	v.add_child(stage)
	_big = FighterSprite.new()
	_big.height = 250.0
	_big.max_width = 360.0
	_big.feet_y = 0.0
	_big.position = Vector2(200, 285)
	stage.add_child(_big)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 26)
	v.add_child(_name)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail.custom_minimum_size = Vector2(400, 0)
	_detail.add_theme_font_size_override("font_size", 15)
	_detail.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
	v.add_child(_detail)
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(40, 650)
	back.custom_minimum_size = Vector2(160, 44)
	back.pressed.connect(_back)
	add_child(back)
	var hint := Label.new()
	hint.text = "Select a unit to see it attack"
	hint.position = Vector2(220, 662)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.5, 0.58, 0.72))
	add_child(hint)
	_first.grab_focus()

func _show(key: String, role: String) -> void:
	_big.set_art("res://assets/sprites/%s.png" % key)
	var k: Dictionary = Game.KITS[key]
	var faction := key.get_slice("/", 0)
	_name.text = Game.UNITS[key]["name"]
	_name.add_theme_color_override("font_color", Game.FACTIONS[faction]["color"].lightened(0.2))
	var lines := ["%s  ·  %d HP" % [role.to_upper(), Game.ROLES[role]["hp"]],
		"Primary: %s" % Game.PRIMARY_NAMES.get(k["primary"], k["primary"])]
	if k["passive"] != "":
		lines.append("Passive: %s" % Game.PASSIVE_NAMES.get(k["passive"], k["passive"]))
	if k["card"] != "" and Game.CARDS.has(k["card"]):
		var c: Dictionary = Game.CARDS[k["card"]]
		lines.append("Card: %s (%d): %s" % [c["name"], int(c["cost"]), c["text"]])
	_detail.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()

func _back() -> void:
	Game.go("res://scenes/main_menu.tscn")
