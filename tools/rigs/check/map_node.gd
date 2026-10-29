extends Node
var _f := 0
func _ready():
	Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
	var col: Array = Game.run["map"][0]
	var long := ["shattered_outpost", "starved_earth", "hostile_nest", "magma_gate"]
	for i in col.size():
		col[i]["mod"] = long[i % long.size()]
	add_child(load("res://scenes/sector_map.tscn").instantiate())
func _process(_d):
	_f += 1
	if _f == 60:
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
		get_tree().quit()
