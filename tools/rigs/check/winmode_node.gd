extends Node
## Prints the window mode a fresh launch ends up in, then quits.
var _f := 0
func _process(_d):
	_f += 1
	if _f == 30:
		print("WINDOW_MODE=", DisplayServer.window_get_mode(), " fullscreen_setting=", Game.settings["fullscreen"], " size=", DisplayServer.window_get_size())
		get_tree().quit()
