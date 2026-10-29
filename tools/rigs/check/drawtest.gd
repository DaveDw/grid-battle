extends SceneTree
var _f := 0
class D extends Control:
	var t: Texture2D
	func _draw():
		draw_rect(Rect2(10, 10, 32, 32), Color(0, 0, 0, 0.25))
		draw_texture_rect(t, Rect2(10, 10, 32, 32), false, Color.WHITE)
		draw_string(Game.FONT_CARD, Vector2(10, 60), "15", HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		draw_texture_rect(t, Rect2(60, 10, 128, 128), false)
		draw_texture(t, Vector2(200, 10))
func _init():
	var layer := CanvasLayer.new()
	root.add_child.call_deferred(layer)
	var d := D.new()
	d.t = load("res://assets/cards/claim.png")
	d.size = Vector2(400, 200)
	d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child.call_deferred(d)
func _process(_x):
	_f += 1
	if _f == 10:
		root.get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 400, 160)).save_png(OS.get_cmdline_user_args()[0])
		quit()
	return false
