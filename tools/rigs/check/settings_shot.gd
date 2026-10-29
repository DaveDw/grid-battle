extends Control
func _ready():
	add_child(preload("res://scripts/settings_panel.gd").new())
