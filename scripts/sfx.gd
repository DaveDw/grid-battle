extends Node
## Sound effects, synthesized in code (no audio files): every sound is a recipe of
## layered oscillators rendered once into an AudioStreamWAV and cached. Autoload "Sfx".
##
## Each faction has a timbre (Terran gritty and ballistic, Ascendancy clean lasers,
## Manyworlds wet and organic, Long Tomorrow ragged and cosmic). A unit's shot is its
## faction's timbre shaped by its primary, pitched by role (heavies lower), plus a small
## fixed offset from its name so no two units sound quite alike. Cards sound by what
## they do (heal, shield, terrain, strike...) in the timbre of the card's faction.
##
## Recipe: Array of layers. Layer keys (all optional but w/d):
##   w: "sine" | "square" | "saw" | "tri" | "noise"     d: seconds
##   f: [start Hz, end Hz] (exponential sweep)          v: volume 0..1
##   a: attack s   curve: decay exponent (1 = linear, higher = punchier)
##   at: start offset s   vib: [rate Hz, depth 0..1]   duty: square duty 0..1
##   lp: one-pole low-pass 0..1 (lower = darker)   crush: bit-crush steps (0 = off)
## A recipe may end with {"echo": [delay s, feedback, repeats]}.

const RATE := 22050
const VOICES := 14

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}          # key -> msec, to stop the same sound stacking in a frame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	apply_volume()
	# UI: a tick when focus moves, a click when any button is pressed (hooked globally)
	get_viewport().gui_focus_changed.connect(func(_c): play("ui_move", ui_move(), 0.0, -6.0))
	get_tree().node_added.connect(_on_node_added)

func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus < 0:
		return   # settings applied before this autoload is ready; _ready applies them
	var v := float(Game.settings.get("sfx_volume", 0.8))
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))

var _silent := false

## Render a battle's sounds up front (each is ~10 ms to synthesize), so the first shot
## or card of each kind doesn't hitch mid-fight.
func warm(units: Array, cards: Array) -> void:
	_silent = true
	for u in units:
		unit_fire(u)
		unit_hit(u)
		unit_death(u)
		unit_step(u)
	for id in cards:
		card(id, 0)
		card(id, 1)
	_silent = false

func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		(n as BaseButton).pressed.connect(func(): play("ui_press", ui_press()))

# --- playback ------------------------------------------------------------------------

## Play recipe `r` (cached under `key`). `jitter`: random pitch spread; `db`: gain.
func play(key: String, r: Array, jitter := 0.04, db := 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _silent:
		if not _cache.has(key):
			_cache[key] = render(r)
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(key, -1000)) < 30:
		return
	_last_played[key] = now
	if not _cache.has(key):
		_cache[key] = render(r)
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _cache[key]
	p.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	p.volume_db = db
	p.play()

## Render a recipe to a 16-bit mono WAV.
func render(r: Array) -> AudioStreamWAV:
	var echo: Array = []
	var total := 0.0
	for l in r:
		if l.has("echo"):
			echo = l["echo"]
		else:
			total = maxf(total, l.get("at", 0.0) + l["d"])
	if not echo.is_empty():
		total += echo[0] * echo[2]
	var n := int(total * RATE) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	for l in r:
		if not l.has("echo"):
			_layer(buf, l)
	if not echo.is_empty():
		var dl := int(echo[0] * RATE)
		for i in range(dl, n):
			buf[i] += buf[i - dl] * echo[1]
	var peak := 0.0001
	for x in buf:
		peak = maxf(peak, absf(x))
	var gain := 0.85 / maxf(peak, 0.85)   # only scale down, never boost quiet recipes
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w

func _layer(buf: PackedFloat32Array, l: Dictionary) -> void:
	var start := int(l.get("at", 0.0) * RATE)
	var count := int(l["d"] * RATE)
	var f: Array = l.get("f", [440.0, 440.0])
	var vol: float = l.get("v", 0.5)
	var attack: float = maxf(l.get("a", 0.004), 0.001)
	var curve: float = l.get("curve", 2.0)
	var vib: Array = l.get("vib", [0.0, 0.0])
	var duty: float = l.get("duty", 0.5)
	var lp: float = l.get("lp", 1.0)
	var crush: int = l.get("crush", 0)
	var w: String = l["w"]
	var phase := 0.0
	var low := 0.0
	var noise_hold := 0.0
	for i in count:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var k := float(i) / count
		var freq: float = f[0] * pow(f[1] / f[0], k)
		if vib[1] > 0.0:
			freq *= 1.0 + vib[1] * sin(TAU * vib[0] * t)
		phase = fmod(phase + freq / RATE, 1.0)
		var s := 0.0
		match w:
			"sine": s = sin(TAU * phase)
			"square": s = 1.0 if phase < duty else -1.0
			"saw": s = 2.0 * phase - 1.0
			"tri": s = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				# sample-and-hold noise: the "frequency" sets how grainy it is
				if phase < freq / RATE:
					noise_hold = randf_range(-1.0, 1.0)
				s = noise_hold
		if crush > 0:
			s = round(s * crush) / crush
		low += (s - low) * lp
		var env := minf(t / attack, 1.0) * pow(1.0 - k, curve)
		buf[idx] += low * env * vol

# --- recipes -------------------------------------------------------------------------

## A stable -1..1 offset per name (so each unit keeps its own voice).
func _vary(name: String) -> float:
	return float(absi(hash(name)) % 1000) / 500.0 - 1.0

func _role_pitch(role: String) -> float:
	return {"heavy": 0.7, "leader": 1.0, "light": 1.3}.get(role, 1.0)

## The unit's primary fire. `u` is a Unit.
func unit_fire(u) -> void:
	var faction: String = u.key.get_slice("/", 0)
	var key: String = "fire:" + u.key
	play(key, fire_recipe(faction, u.primary, _role_pitch(u.role) * (1.0 + 0.08 * _vary(u.key))), 0.05, -3.0)

func fire_recipe(faction: String, primary: String, p: float) -> Array:
	match primary:
		"mortar":
			return [{"w": "noise", "f": [3000, 600], "d": 0.25, "v": 0.7, "lp": 0.4, "curve": 3.0},
				{"w": "sine", "f": [110 * p, 45 * p], "d": 0.3, "v": 0.9, "curve": 2.0},
				{"w": "square", "f": [300 * p, 900 * p], "d": 0.35, "v": 0.12, "at": 0.08, "duty": 0.3}]
		"charge":
			return [{"w": "saw", "f": [140 * p, 70 * p], "d": 0.45, "v": 0.5, "lp": 0.3, "curve": 1.5},
				{"w": "sine", "f": [900 * p, 300 * p], "d": 0.4, "v": 0.5, "vib": [30, 0.05]},
				{"w": "noise", "f": [8000, 2000], "d": 0.2, "v": 0.3, "lp": 0.6}]
		"courtesy":
			return [{"w": "sine", "f": [1320 * p, 1320 * p], "d": 0.08, "v": 0.4},
				{"w": "sine", "f": [990 * p, 990 * p], "d": 0.12, "v": 0.4, "at": 0.07},
				{"w": "tri", "f": [700 * p, 350 * p], "d": 0.14, "v": 0.4, "at": 0.12}]
		"undertow":
			return [{"w": "sine", "f": [180 * p, 420 * p], "d": 0.3, "v": 0.7, "vib": [18, 0.12], "curve": 1.5},
				{"w": "noise", "f": [2500, 800], "d": 0.3, "v": 0.35, "lp": 0.15}]
		"refraction":
			return [{"w": "tri", "f": [1600 * p, 1200 * p], "d": 0.25, "v": 0.45},
				{"w": "tri", "f": [2400 * p, 1800 * p], "d": 0.25, "v": 0.3, "at": 0.03},
				{"w": "sine", "f": [3200 * p, 2600 * p], "d": 0.3, "v": 0.2, "at": 0.06},
				{"echo": [0.06, 0.35, 3]}]
		"ember":
			return [{"w": "noise", "f": [6000, 1500], "d": 0.3, "v": 0.6, "lp": 0.5, "curve": 1.2},
				{"w": "saw", "f": [400 * p, 120 * p], "d": 0.22, "v": 0.35, "crush": 6}]
		"afterimage":
			return [{"w": "saw", "f": [700 * p, 350 * p], "d": 0.16, "v": 0.45, "lp": 0.5, "crush": 5},
				{"w": "saw", "f": [700 * p, 350 * p], "d": 0.16, "v": 0.25, "lp": 0.5, "crush": 5, "at": 0.09},
				{"echo": [0.09, 0.3, 2]}]
	# "standard", in the faction's timbre
	match faction:
		"terran":   # gunshot: crack of noise over a thump
			return [{"w": "noise", "f": [9000, 3000], "d": 0.12, "v": 0.8, "lp": 0.7, "curve": 4.0},
				{"w": "square", "f": [220 * p, 70 * p], "d": 0.1, "v": 0.5, "duty": 0.25, "curve": 3.0}]
		"ascendancy":   # clean laser zap
			return [{"w": "sine", "f": [1800 * p, 500 * p], "d": 0.14, "v": 0.7, "curve": 1.5},
				{"w": "square", "f": [900 * p, 250 * p], "d": 0.1, "v": 0.18, "duty": 0.12}]
		"manyworlds":   # wet spit / bubble pop
			return [{"w": "sine", "f": [300 * p, 900 * p], "d": 0.12, "v": 0.7, "vib": [40, 0.1]},
				{"w": "noise", "f": [3000, 1200], "d": 0.08, "v": 0.3, "lp": 0.2}]
		"long":   # ragged, crushed blast with a tail
			return [{"w": "saw", "f": [600 * p, 150 * p], "d": 0.18, "v": 0.6, "crush": 4, "lp": 0.6},
				{"w": "noise", "f": [5000, 1000], "d": 0.12, "v": 0.35, "lp": 0.5},
				{"echo": [0.07, 0.3, 2]}]
	return [{"w": "square", "f": [800 * p, 300 * p], "d": 0.1, "v": 0.5}]

## Taking a hit: a faction-flavoured impact, pitched by role.
func unit_hit(u) -> void:
	var faction: String = u.key.get_slice("/", 0)
	var p := _role_pitch(u.role)
	var r: Array
	match faction:
		"terran": r = [{"w": "noise", "f": [4000, 800], "d": 0.1, "v": 0.6, "lp": 0.4, "curve": 3.0}, {"w": "square", "f": [160 * p, 90 * p], "d": 0.08, "v": 0.3, "duty": 0.3}]
		"ascendancy": r = [{"w": "square", "f": [600 * p, 300 * p], "d": 0.07, "v": 0.35, "duty": 0.1, "crush": 3}, {"w": "noise", "f": [9000, 4000], "d": 0.05, "v": 0.3}]
		"manyworlds": r = [{"w": "sine", "f": [220 * p, 110 * p], "d": 0.12, "v": 0.6, "vib": [25, 0.15]}, {"w": "noise", "f": [1500, 500], "d": 0.08, "v": 0.3, "lp": 0.15}]
		_: r = [{"w": "saw", "f": [300 * p, 100 * p], "d": 0.12, "v": 0.45, "crush": 3}, {"w": "noise", "f": [3000, 900], "d": 0.08, "v": 0.3}]
	play("hit:%s:%s" % [faction, u.role], r, 0.08, -5.0)

func unit_death(u) -> void:
	var faction: String = u.key.get_slice("/", 0)
	var p := _role_pitch(u.role)
	var tone: String = {"terran": "square", "ascendancy": "sine", "manyworlds": "tri", "long": "saw"}.get(faction, "square")
	play("death:%s:%s" % [faction, u.role], [
		{"w": tone, "f": [500 * p, 60 * p], "d": 0.7, "v": 0.5, "curve": 1.2, "lp": 0.5},
		{"w": "noise", "f": [6000, 300], "d": 0.6, "v": 0.5, "lp": 0.35, "curve": 1.5},
		{"w": "sine", "f": [90, 40], "d": 0.5, "v": 0.6, "at": 0.05}], 0.03)

func unit_step(u) -> void:
	var p := _role_pitch(u.role)
	play("step:" + u.role, [{"w": "noise", "f": [1800 * p, 900 * p], "d": 0.05, "v": 0.4, "lp": 0.25, "curve": 3.0},
		{"w": "sine", "f": [150 * p, 90 * p], "d": 0.05, "v": 0.3}], 0.1, -12.0)

## A card being played, by what it does, in its faction's timbre.
const CARD_KIND := {
	"fortify": "shield", "sandbags": "build", "stake_claim": "build", "claim": "build", "hold_the_line": "shield",
	"barrage": "strike", "requisition": "draw", "suppressing_fire": "strike",
	"deploy_drone": "build", "issue_protocol": "debuff", "overclock": "power", "containment": "debuff",
	"target_lock": "debuff", "shield_drone": "shield", "recompile": "draw", "firewall": "debuff",
	"flood": "terrain", "spore_bloom": "terrain", "riptide": "pull", "mire": "terrain", "undertow_surge": "pull",
	"regrowth": "heal", "mudslide": "terrain", "mycelial_link": "heal", "medpod": "heal",
	"void_orb": "debuff", "borrowed_time": "power", "rewind": "time", "last_stand": "shield",
	"burn_bright": "power", "echo_strike": "strike", "supernova": "strike",
	"supply_drop": "build", "dig_in": "shield", "data_breach": "debuff", "tide_pool": "heal",
	"flash_forward": "time", "collapse": "strike",
}

func card(id: String, team: int) -> void:
	var kind: String = CARD_KIND.get(id, "power")
	var faction: String = Game.card_faction(id)
	var tone: String = {"terran": "square", "ascendancy": "sine", "manyworlds": "tri", "long": "saw"}.get(faction, "square")
	var base: float = {"terran": 1.0, "ascendancy": 1.5, "manyworlds": 0.85, "long": 0.75}.get(faction, 1.0) * (1.0 + 0.05 * _vary(id))
	var r: Array
	match kind:
		"heal":
			r = [{"w": tone, "f": [520 * base, 520 * base], "d": 0.12, "v": 0.35, "lp": 0.5},
				{"w": tone, "f": [660 * base, 660 * base], "d": 0.12, "v": 0.35, "lp": 0.5, "at": 0.09},
				{"w": tone, "f": [780 * base, 780 * base], "d": 0.3, "v": 0.35, "lp": 0.5, "at": 0.18},
				{"w": "sine", "f": [1560 * base, 1560 * base], "d": 0.35, "v": 0.15, "at": 0.18, "vib": [6, 0.01]}]
		"shield":
			r = [{"w": "sine", "f": [200 * base, 600 * base], "d": 0.25, "v": 0.5, "curve": 0.8},
				{"w": tone, "f": [400 * base, 1200 * base], "d": 0.3, "v": 0.2, "lp": 0.3},
				{"w": "sine", "f": [1200 * base, 1200 * base], "d": 0.3, "v": 0.25, "at": 0.2, "vib": [12, 0.02]}]
		"build":
			r = [{"w": "noise", "f": [1200, 600], "d": 0.08, "v": 0.5, "lp": 0.3, "curve": 3.0},
				{"w": "square", "f": [140 * base, 100 * base], "d": 0.1, "v": 0.35, "duty": 0.3},
				{"w": "noise", "f": [1200, 600], "d": 0.08, "v": 0.4, "lp": 0.3, "curve": 3.0, "at": 0.12},
				{"w": "square", "f": [180 * base, 120 * base], "d": 0.1, "v": 0.3, "duty": 0.3, "at": 0.12}]
		"strike":
			r = [{"w": tone, "f": [900 * base, 150 * base], "d": 0.35, "v": 0.45, "lp": 0.6},
				{"w": "noise", "f": [6000, 600], "d": 0.4, "v": 0.45, "lp": 0.4, "curve": 1.5},
				{"w": "sine", "f": [100, 45], "d": 0.35, "v": 0.6, "at": 0.05}]
		"draw":
			r = [{"w": "noise", "f": [8000, 3000], "d": 0.12, "v": 0.3, "lp": 0.5, "curve": 1.0},
				{"w": tone, "f": [800 * base, 1400 * base], "d": 0.1, "v": 0.25, "lp": 0.5, "at": 0.06}]
		"debuff":
			r = [{"w": tone, "f": [600 * base, 300 * base], "d": 0.3, "v": 0.35, "vib": [9, 0.08], "lp": 0.5},
				{"w": tone, "f": [635 * base, 318 * base], "d": 0.3, "v": 0.3, "vib": [9, 0.08], "lp": 0.5},
				{"w": "noise", "f": [3000, 3000], "d": 0.3, "v": 0.12, "lp": 0.3}]
		"terrain":
			r = [{"w": "noise", "f": [900, 300], "d": 0.5, "v": 0.55, "lp": 0.12, "curve": 1.2},
				{"w": tone, "f": [160 * base, 90 * base], "d": 0.45, "v": 0.35, "vib": [7, 0.1], "lp": 0.3}]
		"pull":
			r = [{"w": tone, "f": [180 * base, 520 * base], "d": 0.25, "v": 0.4, "lp": 0.4},
				{"w": "noise", "f": [2000, 900], "d": 0.3, "v": 0.35, "lp": 0.18},
				{"w": "sine", "f": [520 * base, 200 * base], "d": 0.15, "v": 0.3, "at": 0.22}]
		"time":
			r = [{"w": "sine", "f": [1200 * base, 300 * base], "d": 0.4, "v": 0.45, "vib": [14, 0.05]},
				{"echo": [0.08, 0.45, 4]}]
		_:   # power
			r = [{"w": tone, "f": [200 * base, 1000 * base], "d": 0.25, "v": 0.45, "lp": 0.5, "curve": 1.0},
				{"w": "square", "f": [1000 * base, 1000 * base], "d": 0.1, "v": 0.2, "duty": 0.2, "at": 0.2}]
	# the enemy's cards sound a little lower and further away
	if team == 1:
		for l in r:
			if l.has("f"):
				l["f"] = [l["f"][0] * 0.85, l["f"][1] * 0.85]
	play("card:%s:%d" % [id, team], r, 0.02, 0.0 if team == 0 else -4.0)

# --- small one-offs ------------------------------------------------------------------

func ui_move() -> Array:
	return [{"w": "square", "f": [1400, 1400], "d": 0.025, "v": 0.25, "duty": 0.25}]

func ui_press() -> Array:
	return [{"w": "square", "f": [700, 700], "d": 0.04, "v": 0.3, "duty": 0.25},
		{"w": "square", "f": [1050, 1050], "d": 0.06, "v": 0.3, "duty": 0.25, "at": 0.04}]

func denied() -> void:
	play("denied", [{"w": "square", "f": [180, 150], "d": 0.12, "v": 0.35, "duty": 0.5},
		{"w": "square", "f": [140, 120], "d": 0.12, "v": 0.35, "duty": 0.5, "at": 0.1}], 0.0, -6.0)

func card_drawn() -> void:
	play("draw", [{"w": "noise", "f": [7000, 3500], "d": 0.07, "v": 0.3, "lp": 0.6, "curve": 1.0}], 0.1, -10.0)

func card_burned() -> void:
	play("burn", [{"w": "noise", "f": [5000, 400], "d": 0.45, "v": 0.5, "lp": 0.45, "curve": 1.2},
		{"w": "saw", "f": [300, 80], "d": 0.35, "v": 0.3, "crush": 4}], 0.05, -4.0)

func shell_land() -> void:
	play("shell", [{"w": "noise", "f": [4000, 200], "d": 0.45, "v": 0.8, "lp": 0.3, "curve": 2.0},
		{"w": "sine", "f": [80, 35], "d": 0.4, "v": 0.9}], 0.08, -2.0)

func doctrine() -> void:
	play("doctrine", [{"w": "saw", "f": [220, 220], "d": 0.5, "v": 0.3, "lp": 0.2, "vib": [5, 0.03]},
		{"w": "saw", "f": [233, 233], "d": 0.5, "v": 0.3, "lp": 0.2},
		{"w": "square", "f": [110, 110], "d": 0.6, "v": 0.3, "duty": 0.3, "lp": 0.3}], 0.0, -3.0)

func stinger(won: bool) -> void:
	var notes: Array = [523.0, 659.0, 784.0, 1047.0] if won else [392.0, 330.0, 262.0, 196.0]
	var r: Array = []
	for i in notes.size():
		r.append({"w": "square", "f": [notes[i], notes[i]], "d": 0.35 if i == 3 else 0.16, "v": 0.3, "duty": 0.25, "at": i * 0.13, "lp": 0.6})
		r.append({"w": "tri", "f": [notes[i] / 2, notes[i] / 2], "d": 0.35 if i == 3 else 0.16, "v": 0.3, "at": i * 0.13})
	play("stinger:%s" % won, r, 0.0)
