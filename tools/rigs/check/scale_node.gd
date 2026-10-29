extends Node
var _f := 0
var _m: Node
func _ready():
	_m = load("res://scenes/main_menu.tscn").instantiate()
	add_child(_m)
func _process(_d):
	_f += 1
	if _f == 10:
		for c in _m.get_children():
			if c is FighterSprite:
				print(c.sprite_path.get_file(), " scale ", c._base_scale, " cell ", c._cell, " drawn_h ", c._cell.y * c._base_scale.y)
		get_tree().quit()
