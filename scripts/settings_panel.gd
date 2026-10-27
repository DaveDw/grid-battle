extends Control
## Settings overlay, usable from the main menu and the pause menu. Changes apply live
## and are saved when the panel closes (Back button or Esc).

signal closed

const SLIDERS := [["Master volume", "master_volume"], ["Music volume", "music_volume"], ["Effects volume", "sfx_volume"]]
const TOGGLES := [["Fullscreen", "fullscreen"], ["V-Sync", "vsync"], ["Screen shake", "screen_shake"], ["Damage numbers", "show_damage_numbers"]]

var _first: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.theme   # may live under a CanvasLayer, which blocks theme inheritance
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(340, 90)
	panel.custom_minimum_size = Vector2(600, 540)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 30)
	v.add_child(title)
	_section(v, "Audio")
	for s in SLIDERS:
		var row := _row(v, s[0])
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = float(Game.settings[s[1]])
		sl.custom_minimum_size = Vector2(260, 24)
		var pct := Label.new()
		pct.text = "%d%%" % int(sl.value * 100)
		pct.custom_minimum_size = Vector2(52, 0)
		sl.value_changed.connect(func(val):
			Game.settings[s[1]] = val
			pct.text = "%d%%" % int(val * 100)
			Game.apply_settings())
		row.add_child(sl)
		row.add_child(pct)
		if _first == null:
			_first = sl
	_section(v, "Display & gameplay")
	for t in TOGGLES:
		var row := _row(v, t[0])
		var cb := CheckButton.new()
		cb.button_pressed = bool(Game.settings[t[1]])
		cb.toggled.connect(func(on):
			Game.settings[t[1]] = on
			Game.apply_settings())
		row.add_child(cb)
	_section(v, "Controls")
	var keys := Label.new()
	keys.text = "Keyboard: WASD move · Q/E swap · Space fire · 1-3 cards · Esc pause\nController: D-pad move · L1/R1 swap · A fire · X/Y/B cards · right stick aims, R2 confirms · Start pause"
	keys.add_theme_font_size_override("font_size", 14)
	keys.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	v.add_child(keys)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(160, 42)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(close)
	v.add_child(back)
	_first.grab_focus()

func _section(v: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
	v.add_child(l)

func _row(v: VBoxContainer, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(220, 0)
	row.add_child(l)
	v.add_child(row)
	return row

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	Game.save_settings()
	closed.emit()
	queue_free()
