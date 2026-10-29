extends SceneTree
# Usage: godot --path . -s tools/shot.gd -- res://scenes/<scene>.tscn out.png [frames]
# Opens a scene in a real window, waits a few frames, saves a screenshot, quits.
var _out := ""
var _wait := 90

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[1]
	if a.size() > 2:
		_wait = int(a[2])
	change_scene_to_file.call_deferred(a[0])

func _process(_d: float) -> bool:
	_wait -= 1
	if _wait == 0:
		root.get_viewport().get_texture().get_image().save_png(_out)
		quit()
	return false
