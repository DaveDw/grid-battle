extends Node
## Background music. Autoload "Music". Each screen asks for a context; a new context
## cross-fades from the old one, and asking again for the one already playing does
## nothing (it keeps playing across screens).
##   menu: title, leader select, collection...   map: sector map, drafts, events
##   terran / ascendancy / manyworlds / long: a battle against that faction
##   commander: a sector commander battle
## Every context has a built-in track (tools/compose_music.gd renders them into
## assets/music/gen/). Licensed tracks listed in LIBRARY join the rotation: each time a
## context starts, one of its tracks is picked, so both kinds get heard.

const FADE := 1.2
const DUCK_DB := -9.0            # under the victory / defeat screen
const GEN := "res://assets/music/gen/%s.wav"
## Library tracks (assets/music/lib/), per context. Every track gets a line in CREDITS
## (shown on the Credits screen), even CC0 ones that don't require it.
const LIB := "res://assets/music/lib/"
const LIBRARY := {
	"menu": [LIB + "outer_space.mp3"],
	"map": [LIB + "claimed_by_the_void_mix.ogg"],
	"terran": [LIB + "space_battle_bpm130.ogg", LIB + "kohle_und_stahl.ogg", LIB + "militaristic_tune.ogg"],
	"ascendancy": [LIB + "space_battle_bpm130.ogg", LIB + "ganymede.ogg", LIB + "hunter_class_lifeform.mp3"],
	"manyworlds": [LIB + "space_battle_bpm130.ogg", LIB + "ocean_trance.ogg", LIB + "energy_storm.mp3"],
	"long": [LIB + "space_battle_bpm130.ogg", LIB + "the_plague_beat.wav", LIB + "the_plague_trap.wav",   # tools/beat_layer.gd
		LIB + "technovillain.mp3", LIB + "true_villain_emerges.wav"],
	"commander": [LIB + "carnageboss_battle_6_mix_faster.ogg"],
}
const CREDITS: Array = [
	"\"Outer Space Loop\" by wipics (CC0)",
	"\"Claimed by the Void\" mix by vitalezzz & tricksntraps (CC0)",
	"\"Space Battle\" and \"Ocean Trance\" by MintoDog (CC0)",
	"\"Kohle und Stahl\" and \"Some Militaristic Tune\" by Spring Spring (CC0)",
	"\"Ganymede\" by congusbongus (CC0)",
	"\"Hunter-class Lifeform\" by vitalezzz (CC0)",
	"\"Energy Storm\" by iamoneabe (CC0)",
	"\"The Plague\" by Indieteur (CC0), with added drums",
	"\"Technovillain\" by Joth (CC0)",
	"\"The True Villain Emerges\" by Umplix (CC0)",
	"\"Carnage & Boss Battle\" by Centurion of war & nene (CC0)",
	"via OpenGameArt.org",
]

var context := ""
var _players: Array[AudioStreamPlayer] = []
var _cur := 0
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps playing under the pause menu
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	apply_volume()
	# the first screen (the title) never goes through Game.go
	(func():
		if context == "":
			play("menu")).call_deferred()

func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		var v := float(Game.settings.get("music_volume", 0.7))
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))

## Every track that can play in `ctx`.
func tracks(ctx: String) -> Array:
	var out: Array = []
	if ResourceLoader.exists(GEN % ctx):
		out.append(GEN % ctx)
	for path in LIBRARY.get(ctx, []):
		if ResourceLoader.exists(path):
			out.append(path)
	return out

## Cross-fade to context `ctx` (no-op if it's already playing).
func play(ctx: String) -> void:
	if ctx == context:
		duck(false)
		return
	var options := tracks(ctx)
	if options.is_empty():
		return
	context = ctx
	var stream: AudioStream = load(options[randi() % options.size()])
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	var old := _players[_cur]
	_cur = 1 - _cur
	var new := _players[_cur]
	new.stream = stream
	new.volume_db = -40.0
	new.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(new, "volume_db", 0.0, FADE).set_trans(Tween.TRANS_SINE)
	if old.playing:
		_tween.tween_property(old, "volume_db", -60.0, FADE).set_trans(Tween.TRANS_SINE)
		_tween.chain().tween_callback(old.stop)

## Music for a screen Game.go is switching to ("" = the screen chooses for itself).
func for_scene(path: String) -> void:
	var file := path.get_file().get_basename()
	if file == "main":
		return   # the battlefield picks the enemy's faction theme
	play("map" if file in ["sector_map", "draft", "event"] else "menu")

## Lower the music (the end-of-battle screen), or bring it back.
func duck(on: bool) -> void:
	var p := _players[_cur]
	if not p.playing:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(p, "volume_db", DUCK_DB if on else 0.0, 0.6)
