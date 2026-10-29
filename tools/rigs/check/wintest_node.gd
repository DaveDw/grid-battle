extends Node
var _f := 0
func _process(_d):
	_f += 1
	if _f == 5:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	elif _f == 30:
		print("before: ", DisplayServer.window_get_mode())
		Game.settings["screen_shake"] = not Game.settings["screen_shake"]
		Game.apply_settings()
	elif _f == 50:
		print("after setting change: ", DisplayServer.window_get_mode(), " (2 = maximized)")
		Game.settings["fullscreen"] = true
		Game.apply_settings()
	elif _f == 80:
		print("fullscreen on: ", DisplayServer.window_get_mode(), " (3 = fullscreen)")
		Game.settings["fullscreen"] = false
		Game.apply_settings()
	elif _f == 110:
		print("fullscreen off: ", DisplayServer.window_get_mode(), " (0 = windowed)")
		Game.settings["screen_shake"] = not Game.settings["screen_shake"]
		get_tree().quit()
