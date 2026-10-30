extends Control
## Scrolling credits. Hold Down or the mouse button to speed up; Esc or Back returns to the title.

const LINES := [
	["GRID BATTLE", 48],
	["", 12],
	["A game by", 16], ["David Dwight", 30],
	["", 24],
	["Game design & direction", 16], ["David Dwight", 26],
	["", 20],
	["Programming", 16], ["David Dwight", 26],
	["", 20],
	["Art direction & character art", 16], ["David Dwight", 26],
	["", 20],
	["Unit animation", 16], ["David Dwight", 26],
	["", 20],
	["Card and bullet art", 16], ["David Dwight", 26],
	["", 20],
	["Writing: cards, events, sectors and lore", 16], ["David Dwight", 26],
	["", 20],
	["Sound design", 16], ["David Dwight", 26], ["every effect synthesized in code", 18],
	["", 20],
	["Testing & balance", 16], ["David Dwight", 26],
	["", 20],
	["Fonts (SIL Open Font License)", 16],
	["Press Start 2P by CodeMan38", 20], ["Silkscreen by Jason Kottke", 20], ["Jersey 10 by Sarah Cadigan-Fried", 20],
	["", 20],
	["Engine", 16], ["Godot Engine 4.7", 26], ["by Juan Linietsky, Ariel Manzur and the Godot contributors (MIT)", 18],
	["", 20],
	["Inspired by", 16], ["grid battlers and deck-building roguelikes", 22],
	["", 40],
	["Thanks for playing.", 26],
]

var _scroll: VBoxContainer
var _speed := 40.0

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(0.6, 0.35, 0.95), 16, Vector2(1100, 560), 360.0))
	_scroll = VBoxContainer.new()
	_scroll.position = Vector2(0, 720)
	_scroll.custom_minimum_size = Vector2(1280, 0)
	_scroll.add_theme_constant_override("separation", 6)
	add_child(_scroll)
	var lines: Array = LINES.duplicate()
	# music credits go after the Engine block
	var at := lines.find(["Godot Engine 4.7", 26]) + 1
	var music: Array = [["", 20], ["Music", 16], ["David Dwight", 26], ["original score generated in code, with these tracks:", 18]]
	for c in Music.CREDITS:
		music.append([c, 18])
	for i in music.size():
		lines.insert(at + i, music[i])
	for l in lines:
		var lab := Label.new()
		lab.text = l[0]
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.custom_minimum_size = Vector2(1280, 0)
		lab.add_theme_font_size_override("font_size", l[1])
		if l[1] == 16:
			lab.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
		_scroll.add_child(lab)
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(40, 650)
	back.custom_minimum_size = Vector2(140, 44)
	back.pressed.connect(_back)
	add_child(back)
	back.grab_focus()

func _process(delta: float) -> void:
	var fast := Input.is_action_pressed("ui_down") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_scroll.position.y -= _speed * (4.0 if fast else 1.0) * delta
	if _scroll.position.y < -_scroll.size.y:
		_scroll.position.y = 720.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()

func _back() -> void:
	Game.go("res://scenes/main_menu.tscn")
