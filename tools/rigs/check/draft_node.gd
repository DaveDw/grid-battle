extends Node
var _f := 0
var _d: Node
func _ready():
	Game.new_run("banner_marshal", 99, 0, [], "conquest", 1)
	Game.run["enemy"] = "chief_visionary"
	Game.run["phase"] = "draft"
	Game.run["offer"] = ["sandbags", "data_breach", "medpod"]
	_d = load("res://scenes/draft.tscn").instantiate()
	add_child(_d)
func _process(_x):
	_f += 1
	if _f == 40:
		for c in _d._choices.get_children():
			print("card ", c.position, " size ", c.size, " min ", c.get_combined_minimum_size())
		print("deck label ", _d._deck_label.position, " ", _d._deck_label.text)
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
		get_tree().quit()
