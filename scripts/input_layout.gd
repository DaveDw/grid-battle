class_name InputLayout
## Input layout for keyboard + mouse, controller and touch (touch arrives as mouse
## clicks). Applied at startup by the Game autoload so the whole scheme reads in one
## place.
##   Keyboard + mouse: WASD move, Q/E swap, Space or right-click fire, 1-3 or click a
##                     card, click a tile to aim, right-click or Esc cancels aiming.
##   Controller:       D-pad move, L1/R1 swap, A/Cross fire, X/Y/B cards, right stick
##                     aims, R2 confirms, L2 cancels, Start pauses.

static func apply() -> void:
	var layout := {
		"move_up": _keys([KEY_W, KEY_UP]) + [_pad(JOY_BUTTON_DPAD_UP)],
		"move_down": _keys([KEY_S, KEY_DOWN]) + [_pad(JOY_BUTTON_DPAD_DOWN)],
		"move_left": _keys([KEY_A, KEY_LEFT]) + [_pad(JOY_BUTTON_DPAD_LEFT)],
		"move_right": _keys([KEY_D, KEY_RIGHT]) + [_pad(JOY_BUTTON_DPAD_RIGHT)],
		"swap_prev": _keys([KEY_Q]) + [_pad(JOY_BUTTON_LEFT_SHOULDER)],
		"swap_next": _keys([KEY_E]) + [_pad(JOY_BUTTON_RIGHT_SHOULDER)],
		"buster": _keys([KEY_SPACE, KEY_Z]) + [_mouse(MOUSE_BUTTON_RIGHT), _pad(JOY_BUTTON_A)],
		"card_1": _keys([KEY_1]) + [_pad(JOY_BUTTON_X)],
		"card_2": _keys([KEY_2]) + [_pad(JOY_BUTTON_Y)],
		"card_3": _keys([KEY_3]) + [_pad(JOY_BUTTON_B)],
		"aim_up": [_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"aim_down": [_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"aim_left": [_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"aim_right": [_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"aim_confirm": [_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"aim_cancel": [_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"pause": _keys([KEY_ESCAPE]) + [_pad(JOY_BUTTON_START)],
		"confirm": _keys([KEY_ENTER, KEY_KP_ENTER]) + [_pad(JOY_BUTTON_A)],
	}
	for action in layout:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		InputMap.action_set_deadzone(action, 0.5)
		for e in layout[action]:
			InputMap.action_add_event(action, e)
	# menus: A / Cross presses the focused button, B / Circle backs out (the battle
	# pauses on "pause", so B stays a card there). Godot's defaults have neither.
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var ev := _pad(pair[1])
		if not InputMap.action_has_event(pair[0], ev):
			InputMap.action_add_event(pair[0], ev)

static func _keys(codes: Array) -> Array:
	var out := []
	for c in codes:
		var e := InputEventKey.new()
		e.physical_keycode = c
		out.append(e)
	return out

static func _pad(button: JoyButton) -> InputEvent:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e

static func _axis(a: JoyAxis, v: float) -> InputEvent:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e

static func _mouse(b: MouseButton) -> InputEvent:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e
