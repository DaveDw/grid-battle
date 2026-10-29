extends Control
## Title screen: Continue (latest save), New Run, Load Run, Settings, How to Play,
## Credits, Quit. The eight leaders stand along the bottom.

const SETTINGS_PANEL := preload("res://scripts/settings_panel.gd")
const UPDATER := preload("res://scripts/updater.gd")

var _buttons: VBoxContainer
var _t := 0.0
var _title: Label
var _update_btn: Button
var _update_note: Label

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("grid", Color(0.3, 0.5, 0.9), randi() % 20, Vector2(980, 0), 340.0))
	_add_leader_lineup()
	_title = Label.new()
	_title.text = "GRID BATTLE"
	_title.add_theme_font_override("font", Game.FONT_HEAD)
	_title.add_theme_font_size_override("font_size", 76)
	_title.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))
	_title.add_theme_color_override("font_outline_color", Color(0.1, 0.4, 0.7))
	_title.add_theme_constant_override("outline_size", 10)
	_title.position = Vector2(90, 70)
	add_child(_title)
	var sub := Label.new()
	sub.text = "squad tactics  ·  deck-building roguelike"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	sub.position = Vector2(96, 168)
	add_child(sub)

	_buttons = VBoxContainer.new()
	_buttons.position = Vector2(96, 214)
	_buttons.custom_minimum_size = Vector2(320, 0)
	_buttons.add_theme_constant_override("separation", 8)
	add_child(_buttons)
	var latest := Game.latest_slot()
	var cont := _button("Continue", _on_continue)
	cont.disabled = latest < 0
	if latest >= 0:
		var d := Game.read_slot(latest)
		cont.text = "Continue  —  %s, sector %d stage %d" % [Game.UNITS[Game.leader_by_id(d.get("leader", ""))["leader"]]["name"], int(d.get("sector", 1)), int(d.get("stage", 0)) + 1]
		if d.get("mode", "evolution") == "conquest":
			cont.text += "  ·  Conquest"
	_button("Start New Run", func(): Game.go("res://scenes/character_select.tscn"))
	_button("Load Run", func(): Game.go("res://scenes/load_run.tscn"))
	_button("Collection", func(): Game.go("res://scenes/collection.tscn"))
	_button("Units", func(): Game.go("res://scenes/units.tscn"))
	_button("Settings", _on_settings)
	_button("How to Play", _on_how_to_play)
	_button("Credits", func(): Game.go("res://scenes/credits.tscn"))
	_button("Quit", func(): get_tree().quit())
	(_buttons.get_child(0) if not cont.disabled else _buttons.get_child(1)).grab_focus()

	var ver := Label.new()
	ver.text = Game.VERSION
	ver.add_theme_font_size_override("font_size", 13)
	ver.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	ver.size = Vector2(400, 20)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.position = Vector2(1280 - 16 - 400, 690)
	add_child(ver)
	var hint := Label.new()
	hint.text = "Arrows / D-pad / mouse to choose  ·  Enter / A to select  ·  Esc / B to go back"
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	hint.position = Vector2(24, 690)
	add_child(hint)
	_add_updater()

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 42)
	b.pressed.connect(cb)
	_buttons.add_child(b)
	return b

## Top right: an "Update to vX" button when GitHub has a newer release, with a
## status line under it. Exported builds only (see updater.gd).
func _add_updater() -> void:
	UPDATER.cleanup()
	if not UPDATER.should_check():
		return
	_update_btn = Button.new()
	_update_btn.size = Vector2(320, 42)
	_update_btn.position = Vector2(1280 - 24 - 320, 24)
	_update_btn.visible = false
	add_child(_update_btn)
	_update_note = Label.new()
	_update_note.add_theme_font_size_override("font_size", 13)
	_update_note.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8))
	_update_note.size = Vector2(320, 20)
	_update_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_update_note.position = Vector2(1280 - 24 - 320, 72)
	add_child(_update_note)
	var u := UPDATER.new()
	add_child(u)
	u.status.connect(func(t: String): _update_note.text = t)
	u.available.connect(func(v: String):
		_update_btn.text = ("Update to %s" if UPDATER.can_self_update() else "Get %s") % v
		_update_note.text = "Restarts the game when done" if UPDATER.can_self_update() else "Opens the download page"
		_update_btn.visible = true)
	u.progress.connect(func(f: float): _update_btn.text = "Downloading update… %d%%" % int(f * 100.0))
	u.failed.connect(func(t: String):
		_update_note.text = t
		if _update_btn.visible:
			_update_btn.disabled = false
			_update_btn.text = "Retry update")
	_update_btn.pressed.connect(func():
		if UPDATER.can_self_update():
			_update_btn.disabled = true
		u.update())
	u.check()

## The eight leaders, facing in from both sides, breathing slowly.
func _add_leader_lineup() -> void:
	var i := 0
	for l in Game.LEADERS:
		var s := FighterSprite.new()
		s.sprite_path = "res://assets/sprites/%s.png" % l["leader"]
		s.height = 150.0
		s.feet_y = 0.0
		s.face_left = i >= 4
		s.position = Vector2(608 + i * 86, 640 - (i % 2) * 26)
		s.modulate = Color(0.75, 0.8, 0.95, 0.9)
		add_child(s)
		i += 1

func _process(delta: float) -> void:
	_t += delta
	_title.position.y = 70.0 + sin(_t * 1.4) * 3.0

func _on_continue() -> void:
	if Game.load_run(Game.latest_slot()):
		Game.go(Game.resume_scene())

func _on_settings() -> void:
	var p := SETTINGS_PANEL.new()
	add_child(p)
	p.closed.connect(func(): _buttons.get_child(5).grab_focus())

func _on_how_to_play() -> void:
	var d := AcceptDialog.new()
	d.title = "How to Play"
	d.dialog_autowrap = true   # wrap long lines instead of stretching past the screen
	d.dialog_text = "Pick a leader and a mode.\n" \
		+ "CONQUEST: choose how many units you control (1-3); the enemy brings the same, then one more each sector after the third. " \
		+ "Place your squad before each battle. Cards stay in hand until you play them. A leader alone fires its squad's weapon on E / R1.\n" \
		+ "EVOLUTION: three units a side, and a full hand burns a card on every draw.\n\n" \
		+ "WASD / D-pad: move the unit you control (each tile costs a stamina chunk; stamina refills constantly).\n" \
		+ "Q / E or L1 / R1: swap which unit you control.\n" \
		+ "Space, right-click or A: the controlled unit's primary fire (costs energy; recharges after a short pause).\n" \
		+ "1 / 2 / 3 or X / Y / B: play a card. Tile cards are aimed with the mouse or right stick (R2 confirms).\n" \
		+ "Esc / Start: pause.\n\n" \
		+ "Cards come from all three units and stay in the deck even if their unit falls.\n" \
		+ "Each sector is three battles. Damage carries between them; clearing a sector heals your squad.\n" \
		+ "After every win, pick a card for your deck. Between battles you may meet an event: choose carefully.\n" \
		+ "Each planet on the sector map has a modifier that shapes all three of its battles.\n" \
		+ "The third battle is the sector commander: tougher, smarter, with a doctrine of its own.\n" \
		+ "Lose all three units and the run is over."
	add_child(d)
	d.visibility_changed.connect(func():
		if not d.visible:
			_buttons.get_child(6).grab_focus())
	d.get_label().add_theme_font_size_override("font_size", 12)
	d.popup_centered(Vector2i(1040, 0))
	d.get_ok_button().grab_focus()
