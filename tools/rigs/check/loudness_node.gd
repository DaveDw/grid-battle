extends Node
## Loudness check: plays a battle with the user's own settings, has the player's unit
## fire, and measures what actually reaches the SFX and Music buses (after their volume
## sliders) and the master output, in dBFS. Needs a real audio device (not --headless).
## godot --path . res://tools/rigs/check/loudness.tscn -- <leader> [squad]
var _caps := {}

func _peak(bus: String) -> float:
	var c: AudioEffectCapture = _caps[bus]
	var frames := c.get_frames_available()
	var buf := c.get_buffer(frames)
	var p := 0.0
	for v in buf:
		p = maxf(p, maxf(absf(v.x), absf(v.y)))
	return linear_to_db(maxf(p, 0.000001))

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var leader: String = args[0] if args.size() > 0 else "claim_lord"
	var squad := int(args[1]) if args.size() > 1 else 1
	await get_tree().process_frame
	for bus in ["SFX", "Music", "Master"]:
		var idx := AudioServer.get_bus_index(bus)
		var c := AudioEffectCapture.new()
		AudioServer.add_bus_effect(idx, c)
		_caps[bus] = c
	print("settings: master %.2f  music %.2f  sfx %.2f" % [Game.settings["master_volume"], Game.settings["music_volume"], Game.settings["sfx_volume"]])
	Game.new_run(leader, 99, 0, [], "evolution", 3)   # starts at once (no placement)
	Game.run["phase"] = "battle"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	var bf = main.get_node("Battlefield")
	bf.ai["attack_min"] = 999.0
	bf.ai["attack_max"] = 999.0
	for u in bf.enemy_units:
		u._ai_attack = 999.0
	await get_tree().create_timer(4.0).timeout   # music fades in; placement countdown
	await get_tree().create_timer(4.0).timeout
	for b in _caps:
		_peak(b)   # drain
	await get_tree().create_timer(1.0).timeout
	print("music alone, 1s:  SFX %.1f dB   Music %.1f dB   Master %.1f dB" % [_peak("SFX"), _peak("Music"), _peak("Master")])
	var u: Unit = bf.active_unit()
	bf.team_energy[0].value = 100.0
	var ok: bool = bf.fire_primary(u)
	await get_tree().create_timer(0.5).timeout
	print("player shot (%s, fired %s): SFX %.1f dB   Music %.1f dB   Master %.1f dB" % [u.key, ok, _peak("SFX"), _peak("Music"), _peak("Master")])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	get_tree().quit()
