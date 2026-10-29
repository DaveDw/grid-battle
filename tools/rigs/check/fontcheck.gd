extends SceneTree
func _init():
	print("fallback: ", ThemeDB.fallback_font.resource_path if ThemeDB.fallback_font else "none")
	quit()
