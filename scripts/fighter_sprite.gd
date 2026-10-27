class_name FighterSprite
extends Node2D
## Character art for a fighter (player or enemy). Loads one of the cut-out sprites in
## res://assets/sprites/ and animates it procedurally: a breathing idle loop, an
## attack recoil with muzzle flash, an enemy wind-up, a hit flash and a death fade.
## The sprite's feet sit near the bottom edge of the fighter's panel.



## Path of the sprite PNG (any of the 24 under res://assets/sprites/<faction>/).
@export_file("*.png") var sprite_path := "res://assets/sprites/terran/pathfinder.png"
## Mirror the art so it faces left (sheet art faces right).
@export var face_left := false
## On-screen height in pixels.
@export var height := 112.0
## If > 0, also shrink wide art to fit this width.
@export var max_width := 0.0
## Feet offset below the panel centre.
@export var feet_y := 40.0
## Where the weapon muzzle is, as a fraction of the (unmirrored) art's width/height.
@export var muzzle := Vector2(0.95, 0.45)

## Frame animation: if `<sprite>_idle.png` (IDLE_FRAMES cells in a row) exists next to
## the sprite, it loops instead of the procedural breathing; `<sprite>_attack.png`
## (ATTACK_FRAMES cells) plays on each shot. Cells share one size with the feet at the
## bottom centre (tools/slice_frames.gd builds them that way).
const IDLE_FRAMES := 8
const ATTACK_FRAMES := 2
const IDLE_FPS := 8.0
const ATTACK_FRAME_TIME := [0.07, 0.14]

var _sprite: Sprite2D
var _base_scale := Vector2.ONE
var _still: Texture2D           # the single cut-out (portraits, afterimages)
var _idle: Texture2D
var _attack: Texture2D
var _cell := Vector2.ONE        # size of one frame (or the whole still)
var _attack_t := -1.0           # time into the attack frames (< 0 = not attacking)
## Single-frame move poses, `<sprite>_move_<dir>.png` (same cell size as the idle frames):
## shown for MOVE_POSE_TIME while sliding to a new tile. fwd = toward the enemy.
const MOVE_DIRS := ["up", "down", "fwd", "back"]
const MOVE_POSE_TIME := 0.16
var _moves := {}
var _move_t := -1.0
var _t := 0.0
var _flash := 0.0          # muzzle flash time left
var _windup := false
var _anim: Tween

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	_apply_art()

## Swap to another character's art (e.g. on the leader select screen).
func set_art(path: String) -> void:
	sprite_path = path
	if _sprite:
		_apply_art()

func _apply_art() -> void:
	_still = load(sprite_path)
	var stem := sprite_path.get_basename()
	_idle = load(stem + "_idle.png") if ResourceLoader.exists(stem + "_idle.png") else null
	_attack = load(stem + "_attack.png") if ResourceLoader.exists(stem + "_attack.png") else null
	# frame art carries its own muzzle point (found by tools/import_frames.gd)
	# and its body height (cells can be taller than the body: flags, launched shells)
	var meta := stem + "_frames.json"
	var body_h := 0.0
	if _idle and FileAccess.file_exists(meta):
		var data = JSON.parse_string(FileAccess.get_file_as_string(meta))
		if data is Dictionary and data.has("muzzle"):
			muzzle = Vector2(data["muzzle"][0], data["muzzle"][1])
		if data is Dictionary and data.has("body_h"):
			body_h = float(data["body_h"])
	_moves = {}
	for d in MOVE_DIRS:
		var p: String = stem + "_move_" + d + ".png"
		if ResourceLoader.exists(p):
			_moves[d] = load(p)
	_attack_t = -1.0
	_move_t = -1.0
	_show_idle()
	var size := _cell
	_sprite.offset = Vector2(-size.x * 0.5, -size.y)  # pivot at the feet
	var s := height / (body_h if body_h > 0.0 else size.y)
	if max_width > 0.0:
		# fit the character (as wide as the still art at this scale), not the roomy cell
		var art_w := size.x if body_h <= 0.0 else _still.get_width() * body_h / _still.get_height()
		s = minf(s, max_width / art_w)
	_base_scale = Vector2(-s if face_left else s, s)
	_sprite.scale = _base_scale
	_sprite.position = Vector2(0.0, feet_y)

func has_frames() -> bool:
	return _idle != null

func _show_idle() -> void:
	if _idle:
		_sprite.texture = _idle
		_sprite.hframes = IDLE_FRAMES
		_cell = Vector2(_idle.get_width() / float(IDLE_FRAMES), _idle.get_height())
	else:
		_sprite.texture = _still
		_sprite.hframes = 1
		_cell = _still.get_size()
	_sprite.frame = 0

func _process(delta: float) -> void:
	_t += delta
	if _move_t >= 0.0:
		_move_t += delta
		if _move_t >= MOVE_POSE_TIME:
			_move_t = -1.0
			_show_idle()
	elif _attack_t >= 0.0:
		_attack_t += delta
		var f := 0 if _attack_t < ATTACK_FRAME_TIME[0] else 1
		if _attack_t >= ATTACK_FRAME_TIME[0] + ATTACK_FRAME_TIME[1]:
			_attack_t = -1.0
			_show_idle()
		else:
			_sprite.frame = f
	elif _idle:
		_sprite.frame = int(_t * IDLE_FPS) % IDLE_FRAMES
	# idle without frames: slow breathing squash (feet stay planted: pivot at the feet)
	if _idle == null and (_anim == null or not _anim.is_running()):
		var breathe := sin(_t * 3.2) * 0.022
		_sprite.scale = _base_scale * Vector2(1.0 - breathe * 0.5, 1.0 + breathe)
	if _windup:
		# pulse hot orange while charging (never fully back to normal, so it reads as a warning)
		var p := 0.45 + 0.55 * (0.5 + 0.5 * sin(_t * 24.0))
		_sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(2.2, 1.2, 0.45), p)
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()
	elif _flash > -1.0:
		_flash = -2.0
		queue_redraw()

func _draw() -> void:
	if _flash <= 0.0:
		return
	var m := muzzle_point()
	var k := _flash / 0.12
	draw_circle(m, 10.0 * k + 4.0, Color(1.0, 0.95, 0.6, 0.85 * k))
	draw_circle(m, 5.0 * k + 2.0, Color(1.0, 1.0, 1.0, k))

## The single still image (for portraits and afterimages), even when animating frames.
func get_texture() -> Texture2D:
	return _still if _still else load(sprite_path)

## Muzzle position in this node's coordinates (follows mirroring).
func muzzle_point() -> Vector2:
	var size := _cell * absf(_base_scale.y)
	var x := (muzzle.x - 0.5) * size.x
	return Vector2(-x if face_left else x, feet_y - muzzle.y * size.y)

func _restart_anim() -> Tween:
	if _anim:
		_anim.kill()
	_sprite.position = Vector2(0.0, feet_y)
	_sprite.scale = _base_scale
	_anim = create_tween()
	return _anim

## Shot fired: kick back against the facing, squash, flash at the muzzle.
func play_attack() -> void:
	end_windup()
	_flash = 0.12
	_move_t = -1.0
	if _attack:
		# hand-drawn attack frames; the cell matches the idle cell, so the scale holds
		_sprite.texture = _attack
		_sprite.hframes = ATTACK_FRAMES
		_sprite.frame = 0
		_attack_t = 0.0
	var back := 7.0 if face_left else -7.0
	var tw := _restart_anim()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "position:x", back, 0.05)
	tw.tween_property(_sprite, "scale", _base_scale * Vector2(1.08, 0.94), 0.05)
	tw.chain().set_parallel(true)
	tw.tween_property(_sprite, "position:x", 0.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "scale", _base_scale, 0.14)

## Enemy telegraph: crouch and lean back while pulsing, for `duration` seconds.
func play_windup(duration: float) -> void:
	_windup = true
	var lean := 6.0 if face_left else -6.0
	var tw := _restart_anim()
	tw.set_parallel(true)
	tw.tween_property(_sprite, "scale", _base_scale * Vector2(1.1, 0.88), duration * 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sprite, "position:x", lean, duration * 0.6)

func end_windup() -> void:
	_windup = false
	_sprite.modulate = Color.WHITE

## Took damage: white flash and a short shake.
func play_hit() -> void:
	end_windup()
	var tw := _restart_anim()
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.18)
	tw.parallel().tween_property(_sprite, "position:x", 5.0, 0.03)
	tw.tween_property(_sprite, "position:x", -5.0, 0.04)
	tw.tween_property(_sprite, "position:x", 0.0, 0.04)

## Moving one tile: `d` is "up" / "down" / "fwd" / "back". Shows that pose, if drawn.
func play_move(d: String) -> void:
	if _moves.has(d) and _attack_t < 0.0:
		_sprite.texture = _moves[d]
		_sprite.hframes = 1
		_sprite.frame = 0
		_move_t = 0.0

## Landed on a new panel: quick squash so the snap reads as a hop.
func play_land() -> void:
	if _windup:
		return
	var tw := _restart_anim()
	_sprite.scale = _base_scale * Vector2(1.12, 0.86)
	tw.tween_property(_sprite, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Deleted: flash, sink and fade out.
func play_death() -> void:
	end_windup()
	var tw := _restart_anim()
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	tw.set_parallel(true)
	tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.6)
	tw.tween_property(_sprite, "scale", _base_scale * Vector2(1.25, 0.2), 0.6).set_ease(Tween.EASE_IN)
