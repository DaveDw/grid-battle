class_name PauseMenu
extends CanvasLayer
## In-battle pause (Esc): Resume, Settings, Save & Quit to Title, Abandon Run.
## Pauses the tree while open; this layer keeps processing.

var _box: VBoxContainer
var _confirm: ConfirmationDialog

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.theme = Game.theme   # CanvasLayer blocks theme inheritance
	panel.position = Vector2(480, 170)
	panel.custom_minimum_size = Vector2(320, 0)
	add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	panel.add_child(_box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	_box.add_child(title)
	var has_run := int(Game.run.get("slot", -1)) >= 0
	_button("Resume", _resume)
	_button("Deck", _on_deck)
	_button("Settings", _on_settings)
	_button("Save & Quit to Title" if has_run else "Quit to Title", _on_quit)
	var abandon := _button("Abandon Run", _on_abandon)
	abandon.disabled = not has_run
	_box.get_child(1).grab_focus()
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Abandon run?"
	_confirm.dialog_text = "Abandon this run? Its save will be deleted."
	_confirm.ok_button_text = "Abandon"
	_confirm.confirmed.connect(func():
		Game.end_run()
		Game.go("res://scenes/main_menu.tscn"))
	add_child(_confirm)

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.pressed.connect(cb)
	_box.add_child(b)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_resume()

func _resume() -> void:
	get_tree().paused = false
	queue_free()

## Read through the battle deck: hand, draw pile (order hidden) and used cards.
func _on_deck() -> void:
	var h: CardHand = get_parent().hand
	var d := DeckView.new()
	d.title = "DECK"
	d.groups = [["Hand", h.hand], ["Draw pile", h.deck], ["Used", h.discard]]
	add_child(d)
	_box.get_parent().hide()
	d.closed.connect(func():
		_box.get_parent().show()
		_box.get_child(2).grab_focus())

func _on_settings() -> void:
	var p := preload("res://scripts/settings_panel.gd").new()
	add_child(p)
	_box.get_parent().hide()
	p.closed.connect(func():
		_box.get_parent().show()
		_box.get_child(3).grab_focus())

## The run is saved at the start of every battle, so quitting mid-battle resumes
## that battle from the start.
func _on_quit() -> void:
	Game.save_run()
	Game.run = {}
	Game.go("res://scenes/main_menu.tscn")

func _on_abandon() -> void:
	_confirm.popup_centered()
