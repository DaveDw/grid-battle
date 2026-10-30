class_name Unit
extends Node2D
## One fighter on the grid, on either team. Holds its tile, HP, art (a FighterSprite
## built in setup()) and the per-unit state its kit needs (shield, hit streak, marks,
## heal-over-time...). The battlefield owns the rules; enemy units run a small AI that
## goes through the same battlefield calls as the player, so they pay stamina and
## energy too.

signal hp_changed(unit: Unit)
signal killed(unit: Unit)

const MOVE_TIME := 0.09         # tween time between tiles
# first AI timers; after that the stage's tuning (battlefield.ai) takes over
const AI_MOVE_MIN := 1.3
const AI_MOVE_MAX := 2.5
const AI_ATTACK_MIN := 2.5
const AI_ATTACK_MAX := 4.5
const AI_CHARGE_TIME := 1.2

var team := 0                   # 0 = player, 1 = enemy
var key := ""                   # sprite key, e.g. "terran/pathfinder"
var unit_name := ""
var role := ""                  # "leader" / "heavy" / "light"
var primary := "standard"
var passive := ""
var alt_primary := ""           # a leader fighting alone: its squad's fire, on the right swap button
var alt_role := ""              # whose shot numbers the alternate fire uses
var col := 0
var row := 0
var prev_col := 0               # last tile stood on (Parallax afterimage)
var prev_row := 0
var hp := 100
var max_hp := 100
var active := false             # the player unit currently under control
var grid: Node2D = null
var sprite: FighterSprite

# kit state (times are battlefield time in seconds)
var last_moved_at := -99.0
var last_fired_at := -99.0
var forced_at := -99.0          # last forced move (Ambush)
var shield_up := true           # Breacher
var shield_hits: Array = []
var last_hit_at := -99.0
var streak := 0                 # Pathfinder consecutive hits
var free_moves_used := 0        # Glasswing
var vmove_times: Array = []     # Prism Elder vertical moves
var refract_ready := false
var heal_until := -1.0          # Medpod
var mark_hits := {}             # marker instance id -> [hit times]
var pip_count := 0              # hits toward a mark, shown over the head
var pip_color := Color.WHITE
var pip_until := -1.0
var marks := {}                 # "analysis" / "interval" -> {until, team, accum}
var overclock_until := -1.0     # Overclock: half-cost primary until then...
var jam_until := -1.0           # ...then can't fire until this
var echo_until := -1.0          # Echo Strike: every shot fires a free echo until then
var echoing := false            # true while firing an echo (echoes don't echo)
var last_charge := 0.0          # energy in the last Charge Beam (its echo copies it)
var history: Array = []         # [time, col, row, hp] samples for Rewind
var heal_rate := 6.0            # HP/s while heal_until is running (Medpod, Regrowth)
var barrier := 0.0              # Shield Drone HP left...
var barrier_until := -1.0       # ...until this time
var undying_until := -1.0       # Last Stand: can't drop below 1 HP until this time
var link_until := -1.0          # Mycelial Link: hits on this unit are shared by the squad
var spared := false             # Burning Stars commander: already shrugged off a killing blow
var dug_until := -1.0           # Dig In: tougher and harder-hitting until then (moving ends it)
var breach_until := -1.0        # Data Breach: shots cost double until then
var rooted_until := -1.0        # Flash Forward's time debt: can't move until then

var _ai_move := 0.0
var _ai_attack := 0.0
var _telegraph := 0.0
var _ai_charging := 0.0
var _dodge_cd := 0.0
var _move_tween: Tween

## `data`: name, sprite, role, hp, height, muzzle, cell, primary, passive (Game.squad_for).
func setup(bf: Node2D, data: Dictionary, unit_team: int) -> void:
	grid = bf
	team = unit_team
	key = data["sprite"]
	unit_name = data["name"]
	role = data["role"]
	primary = data.get("primary", "standard")
	passive = data.get("passive", "")
	alt_primary = data.get("alt", "")
	alt_role = data.get("alt_role", "")
	max_hp = data["hp"]
	hp = max_hp
	col = data["cell"].x
	row = data["cell"].y
	prev_col = col
	prev_row = row
	position = grid.panel_center(col, row)
	sprite = FighterSprite.new()
	sprite.sprite_path = "res://assets/sprites/%s.png" % key
	sprite.face_left = team == 1
	sprite.height = data["height"]
	sprite.feet_y = grid.PANEL_H * 0.4
	sprite.muzzle = data["muzzle"]
	add_child(sprite)
	_ai_move = randf_range(AI_MOVE_MIN, AI_MOVE_MAX)
	_ai_attack = randf_range(AI_ATTACK_MIN, AI_ATTACK_MAX)

func is_alive() -> bool:
	return hp > 0

func is_telegraphing() -> bool:
	return _telegraph > 0.0

## Put the unit straight on a tile (setting up the battle: no move, no animation).
func place(c: int, r: int) -> void:
	col = c
	row = r
	prev_col = c
	prev_row = r
	if _move_tween:
		_move_tween.kill()
	position = grid.panel_center(c, r)

## Slide to a new tile. The battlefield has already checked it is legal and free.
func move_to(c: int, r: int) -> void:
	if hp <= 0:
		return
	var toward := 1 if team == 0 else -1
	sprite.play_move("up" if r < row else "down" if r > row else "fwd" if (c - col) * toward > 0 else "back")
	prev_col = col
	prev_row = row
	col = c
	row = r
	if _move_tween:
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", grid.panel_center(c, r), MOVE_TIME).set_ease(Tween.EASE_OUT)
	sprite.play_land()

func take_damage(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(self)
	if hp <= 0:
		_telegraph = 0.0
		marks.clear()
		sprite.play_death()
		killed.emit(self)
	else:
		sprite.play_hit()

func heal(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(self)

func set_active(on: bool) -> void:
	active = on
	queue_redraw()

func _process(delta: float) -> void:
	queue_redraw()
	if team == 1 and hp > 0 and grid.battle_on:
		_run_ai(delta)

# --- status visuals (drawn before the sprite child) --------------------------------

func _draw() -> void:
	if hp <= 0:
		return
	var t: float = grid.time
	var feet := Vector2(0.0, grid.PANEL_H * 0.4)
	var rx: float = grid.PANEL_W * 0.36
	var ry: float = grid.PANEL_H * 0.28
	if active:
		var pulse := 0.5 + 0.5 * sin(t * 5.0)
		draw_set_transform(feet, 0.0, Vector2(1.0, ry / rx))
		draw_circle(Vector2.ZERO, rx, Color(0.35, 0.85, 1.0, 0.18 + 0.12 * pulse))
		draw_arc(Vector2.ZERO, rx, 0.0, TAU, 40, Color(0.5, 0.95, 1.0, 0.7 + 0.3 * pulse), 3.0)
		draw_set_transform(Vector2.ZERO)
	var head := Vector2(0.0, feet.y - sprite.height - 8.0)
	# marks: a ring around the feet in the marker's colour, with the time left
	var ring_r := rx * 0.8
	for m in marks:
		var info: Dictionary = marks[m]
		var c := Color(0.3, 0.95, 0.9) if m == "analysis" else Color(0.75, 0.45, 1.0)
		var left: float = (info["until"] - t) / grid.MARK_TIME
		draw_set_transform(feet, 0.0, Vector2(1.0, ry / rx))
		draw_arc(Vector2.ZERO, ring_r, -PI / 2, -PI / 2 + TAU * left, 32, c, 3.0)
		draw_set_transform(Vector2.ZERO)
		ring_r -= 7.0
		var font := ThemeDB.fallback_font
		draw_string(font, head + Vector2(-40, -14), "ANALYZED" if m == "analysis" else "MARKED", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, c)
	# 3-pip counter toward a mark
	if pip_count > 0 and t < pip_until:
		for k in 3:
			var p := head + Vector2((k - 1) * 12.0, 0)
			draw_circle(p, 4.5, Color(0, 0, 0, 0.6))
			if k < pip_count:
				draw_circle(p, 3.5, pip_color)
			else:
				draw_arc(p, 3.5, 0, TAU, 12, pip_color, 1.0)
	# Breacher shield
	if passive == "shield_up":
		var front := Vector2(26.0 if team == 0 else -26.0, feet.y - sprite.height * 0.45)
		var col_s := Color(0.5, 0.8, 1.0, 0.8) if shield_up else Color(1.0, 0.35, 0.3, 0.6)
		var a0 := -1.0 if team == 0 else PI - 1.0
		draw_arc(front, 22.0, a0, a0 + 2.0, 12, col_s, 3.0)
	# Medpod heal
	if t < heal_until:
		var y := fmod(t * 40.0, 30.0)
		var p := Vector2(-18.0, feet.y - 20.0 - y)
		draw_rect(Rect2(p - Vector2(5, 1.5), Vector2(10, 3)), Color(0.4, 1.0, 0.5, 1.0 - y / 30.0))
		draw_rect(Rect2(p - Vector2(1.5, 5), Vector2(3, 10)), Color(0.4, 1.0, 0.5, 1.0 - y / 30.0))
	# Shield Drone barrier: a bubble that thins as it soaks damage
	if barrier > 0.0 and t < barrier_until:
		var mid := Vector2(0, feet.y - sprite.height * 0.5)
		draw_arc(mid, sprite.height * 0.55, 0, TAU, 40, Color(0.5, 0.9, 1.0, 0.25 + 0.5 * barrier / 30.0), 3.0)
	# Last Stand: red-gold edge while it can't fall
	if t < undying_until:
		draw_arc(Vector2(0, feet.y - sprite.height * 0.5), sprite.height * 0.5, 0, TAU, 40, Color(1.0, 0.6, 0.2, 0.5 + 0.3 * sin(t * 12.0)), 2.0)
	# Dig In: a low sandbag ring around the feet
	if t < dug_until:
		for n in 7:
			var ang := PI + n * PI / 6.0
			var p := feet + Vector2(cos(ang) * rx * 0.9, sin(ang) * ry * 0.5 + 6.0)
			draw_rect(Rect2(p - Vector2(7, 4), Vector2(14, 8)), Color(0.75, 0.65, 0.42))
			draw_rect(Rect2(p - Vector2(7, 4), Vector2(14, 8)), Color(0.35, 0.28, 0.15), false, 1.0)
	# Data Breach: glitchy red label
	if t < breach_until:
		var font := ThemeDB.fallback_font
		var jit := Vector2(randf_range(-1, 1), 0) if fmod(t, 0.5) < 0.1 else Vector2.ZERO
		draw_string(font, head + Vector2(-40, -28) + jit, "BREACHED", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color(1.0, 0.35, 0.4))
	# Mycelial Link: green threads running from the feet to each living squadmate
	if t < link_until:
		for o in grid.units_of(team):
			if o != self and o.is_alive():
				var to: Vector2 = o.position - position + feet
				var mid: Vector2 = (feet + to) * 0.5 + Vector2(0, 10.0 * sin(t * 4.0))
				var c := Color(0.45, 1.0, 0.55, 0.45)
				draw_line(feet, mid, c, 2.0)
				draw_line(mid, to, c, 2.0)
	# Overclock: cyan sparks while boosted, a red bar while jammed
	if t < overclock_until:
		for n in 3:
			var a := t * 9.0 + n * TAU / 3.0
			draw_circle(Vector2(cos(a) * 20.0, feet.y - sprite.height * 0.5 + sin(a) * 10.0), 2.5, Color(0.4, 0.95, 1.0))
	elif t < jam_until:
		var font := ThemeDB.fallback_font
		draw_string(font, head + Vector2(-40, -14), "JAMMED", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color(1.0, 0.4, 0.35))
	# Echo Strike: two pale rings pulse around the unit while every shot is echoed
	if t < echo_until:
		var mid := Vector2(0, feet.y - sprite.height * 0.5)
		for n in 2:
			var r := 22.0 + fmod(t * 30.0 + n * 12.0, 24.0)
			draw_arc(mid, r, 0.0, TAU, 32, Color(1.0, 0.85, 0.55, 0.5 - (r - 22.0) / 50.0), 2.0)
	# Prism Elder: refraction charged
	if refract_ready:
		draw_circle(Vector2(0, feet.y - sprite.height * 0.5), 10.0 + 3.0 * sin(t * 10.0), Color(1.0, 0.85, 0.4, 0.35))


# --- AI (enemy team): same calls as the player, so it pays stamina and energy ----------
## The enemy brain, after Codex's plan (kb/proposals/codex-enemy-ai.md): fire only when
## a shot can land, move to useful lanes, react to visible shots after a human-like
## delay, keep stamina and energy in reserve, and play to each kit's strengths. Which
## behaviours are on, and how fast, comes from Game.ai_params(level, faction).

var _threat_seen := {}          # ids of shots already reacted to
var _react_t := -1.0            # counting down to a dodge decision
var _plan_dir := Vector2i.ZERO  # Prism Elder: the second step of a Refraction setup
var _plan_t := 0.0
var _resting := false           # Red Giant / Cinder Scout holding fire at low HP
var _alt_next := false          # the current wind-up fires the alternate primary
var _burst_left := 0            # Field Scholar / Captain: shots left in a mark burst

## Fire within `t` seconds if a shot is lined up (a card combo's volley).
func ai_fire_soon(t: float) -> void:
	_ai_attack = minf(_ai_attack, t)

func _run_ai(delta: float) -> void:
	if _ai_charging > 0.0:
		_ai_charging -= delta
		grid.charge_tick(self, delta)
		if _ai_charging <= 0.0:
			grid.release_charge(self)
		return
	var ai: Dictionary = grid.ai
	if _telegraph > 0.0:
		_telegraph -= delta
		if _telegraph <= 0.0:
			_release(ai)
		return
	_watch_threats(delta, ai)
	# the second step of a planned Refraction setup
	if _plan_dir != Vector2i.ZERO:
		_plan_t -= delta
		if _plan_t <= 0.0:
			if grid.can_move(self, col + _plan_dir.x, row + _plan_dir.y):
				grid.try_move(self, _plan_dir)
			_plan_dir = Vector2i.ZERO
			ai_fire_soon(0.2)
		return
	_ai_move -= delta
	if _ai_move <= 0.0:
		_ai_move = randf_range(ai["move_min"], ai["move_max"])
		_ai_step(ai)
	_ai_attack -= delta
	if _ai_attack <= 0.0:
		_ai_attack = randf_range(ai["attack_min"], ai["attack_max"])
		# SILENCE makes every player shot cost HP: trade more freely while it lasts
		if grid.ai_protocol_rule(1 - team) == "SILENCE":
			_ai_attack *= 0.75
		_ai_try_attack(ai)

## End of the wind-up: recheck the lane (an empty one cancels), then fire.
func _release(ai: Dictionary) -> void:
	var lands: bool = grid.ai_alt_lands(self) if _alt_next else grid.ai_shot_lands(self)
	if not lands and randf() < ai.get("aim", 0.0):
		_ai_attack = maxf(_ai_attack, 0.6)
		return
	if (alt_primary if _alt_next else primary) == "charge":
		# a 0.8s beam normally; a longer one when the bar can afford it
		_ai_charging = 1.2 if grid.team_energy[team].value >= 50.0 else 0.8
	elif _alt_next:
		grid.fire_alt(self)
	else:
		grid.fire_primary(self)
	# a mark burst: the next shot 1.4s after this one (release to release)
	if _burst_left > 0:
		_burst_left -= 1
		if _burst_left > 0:
			_ai_attack = maxf(1.4 - float(ai["telegraph"]), 0.3)
	# Glasswing: Hit and Run makes the next step free, so take a useful one now
	if passive == "hit_and_run" and int(ai.get("level", 0)) >= 1:
		_ai_move = minf(_ai_move, 0.3)

## Visible shots: notice each once, then after the reaction delay maybe sidestep to a
## safer row (never instantly, never twice within 0.8s).
func _watch_threats(delta: float, ai: Dictionary) -> void:
	_dodge_cd -= delta
	if _react_t >= 0.0:
		_react_t -= delta
		if _react_t < 0.0 and _dodge_cd <= 0.0 and randf() < float(ai["dodge"]):
			_dodge_cd = 0.8
			var here: float = grid.ai_tile_score(self, col, row)
			var best := Vector2i.ZERO
			for d in ([Vector2i.UP, Vector2i.DOWN] if randf() < 0.5 else [Vector2i.DOWN, Vector2i.UP]):
				if grid.can_move(self, col, row + d.y):
					var sc: float = grid.ai_tile_score(self, col, row + d.y)
					if sc > here:
						here = sc
						best = d
			if best != Vector2i.ZERO:
				grid.try_move(self, best)   # may spend the stamina kept in reserve
		return
	if float(ai["dodge"]) <= 0.0:
		return
	var s: Dictionary = grid.incoming_threat(self)
	if not s.is_empty() and not _threat_seen.has(s.get("id", -1)):
		_threat_seen[s.get("id", -1)] = true
		_react_t = float(ai["reaction"])

## A move: to the best neighbouring tile (or stay), keeping stamina for dodges.
func _ai_step(ai: Dictionary) -> void:
	if grid.time < rooted_until:
		return
	var reserve := int(ai.get("reserve", 0))
	if reserve >= 2 and grid.units_of(team).filter(func(u): return u.is_alive()).size() < 2:
		reserve = 1   # alone, one chunk is enough
	var stamina: float = grid.team_stamina[team].value
	var free: bool = passive == "hit_and_run" and grid.time - last_fired_at <= 1.0 and free_moves_used < 3
	if not free and stamina < reserve + 1:
		return
	# Prism Elder (level 2+): two quick vertical steps arm Refraction when a split pays
	if primary == "refraction" and not refract_ready and int(ai.get("level", 0)) >= 2 and stamina >= reserve + 2:
		for d in [Vector2i.UP, Vector2i.DOWN]:
			if grid.can_move(self, col, row + d.y) and grid.can_move(self, col, row + 2 * d.y) \
					and grid.ai_refract_pays(self, row + 2 * d.y):
				grid.try_move(self, d)
				_plan_dir = d
				_plan_t = 0.35
				return
	if randf() < float(ai.get("smart", 0.0)):
		var best := Vector2i.ZERO
		var best_score: float = grid.ai_tile_score(self, col, row) + float(ai.get("stay", 0.0))
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if grid.can_move(self, col + d.x, row + d.y):
				var sc: float = grid.ai_tile_score(self, col + d.x, row + d.y) + randf() * 0.3
				if sc > best_score:
					best = d
					best_score = sc
		if best != Vector2i.ZERO:
			grid.try_move(self, best)
		if grid.ai_shot_lands(self):
			ai_fire_soon(0.25)
		return
	# otherwise wander as before: towards the weakest row, or the border for Long Tomorrow
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	dirs.shuffle()
	var target_row: int = grid.weakest_player_row()
	if target_row >= 0 and target_row != row and randf() < ai["focus"]:
		dirs.push_front(Vector2i.DOWN if target_row > row else Vector2i.UP)
	if randf() < ai.get("front", 0.0):
		dirs.push_front(Vector2i.LEFT if team == 1 else Vector2i.RIGHT)
	for d in dirs:
		if grid.can_move(self, col + d.x, row + d.y):
			grid.try_move(self, d)
			break

## An attack decision: kit discipline first, then pick the fire mode and wind up.
func _ai_try_attack(ai: Dictionary) -> void:
	var lvl := int(ai.get("level", 0))
	# self-damaging shooters rest at 25% HP and resume above 35%
	if passive == "overheat" or primary == "ember":
		if hp <= max_hp * 0.25:
			_resting = true
		elif hp > max_hp * 0.35:
			_resting = false
		if _resting:
			_ai_attack = 0.5
			return
	# the squad lets its energy refill rather than starving itself (a mark burst
	# already under way keeps its budget)
	if grid.ai_recovering(team) and _burst_left == 0:
		_ai_attack = 0.4
		return
	# Standard Guard (level 1+): settle 1.5s for Braced's cheap shots, unless hurt
	if passive == "braced" and lvl >= 1 and hp > max_hp * 0.4 and grid.time - last_moved_at < 1.5:
		_ai_attack = 1.55 - (grid.time - last_moved_at)
		return
	# fire mode: a lone leader uses its squad's weapon when that's what lands
	_alt_next = false
	var lands: bool = grid.ai_shot_lands(self)
	if alt_primary != "" and grid.ai_alt_lands(self) and (not lands or randf() < 0.5) \
			and grid.team_energy[team].value >= grid.alt_cost(self):
		_alt_next = true
		lands = true
	# Captain Everafter: don't reset a mark that's waiting to detonate
	if passive == "interval_mark" and not _alt_next and grid.ai_only_marked(self):
		lands = false
	if not lands:
		_burst_left = 0     # the lane is lost: abandon a burst
	if not lands and randf() < float(ai.get("aim", 0.0)):
		_ai_attack = 0.25   # nothing to hit: look again soon
		return
	# level 2+: a marker fires three shots 1.4s apart to land its mark inside 4s
	# (one burst per squad every 6s, with 24 energy to fund it)
	if (passive == "analysis" or passive == "interval_mark") and int(ai.get("level", 0)) >= 2 \
			and _burst_left == 0 and lands and not _alt_next and grid.time - grid._burst_at >= 6.0 \
			and grid.team_energy[team].value >= 24.0:
		_burst_left = 3
		grid._burst_at = grid.time
	var mode := alt_primary if _alt_next else primary
	if mode == "charge" and grid.team_energy[team].value < 20.0:
		_ai_attack = 0.4    # a beam needs a real budget
		return
	if _alt_next or grid.can_afford_primary(self):
		_telegraph = ai["telegraph"]
		sprite.play_windup(_telegraph)
