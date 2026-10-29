extends SceneTree
## Lays a synthesized drum track under an existing song.
##   godot --headless -s beat_layer.gd -- <in.mp3> <out.wav> <bpm> <offset s> [style]
## style: "industrial" (default) or "trap".
## The beat follows the song's loudness bar by bar: quiet bars get a heartbeat kick,
## loud bars the full pattern. Every 8 bars there's an impact on the downbeat.
## Industrial: broken kick, clap-snare on 2 and 4, 16th hats, tom fill into each phrase.
## Trap: half-time clap on 3, rolling hats (32nds and triplets), and a distorted 808
## that plays the song's own bass note, found per bar. The 808 drops out for the last
## beat of each phrase, under a snare roll.
## Kicks duck the song slightly (sidechain) so the beat sits inside it.

const SR := 44100
const KICK := ["x.....x...x.....", "x.....x.x.x....."]
const SNARE := "....x.......x..."
const HAT := "xoxoxoxoxoxoxoxo"
const TRAP_KICK := ["x......x..x.....", "x.....x...x..x.."]

var L := PackedFloat32Array()   # drum bus, left / right
var R := PackedFloat32Array()
var SN := PackedFloat32Array()  # snare bus (gets reverb)
var rng := RandomNumberGenerator.new()

func _initialize():
	var args := OS.get_cmdline_user_args()
	var bpm := float(args[2])
	var offset := float(args[3])
	rng.seed = 6
	var song := AudioStreamMP3.load_from_file(args[0])
	var pb := song.instantiate_playback()
	pb.start(0.0)
	var n := int(song.get_length() * SR)
	var mix := PackedVector2Array()
	while mix.size() < n:
		var chunk: PackedVector2Array = pb.mix_audio(1.0, 4096)
		if chunk.is_empty() or not pb.is_playing():
			break   # the decoder can stop a few samples short of get_length()
		mix.append_array(chunk)
	n = mini(n, mix.size())
	mix.resize(n)
	print("decoded ", n / float(SR), " s")
	L.resize(n)   # packed arrays are values: resize each one directly
	R.resize(n)
	SN.resize(n)
	var step := 60.0 / bpm / 4.0
	var bar := step * 16.0
	var bars := int(ceil(n / float(SR) / bar))
	# loudness per bar, relative to the median
	var loud := []
	for b in bars:
		var s0 := int((offset + b * bar) * SR)
		var acc := 0.0
		var c := 0
		for i in range(maxi(s0, 0), mini(s0 + int(bar * SR), n), 64):
			acc += mix[i].x * mix[i].x + mix[i].y * mix[i].y
			c += 1
		loud.append(sqrt(acc / maxf(c, 1)))
	var sorted := loud.duplicate()
	sorted.sort()
	var med: float = sorted[sorted.size() / 2]
	var style := args[4] if args.size() > 4 else "industrial"
	var roots := _bass_notes(mix, offset, bar, bars) if style == "trap" else []
	var kicks := []
	var subs := []   # trap 808s: [time, midi]
	for b in bars:
		var rel: float = loud[b] / med
		# 0 = heartbeat, 1 = light, 2 = full
		var lvl := 2
		if b < 4 or b >= bars - 4 or rel < 0.45:
			lvl = 0
		elif b < 8 or rel < 0.75 or b >= bars - 8:
			lvl = 1
		var t0 := offset + b * bar
		if b % 8 == 0 and lvl > 0 or b == 0:
			_impact(t0)
		if style == "trap":
			_trap_bar(b, lvl, t0, step, roots[b], kicks, subs)
			continue
		for s in 16:
			var t := t0 + s * step
			if t < 0.0:
				continue
			if lvl == 0:
				if s == 0 or s == 3:
					_kick(t, 0.8 if s == 0 else 0.45)
					kicks.append(t)
				continue
			var fill := b % 8 == 7 and lvl == 2 and s >= 12
			if KICK[b % 2][s] == "x" and not fill:
				_kick(t, 1.0)
				kicks.append(t)
			if SNARE[s] == "x":
				_snare(t, 1.0 if lvl == 2 else 0.6)
			if lvl == 2 or s % 2 == 0:
				if not (s == 14 and b % 2 == 1):
					_hat(t, 0.9 if HAT[s] == "x" else 0.5, -0.3 if s % 4 == 2 else 0.3)
			if s == 14 and b % 2 == 1:
				_open_hat(t)
			if fill:
				_tom(t, [130.0, 110.0, 90.0, 70.0][s - 12], [-0.5, -0.15, 0.15, 0.5][s - 12])
	_render_808s(subs, n)
	_reverb()
	# sidechain duck + mix
	var duck := PackedFloat32Array()
	duck.resize(n)
	duck.fill(1.0)
	for t in kicks:
		var i0 := int(t * SR)
		for i in range(maxi(i0, 0), mini(i0 + int(0.35 * SR), n)):
			duck[i] = minf(duck[i], 1.0 - 0.3 * exp(-(i - i0) / (0.11 * SR)))
	var bytes := PackedByteArray()
	bytes.resize(n * 4)
	for i in n:
		var d: float = duck[i]
		var l := mix[i].x * 0.9 * d + (L[i] + SN[i]) * 0.55
		var r := mix[i].y * 0.9 * d + (R[i] + SN[i]) * 0.55
		bytes.encode_s16(i * 4, int(tanh(l * 1.1) * 0.95 * 32767.0))
		bytes.encode_s16(i * 4 + 2, int(tanh(r * 1.1) * 0.95 * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = true
	w.data = bytes
	print("save: ", w.save_to_wav(args[1]), "  bars ", bars, "  levels median ", med)
	quit()

func _add(buf: PackedFloat32Array, i: int, v: float) -> void:
	if i >= 0 and i < buf.size():
		buf[i] += v

## Distorted sine kick with a click.
func _kick(t: float, v: float) -> void:
	var i0 := int(t * SR)
	var ph := 0.0
	for k in int(0.42 * SR):
		var x := k / float(SR)
		var f := 42.0 + 110.0 * exp(-x * 28.0)
		ph += TAU * f / SR
		var s := tanh(sin(ph) * 2.2) * exp(-x * 7.5) + rng.randf_range(-1, 1) * exp(-x * 400.0) * 0.4
		_add(L, i0 + k, s * v * 0.95)
		_add(R, i0 + k, s * v * 0.95)

## Clap-like snare: three noise bursts then a body, through a band-pass.
func _snare(t: float, v: float) -> void:
	var i0 := int(t * SR)
	var lp := 0.0
	var hp := 0.0
	for k in int(0.3 * SR):
		var x := k / float(SR)
		var env := exp(-x * 14.0)
		for burst in [0.0, 0.011, 0.022]:
			if x >= burst and x < burst + 0.009:
				env = maxf(env, 1.0 - (x - burst) / 0.009)
		var nz := rng.randf_range(-1, 1)
		lp += (nz - lp) * 0.45
		hp += (lp - hp) * 0.05
		var s := (lp - hp) * env * 1.6 + sin(TAU * 185.0 * x) * exp(-x * 30.0) * 0.35
		_add(SN, i0 + k, s * v * 0.6)

func _hat(t: float, v: float, pan: float) -> void:
	var i0 := int(t * SR)
	var prev := 0.0
	for k in int(0.05 * SR):
		var x := k / float(SR)
		var nz := rng.randf_range(-1, 1)
		var s := (nz - prev) * exp(-x * 90.0) * 0.16 * v
		prev = nz
		_add(L, i0 + k, s * (1.0 - pan * 0.5))
		_add(R, i0 + k, s * (1.0 + pan * 0.5))

func _open_hat(t: float) -> void:
	var i0 := int(t * SR)
	var prev := 0.0
	for k in int(0.25 * SR):
		var x := k / float(SR)
		var nz := rng.randf_range(-1, 1)
		var s := (nz - prev) * exp(-x * 14.0) * 0.1
		prev = nz
		_add(L, i0 + k, s)
		_add(R, i0 + k, s)

func _tom(t: float, f0: float, pan: float) -> void:
	var i0 := int(t * SR)
	var ph := 0.0
	for k in int(0.3 * SR):
		var x := k / float(SR)
		ph += TAU * f0 * (1.0 + 0.5 * exp(-x * 20.0)) / SR
		var s := tanh(sin(ph) * 1.8) * exp(-x * 10.0) * 0.6
		_add(L, i0 + k, s * (1.0 - pan))
		_add(R, i0 + k, s * (1.0 + pan))

## Phrase-start hit: deep boom plus a dark noise swell that rings out.
func _impact(t: float) -> void:
	var i0 := int(t * SR)
	var ph := 0.0
	var lp := 0.0
	for k in int(2.2 * SR):
		var x := k / float(SR)
		ph += TAU * (32.0 + 40.0 * exp(-x * 6.0)) / SR
		lp += (rng.randf_range(-1, 1) - lp) * 0.08
		var s := sin(ph) * exp(-x * 2.2) * 0.9 + lp * exp(-x * 2.8) * 0.9
		_add(L, i0 + k, s * 0.7)
		_add(R, i0 + k, s * 0.7)

## Small Schroeder reverb on the snare bus.
func _reverb() -> void:
	var n := SN.size()
	var wet := PackedFloat32Array()
	wet.resize(n)
	for d in [1557, 1617, 1491, 1422]:
		var c := PackedFloat32Array()
		c.resize(n)
		for i in n:
			c[i] = SN[i] + (c[i - d] * 0.78 if i >= d else 0.0)
		for i in n:
			wet[i] += c[i] * 0.12
	for i in n:
		SN[i] += wet[i]

# --- trap ------------------------------------------------------------------------------

func _trap_bar(b: int, lvl: int, t0: float, step: float, root: int, kicks: Array, subs: Array) -> void:
	var phrase_end := b % 8 == 7 and lvl == 2
	for s in 16:
		var t := t0 + s * step
		if t < 0.0:
			continue
		if lvl == 0:
			if s == 0:
				subs.append([t, root, 0.6])
				kicks.append(t)
			continue
		var hit: bool = TRAP_KICK[b % 2][s] == "x"
		if hit and not (phrase_end and s >= 12):
			_trap_kick(t)
			kicks.append(t)
			# octave jump on the last 808 of every other bar
			subs.append([t, root + (12 if s == 13 else 0), 1.0])
		if phrase_end and s == 12:
			subs.append([t, -1, 0.0])   # cuts the 808 for the roll
		if s == 8:
			_snare(t, 1.0 if lvl == 2 else 0.7)
		if lvl == 2 and s == 14 and b % 4 == 3:
			_snare(t, 0.35)   # ghost clap
		# hats
		if phrase_end and s >= 12:
			for k in 2:   # snare roll in 32nds, rising
				_snare(t + k * step * 0.5, 0.25 + 0.6 * ((s - 12) * 2 + k) / 8.0)
			continue
		if lvl == 1:
			if s % 2 == 0:
				_hat(t, 0.6, 0.2)
			continue
		if b % 2 == 1 and s >= 12:
			for k in 2:   # 32nd roll
				_hat(t + k * step * 0.5, 0.45 + 0.1 * k + 0.05 * (s - 12), 0.35)
		elif b % 4 == 2 and s >= 4 and s < 8:
			if s % 2 == 0:   # triplet roll over beat 2
				for k in 3:
					_hat(t + k * step * 2.0 / 3.0, 0.5 + 0.15 * k, -0.35)
		elif s % 2 == 0 or (s % 4 == 3 and b % 2 == 0):
			_hat(t, 0.85 if s % 4 == 0 else 0.6, -0.25 if s % 4 == 2 else 0.25)
		if s == 10 and b % 4 == 1:
			_open_hat(t)

## Short punchy kick that sits on top of the 808.
func _trap_kick(t: float) -> void:
	var i0 := int(t * SR)
	var ph := 0.0
	for k in int(0.16 * SR):
		var x := k / float(SR)
		ph += TAU * (55.0 + 140.0 * exp(-x * 45.0)) / SR
		var s := sin(ph) * exp(-x * 18.0) + rng.randf_range(-1, 1) * exp(-x * 600.0) * 0.5
		_add(L, i0 + k, s * 0.7)
		_add(R, i0 + k, s * 0.7)

## Mono 808s: each one rings until the next starts (or 1.4 s), with a quick pitch dive
## into the note and saturation for bite.
func _render_808s(subs: Array, n: int) -> void:
	for j in subs.size():
		var ev: Array = subs[j]
		var midi: int = ev[1]
		if midi < 0:
			continue
		var t: float = ev[0]
		var v: float = ev[2]
		var end := t + 1.4
		if j + 1 < subs.size():
			end = minf(end, subs[j + 1][0])
		var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
		var i0 := int(t * SR)
		var len := int((end - t) * SR)
		var ph := 0.0
		for k in len:
			var x := k / float(SR)
			ph += TAU * f * (1.0 + 1.0 * exp(-x * 60.0)) / SR
			var rel := clampf((len - k) / (0.015 * SR), 0.0, 1.0)   # de-click at the cut
			var s := tanh(sin(ph) * 2.6) * exp(-x * 1.3) * rel * 0.75 * v
			_add(L, i0 + k, s)
			_add(R, i0 + k, s)

## The song's strongest bass pitch class in each bar, as a MIDI note in F1..E2.
func _bass_notes(mix: PackedVector2Array, offset: float, bar: float, bars: int) -> Array:
	const DEC := 20
	var rate := SR / float(DEC)
	var lo := PackedFloat32Array()
	var a := 0.0
	var c := 0.0
	for i in mix.size():
		a += ((mix[i].x + mix[i].y) * 0.5 - a) * 0.03   # two one-pole stages, ~210 Hz
		c += (a - c) * 0.03
		if i % DEC == 0:
			lo.append(c)
	var out := []
	var names := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var line := ""
	for b in bars:
		var s0 := maxi(int((offset + b * bar) * rate), 0)
		var s1 := mini(s0 + int(bar * rate), lo.size())
		var chroma := PackedFloat32Array()
		chroma.resize(12)
		for m in range(28, 56):
			var f := 440.0 * pow(2.0, (m - 69) / 12.0)
			var coef := 2.0 * cos(TAU * f / rate)
			var q1 := 0.0
			var q2 := 0.0
			for i in range(s0, s1):
				var q0 := coef * q1 - q2 + lo[i]
				q2 = q1
				q1 = q0
			chroma[m % 12] += q1 * q1 + q2 * q2 - coef * q1 * q2
		var best := 0
		for p in 12:
			if chroma[p] > chroma[best]:
				best = p
		out.append(29 + posmod(best - 5, 12))   # F1 (29) .. E2 (40)
		line += names[best] + " "
	print("808 notes per bar: ", line)
	return out
