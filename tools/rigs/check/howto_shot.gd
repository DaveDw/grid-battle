extends Node
var _f := 0
var _m: Node
func _ready():
	_m = load("res://scenes/main_menu.tscn").instantiate()
	add_child(_m)
func _process(_d):
	_f += 1
	if _f == 20:
		_m._on_how_to_play()
	elif _f == 60:
		var w := get_window()
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		for c in _m.get_children():
			if c is AcceptDialog:
				print("dialog size ", c.size, " pos ", c.position, " screen ", DisplayServer.screen_get_size(), " win ", w.size)
		get_tree().quit()
