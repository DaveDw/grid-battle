extends SceneTree
func _init():
	var t: Texture2D = load("res://assets/cards/claim.png")
	print("tex ", t, " size ", t.get_size())
	var im := t.get_image()
	print("fmt ", im.get_format(), " px(64,64) ", im.get_pixel(64, 64), " px(0,0) ", im.get_pixel(0, 0))
	quit()
