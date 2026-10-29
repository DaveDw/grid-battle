extends SceneTree
# -- in.png x y w h scale out.png
func _init():
	var a = OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	var r := img.get_region(Rect2i(int(a[1]), int(a[2]), int(a[3]), int(a[4])))
	r.resize(r.get_width() * int(a[5]), r.get_height() * int(a[5]), Image.INTERPOLATE_NEAREST)
	r.save_png(a[6]); quit()
