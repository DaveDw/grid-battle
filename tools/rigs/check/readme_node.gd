extends Node
## README screenshots: godot --path . res://tools/rigs/check/readme.tscn -- <kind> <out.png> [frames]
## Uses throwaway save slot 99, deleted afterwards.
var _f := 0
var _wait := 90
func _ready():
	var a := OS.get_cmdline_user_args()
	if a.size() > 2:
		_wait = int(a[2])
	var scene := ""
	match a[0]:
		"menu": scene = "main_menu"
		"select": scene = "character_select"
		"units": scene = "units"
		"collection": scene = "collection"
		"map":
			Game.new_run("tide_speaker", 99, 0, [], "conquest", 3)
			scene = "sector_map"
		"draft":
			Game.new_run("mission_mother", 99, 0, [], "conquest", 3)
			Game.run["enemy"] = "banner_marshal"
			Game.run["phase"] = "draft"
			Game.run["offer"] = ["medpod", "barrage"]
			scene = "draft"
		"battle":
			Game.new_run("captain_everafter", 99, 0, [], "evolution", 3)
			Game.run["phase"] = "battle"
			scene = "main"
	add_child(load("res://scenes/%s.tscn" % scene).instantiate())
func _process(_d):
	_f += 1
	if _f == _wait:
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[1])
		if FileAccess.file_exists(Game.slot_path(99)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
		get_tree().quit()
