extends Node
## Bullet sprites and fire sounds: renders every unit's fire sound to
## screenshots/sfx-samples/fire/<unit>.wav, checks each unit has its own sprite and
## recipe, then stages four battles (all 24 units) where everyone fires at once and
## screenshots the shots in flight.
## godot --path . res://tools/rigs/check/shots.tscn -- <out_dir>
## Uses throwaway save slot 99, deleted afterwards.
const MATCHUPS := [["banner_marshal", "chief_visionary"], ["claim_lord", "tide_speaker"],
	["mission_mother", "director_zero"], ["captain_everafter", "prism_elder"]]

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var fails := 0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots/sfx-samples/fire"))
	var seen := {}
	for key in Game.UNITS:
		var r: Array = Sfx.UNIT_FIRE.get(key, [])
		var tex := Game.bullet_tex(key)
		if r.is_empty() or tex == null:
			print("FAIL %s: sound %s, sprite %s" % [key, not r.is_empty(), tex != null])
			fails += 1
			continue
		var sig := JSON.stringify(r)
		if seen.has(sig):
			print("FAIL %s sounds the same as %s" % [key, seen[sig]])
			fails += 1
		seen[sig] = key
		Sfx.render(r + [{"norm": Sfx.FIRE_PEAK}]).save_to_wav(ProjectSettings.globalize_path("res://screenshots/sfx-samples/fire/%s.wav" % key.replace("/", "_")))
	print("%d units have their own sprite and sound" % seen.size())
	for m in MATCHUPS:
		Game.new_run(m[0], 99, 0, [], "evolution", 3)
		Game.run["enemy"] = m[1]
		Game.run["phase"] = "battle"
		var main: Node = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		for i in 40:
			await get_tree().process_frame
		var bf = main.get_node("Battlefield")
		for u in bf.player_units + bf.enemy_units:
			bf.team_energy[u.team].value = 100.0
			if u.primary == "charge":
				bf.charges[u.get_instance_id()] = 40.0
				bf.release_charge(u)
			else:
				bf.fire_primary(u)
		for i in 7:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("%s/shots_%s.png" % [out, m[0]])
		main.queue_free()
		await get_tree().process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(99)))
	print("FAILS %d" % fails)
	get_tree().quit()
