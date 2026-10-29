extends SceneTree
## Composes the game's built-in music and renders each piece to a seamless looping WAV
## in assets/music/gen/. It uses Sfx's oscillators, so it sounds of a piece with the
## effects. Every piece has 16 bars: an A section (its progression twice), then a B
## section (a second progression, fuller drums, the lead an octave up), then it loops.
## Melodies come from a seeded motif. A two-bar idea is answered by a variation that
## fits the next chords, and strong beats always land on chord tones. Re-running
## gives the same music.
##
##   godot --headless --path . -s tools/compose_music.gd            (all pieces)
##   godot --headless --path . -s tools/compose_music.gd -- terran  (one piece)

const OUT := "res://assets/music/gen/"
const RATE := 22050
const SCALES := {
	"minor": [0, 2, 3, 5, 7, 8, 10],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
	"harmonic": [0, 2, 3, 5, 7, 8, 11],
}

## Pieces. root: MIDI note of the key; prog_a / prog_b: scale degree per bar (0 = i);
## drums: 16 steps per bar (x = hit, o = soft hit), [A, B]; bass: per-step "r" root,
## "o" octave, "f" fifth, "." rest; arp: chord-tone order, "" = no arp; lead: wave,
## notes per bar (density); pad: on/off; echo: [delay in steps, feedback]; crush: grit.
const PIECES := {
	"menu": {"bpm": 92, "root": 57, "scale": "minor", "prog_a": [0, 5, 2, 6], "prog_b": [3, 0, 4, 4],
		"kick": ["x.......x.......", "x.......x...x..."], "snare": ["................", "....x.......x..."],
		"hat": ["..o...o...o...o.", "o.o.o.o.o.o.o.o."], "bass": "r.......r...o...",
		"arp": [0, 1, 2, 3, 2, 1], "arp_wave": "tri", "lead": "tri", "density": 3, "pad": true,
		"echo": [3, 0.45], "crush": 0, "swing": 0.0},
	"map": {"bpm": 100, "root": 55, "scale": "dorian", "prog_a": [0, 3, 0, 4], "prog_b": [5, 3, 6, 4],
		"kick": ["x.....x...x.....", "x.....x...x...x."], "snare": ["....x.......x...", "....x.......x..x"],
		"hat": ["x.x.x.x.x.x.x.x.", "xxx.xxx.xxx.xxx."], "bass": "r..r..o.r..r..f.",
		"arp": [0, 2, 1, 2], "arp_wave": "square", "lead": "square", "density": 4, "pad": true,
		"echo": [3, 0.3], "crush": 0, "swing": 0.08},
	"terran": {"bpm": 132, "root": 52, "scale": "minor", "prog_a": [0, 0, 5, 6], "prog_b": [3, 4, 5, 4],
		"kick": ["x...x...x...x...", "x...x...x...x.x."], "snare": ["....x.......x...", "....x..o....x.xx"],
		"hat": ["x.x.x.x.x.x.x.x.", "xxxxxxxxxxxxxxxx"], "bass": "r.rr.r.rr.rr.r.o",
		"arp": [], "arp_wave": "square", "lead": "saw", "density": 4, "pad": false,
		"echo": [2, 0.2], "crush": 6, "swing": 0.0},
	"ascendancy": {"bpm": 124, "root": 50, "scale": "dorian", "prog_a": [0, 6, 5, 6], "prog_b": [3, 4, 0, 4],
		"kick": ["x.......x.......", "x...x...x...x..."], "snare": ["....x.......x...", "....x.......x..o"],
		"hat": ["..x...x...x...x.", "x.xxx.xxx.xxx.xx"], "bass": "r...o...r...o.o.",
		"arp": [0, 1, 2, 3, 2, 1, 2, 3], "arp_wave": "sine", "lead": "tri", "density": 3, "pad": true,
		"echo": [3, 0.4], "crush": 0, "swing": 0.0},
	"manyworlds": {"bpm": 112, "root": 54, "scale": "dorian", "prog_a": [0, 3, 6, 3], "prog_b": [5, 6, 0, 4],
		"kick": ["x..x....x..x....", "x..x..x.x..x..x."], "snare": ["....x.......x...", "....x..o....x.o."],
		"hat": ["x.ox.ox.x.ox.ox.", "xoxxoxxoxoxxoxxo"], "bass": "r..o..r.f..o..r.",
		"arp": [0, 2, 1, 3], "arp_wave": "tri", "lead": "square", "density": 5, "pad": true,
		"echo": [3, 0.35], "crush": 0, "swing": 0.16},
	"long": {"bpm": 108, "root": 48, "scale": "phrygian", "prog_a": [0, 1, 0, 6], "prog_b": [5, 1, 4, 0],
		"kick": ["x.......x.......", "x.....x.x......."], "snare": ["........x.......", "....x.......x..."],
		"hat": ["....o.......o...", "..o...o...o...o."], "bass": "r.......r..f....",
		"arp": [0, 2, 1, 2, 3, 2], "arp_wave": "saw", "lead": "saw", "density": 2, "pad": true,
		"echo": [4, 0.55], "crush": 0, "swing": 0.0},
	"commander": {"bpm": 144, "root": 52, "scale": "harmonic", "prog_a": [0, 5, 3, 4], "prog_b": [0, 1, 5, 4],
		"kick": ["x.x.x...x.x.x...", "x.xxx.x.x.xxx.xx"], "snare": ["....x.......x...", "....x..x....x.xx"],
		"hat": ["xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx"], "bass": "rrorrrorrrofrror",
		"arp": [0, 1, 2, 3], "arp_wave": "square", "lead": "saw", "density": 6, "pad": true,
		"echo": [2, 0.25], "crush": 8, "swing": 0.0},
}

var rng := RandomNumberGenerator.new()

func _initialize():
	var only := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for id in PIECES:
		if only.is_empty() or id in only:
			var t := Time.get_ticks_msec()
			var w := compose(id)
			w.save_to_wav(OUT + id + ".wav")
			print("%s: %.1fs of music in %.1fs" % [id, w.get_length(), (Time.get_ticks_msec() - t) / 1000.0])
	quit()

# --- composition ---------------------------------------------------------------------

func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

## MIDI note of scale degree `deg` (any integer; wraps into octaves) above `root`.
func degree(p: Dictionary, deg: int) -> int:
	var sc: Array = SCALES[p["scale"]]
	var oct := floori(deg / 7.0)
	return int(p["root"]) + sc[posmod(deg, 7)] + 12 * oct

## Chord tones (as scale degrees) of the chord on degree `d`: 1-3-5-7.
func chord(d: int) -> Array:
	return [d, d + 2, d + 4, d + 6]

func compose(id: String) -> AudioStreamWAV:
	var p: Dictionary = PIECES[id]
	rng.seed = hash(id)
	var step: float = 60.0 / float(p["bpm"]) / 4.0           # a 16th note
	var bar: float = step * 16.0
	var prog: Array = p["prog_a"] + p["prog_a"] + p["prog_b"] + p["prog_b"]
	var layers: Array = []
	var lead := _melody(p, prog)
	for b in prog.size():
		var section := 0 if b < 8 else 1
		var t0: float = b * bar
		var ch := chord(prog[b])
		var fill := b % 4 == 3
		# drums
		for s in 16:
			var at: float = t0 + _swing(p, s) * step
			var k: String = p["kick"][section][s]
			if k != ".":
				layers.append(_kick(at, 1.0 if k == "x" else 0.6))
			var sn: String = p["snare"][section][s]
			if fill and s >= 12 and section == 1:
				sn = "x"   # a roll into the next phrase
			if sn != ".":
				layers.append_array(_snare(at, 1.0 if sn == "x" else 0.5, p["crush"]))
			var hh: String = p["hat"][section][s]
			if hh != ".":
				layers.append(_hat(at, hh == "o"))
		# bass
		var bass: String = p["bass"]
		for s in 16:
			var c := bass[s]
			if c == ".":
				continue
			var n := degree(p, ch[0]) - 24
			if c == "o":
				n += 12
			elif c == "f":
				n = degree(p, ch[2]) - 24
			var span := 1
			while s + span < 16 and bass[s + span] == ".":
				span += 1
			layers.append_array(_bass(t0 + _swing(p, s) * step, step * minf(span, 4) * 0.95, hz(n), p["crush"]))
		# pad: the chord, held for the bar (B section only on the first pass of menu-like pieces)
		if p["pad"]:
			for d in ch.slice(0, 3):
				layers.append(_pad(t0, bar, hz(degree(p, d) - 12)))
		# arpeggio: 16ths through the chord, an octave up in the B section
		var arp: Array = p["arp"]
		if not arp.is_empty():
			for s in 16:
				var d: int = ch[arp[s % arp.size()]]
				layers.append(_arp(t0 + _swing(p, s) * step, step * 0.9, hz(degree(p, d) + 12 * section), p["arp_wave"]))
	for n in lead:
		layers.append(_lead(n[0] * step, n[1] * step, hz(n[2]), p["lead"]))
	var loop_len: float = prog.size() * bar
	return _render(layers, loop_len, p["echo"][0] * step, p["echo"][1])

## Steps on the off-beat 16ths get pushed late by the piece's swing.
func _swing(p: Dictionary, s: int) -> float:
	return s + (p["swing"] if s % 2 == 1 else 0.0)

## Lead melody as [start step, length in steps, midi] over the whole progression.
## Bars 1-2 state a motif; 3-4 answer it shifted to fit their chords; the B section
## climbs an octave and varies the rhythm; the last bar of each half resolves home.
func _melody(p: Dictionary, prog: Array) -> Array:
	var notes: Array = []
	var motif := _motif(p)
	for b in prog.size():
		var phrase_bar := b % 2
		var ch := chord(prog[b])
		var section := 0 if b < 8 else 1
		# bars 4 and 8 of each half: hold out a chord tone (breathing room)
		if b % 4 == 3:
			var held := degree(p, ch[0 if b % 8 == 7 else 2]) + 12 + 12 * section
			notes.append([b * 16, 8, held])
			if section == 1:
				notes.append([b * 16 + 10, 2, degree(p, ch[1]) + 24])
				notes.append([b * 16 + 12, 4, degree(p, ch[2]) + 24])
			continue
		for m in motif[phrase_bar]:
			var at: int = m[0]
			var deg: int = ch[0] + m[2] + (1 if section == 1 and b % 2 == 1 and m[0] % 8 == 6 else 0)
			if at % 4 == 0:
				deg = _nearest_chord_tone(deg, ch)   # strong beats land on the chord
			var midi := degree(p, deg) + 12 + 12 * section
			notes.append([b * 16 + at, m[1], midi])
	return notes

func _nearest_chord_tone(deg: int, ch: Array) -> int:
	var best: int = ch[0]
	for c in ch:
		for o in [-7, 0, 7]:
			if absi(c + o - deg) < absi(best - deg):
				best = c + o
	return best

## Two bars of rhythm + contour: [[step, length, degree offset from the chord root]].
func _motif(p: Dictionary) -> Array:
	var out := []
	for half in 2:
		var bar_notes := []
		var s := 0
		var deg := rng.randi_range(0, 4)
		var n: int = p["density"]
		while s < 16:
			var span: int = [2, 2, 4, 2, 3, 1, 6][rng.randi() % 7] if n >= 4 else [4, 4, 6, 2, 8][rng.randi() % 5]
			if rng.randf() < 0.85 or s == 0:
				bar_notes.append([s, mini(span, 16 - s), deg])
			deg += [-2, -1, -1, 1, 1, 2, 0, 3][rng.randi() % 8]
			deg = clampi(deg, -2, 7)
			s += span
		out.append(bar_notes)
	return out

# --- instruments (Sfx layer recipes) ---------------------------------------------------

func _kick(at: float, v: float) -> Dictionary:
	return {"w": "sine", "f": [160.0, 42.0], "d": 0.28, "v": 0.95 * v, "curve": 2.5, "at": at}

func _snare(at: float, v: float, crush: int) -> Array:
	return [{"w": "noise", "f": [9000.0, 4000.0], "d": 0.16, "v": 0.38 * v, "lp": 0.55, "curve": 2.5, "at": at, "crush": crush},
		{"w": "tri", "f": [240.0, 170.0], "d": 0.08, "v": 0.3 * v, "curve": 2.0, "at": at}]

func _hat(at: float, open: bool) -> Dictionary:
	return {"w": "noise", "f": [11000.0, 11000.0], "d": 0.13 if open else 0.035, "v": 0.11 if open else 0.13, "curve": 3.0, "at": at}

func _bass(at: float, d: float, f: float, crush: int) -> Array:
	return [{"w": "saw", "f": [f, f], "d": d, "v": 0.32, "lp": 0.1, "curve": 0.7, "a": 0.005, "at": at, "crush": crush},
		{"w": "square", "f": [f * 0.5, f * 0.5], "d": d, "v": 0.14, "lp": 0.06, "curve": 0.7, "a": 0.005, "at": at}]

func _pad(at: float, d: float, f: float) -> Dictionary:
	return {"w": "saw", "f": [f, f], "d": d * 1.05, "v": 0.055, "lp": 0.05, "curve": 0.4, "a": 0.35, "at": at, "vib": [0.3, 0.003]}

func _arp(at: float, d: float, f: float, wave: String) -> Dictionary:
	return {"w": wave, "f": [f, f], "d": d, "v": 0.09, "lp": 0.35, "duty": 0.25, "curve": 1.6, "a": 0.003, "at": at}

func _lead(at: float, d: float, f: float, wave: String) -> Dictionary:
	return {"w": wave, "f": [f, f], "d": d * 0.95, "v": 0.15, "lp": 0.22, "duty": 0.5, "curve": 0.45, "a": 0.012, "at": at, "vib": [5.5, 0.005]}

# --- rendering -----------------------------------------------------------------------

## Mix every layer into a loop of `length` seconds. Anything ringing past the end wraps
## round to the start, and the echo runs round the loop too, so the seam is inaudible.
func _render(layers: Array, length: float, echo_delay: float, echo_fb: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var tail := int(2.0 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + tail)
	var sfx = root.get_node("Sfx")
	for l in layers:
		sfx._layer(buf, l)
	for i in tail:
		buf[i] += buf[n + i]
	buf.resize(n)
	if echo_fb > 0.0:
		var dl := int(echo_delay * RATE)
		var wet := PackedFloat32Array()
		wet.resize(n)
		for pass_i in 3:   # three trips round the loop settle the feedback
			for i in n:
				wet[i] = (buf[posmod(i - dl, n)] + wet[posmod(i - dl, n)]) * echo_fb * 0.5
		for i in n:
			buf[i] += wet[i]
	var peak := 0.0001
	for x in buf:
		peak = maxf(peak, absf(x))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var s := tanh(buf[i] / peak * 1.3) * 0.86   # gentle glue, never clips
		bytes.encode_s16(i * 2, int(s * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
