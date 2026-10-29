extends SceneTree
# -- out.png : draws a sample line at each size with the project font
var _f := 0
var _out := ""

func _init() -> void:
	_out = OS.get_cmdline_user_args()[0]
	var c := Control.new()
	c.size = Vector2(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.15, 0.25)
	bg.size = c.size
	c.add_child(bg)
	var y := 4
	for s in [8, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 32]:
		var l := Label.new()
		l.text = "%d  Barricade fire FIELD 1234567890 Sandbags Take Claim Esc" % s
		l.add_theme_font_size_override("font_size", s)
		l.position = Vector2(8, y)
		c.add_child(l)
		y += s + 12
	root.add_child.call_deferred(c)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 20:
		root.get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 900, 330)).save_png(_out)
		quit()
	return false
