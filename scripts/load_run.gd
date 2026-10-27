extends Control
## Save slots: shows each slot's leader, progress and last-saved time, with Load and
## Delete (confirmed). Esc / Back returns to the title screen.

var _list: VBoxContainer
var _confirm: ConfirmationDialog
var _pending_delete := -1
var _back_btn: Button

func _ready() -> void:
	add_child(preload("res://scripts/menu_background.gd").make("space", Color(0.25, 0.75, 0.8), 7, Vector2(1120, 160), 220.0))
	var title := Label.new()
	title.text = "LOAD RUN"
	title.add_theme_font_size_override("font_size", 44)
	title.position = Vector2(90, 50)
	add_child(title)
	_list = VBoxContainer.new()
	_list.position = Vector2(90, 130)
	_list.add_theme_constant_override("separation", 14)
	add_child(_list)
	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.position = Vector2(90, 640)
	_back_btn.custom_minimum_size = Vector2(160, 44)
	_back_btn.pressed.connect(_back)
	add_child(_back_btn)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Delete run?"
	_confirm.ok_button_text = "Delete"
	_confirm.confirmed.connect(func():
		Game.delete_slot(_pending_delete)
		_refresh())
	add_child(_confirm)
	_refresh()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var focus_set := false
	for s in Game.SLOTS:
		var d := Game.read_slot(s)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(1100, 140)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 24)
		card.add_child(h)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var head := Label.new()
		head.add_theme_font_size_override("font_size", 24)
		var body := Label.new()
		body.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
		if d.is_empty():
			head.text = "Slot %d  —  empty" % (s + 1)
			body.text = "Start a new run from the title screen to use this slot."
		else:
			var l := Game.leader_by_id(d["leader"])
			var pic := TextureRect.new()
			pic.texture = Game.sprite_texture(l["leader"])
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.custom_minimum_size = Vector2(100, 100)
			h.add_child(pic)
			head.text = "Slot %d  —  %s" % [s + 1, Game.UNITS[l["leader"]]["name"]]
			head.add_theme_color_override("font_color", Game.FACTIONS[l["faction"]]["color"])
			body.text = "%s\nSector %d · stage %d of %d  ·  deck %d cards  ·  %d won  ·  saved %s" % [Game.FACTIONS[l["faction"]]["name"], int(d.get("sector", 1)), int(d.get("stage", 0)) + 1, Game.STAGES_PER_SECTOR, d.get("deck", Game.starter_deck(d["leader"])).size(), int(d["wins"]),
				Time.get_datetime_string_from_unix_time(int(d.get("saved_at", 0)), true)]
			if int(d.get("ng", 0)) > 0:
				head.text += "   (NG+%d)" % int(d["ng"])
			if d.get("infinite", false):
				body.text += "  ·  INFINITY AND BEYOND"
			elif d.get("phase", "") == "won":
				body.text += "  ·  RUN WON: choose to complete or go on"
		info.add_child(head)
		info.add_child(body)
		h.add_child(info)
		if not d.is_empty():
			var load_b := Button.new()
			load_b.text = "Load"
			load_b.custom_minimum_size = Vector2(130, 44)
			load_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			load_b.pressed.connect(func():
				if Game.load_run(s):
					Game.go(Game.resume_scene()))
			h.add_child(load_b)
			var del := Button.new()
			del.text = "Delete"
			del.custom_minimum_size = Vector2(130, 44)
			del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			del.pressed.connect(func():
				_pending_delete = s
				_confirm.dialog_text = "Delete the run in slot %d? This can't be undone." % (s + 1)
				_confirm.popup_centered())
			h.add_child(del)
			if not focus_set:
				load_b.grab_focus.call_deferred()
				focus_set = true
		_list.add_child(card)
	if not focus_set:
		_back_btn.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()

func _back() -> void:
	Game.go("res://scenes/main_menu.tscn")
