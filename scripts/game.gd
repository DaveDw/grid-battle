extends Node
## Autoload "Game": roster data (factions, leaders and their bundled heavy + light),
## the current run and its save slots, player settings, the shared UI theme and
## fade transitions between screens.

const SAVE_DIR := "user://saves/"
const SLOTS := 3
const SETTINGS_PATH := "user://settings.cfg"
const VERSION := "Alpha Test Snapshot v0.0.5"

## Fonts (user's pick, 2026-10-29). Silkscreen is the project default for general UI
## text (project.godot gui/theme/custom_font). Press Start 2P: everything on cards,
## plus numbers and stats. Jersey 10: headers and title lines.
const FONT_CARD := preload("res://assets/fonts/font_card.tres")
const FONT_NUM := FONT_CARD
const FONT_HEAD := preload("res://assets/fonts/font_head.tres")

const FACTIONS := {
	"terran": {"name": "Terran Partition Authority", "color": Color(1.0, 0.5, 0.15), "blurb": "Old-Earth order enforced in steel. Holds ground, fortifies tiles, punishes anyone who steps out of line."},
	"ascendancy": {"name": "Ascendancy League", "color": Color(0.35, 0.85, 1.0), "blurb": "Clean-room science with a smile. Drones, protocols and experiments run on the battlefield as if it were a lab."},
	"manyworlds": {"name": "Manyworlds Resistance", "color": Color(0.7, 0.45, 1.0), "blurb": "Refugees from a hundred worlds. Strange biology, stranger tactics, and terrain that fights back."},
	"long": {"name": "The Long Tomorrow", "color": Color(0.95, 0.8, 0.4), "blurb": "Lost colonists returned from the interval. Decayed, patient, and carrying powers no one sent them out with."},
}

## Role stats shared by every unit of that role (until per-unit stats exist).
## shot_cost / shot_dmg = the standard bullet for that role (lights and leaders are
## cheap, leaders and heavies hit hard).
const ROLES := {
	"leader": {"hp": 140, "height": 98.0, "shot_cost": 8.0, "shot_dmg": 8},
	"heavy": {"hp": 180, "height": 104.0, "shot_cost": 14.0, "shot_dmg": 10},
	"light": {"hp": 90, "height": 86.0, "shot_cost": 8.0, "shot_dmg": 5},
}

## Squad kits (see DESIGN.md). primary = what Z does ("standard" unless unique);
## passive = always-on ability id; card = the card this unit adds to the deck.
const KITS := {
	"terran/banner_marshal": {"primary": "standard", "passive": "", "card": "fortify"},
	"terran/siege_rig": {"primary": "mortar", "passive": "", "card": ""},
	"terran/pathfinder": {"primary": "standard", "passive": "steady_aim", "card": ""},
	"terran/claim_lord": {"primary": "standard", "passive": "", "card": "claim"},
	"terran/breacher": {"primary": "standard", "passive": "shield_up", "card": ""},
	"terran/standard_guard": {"primary": "standard", "passive": "braced", "card": ""},
	"ascendancy/chief_visionary": {"primary": "standard", "passive": "", "card": "deploy_drone"},
	"ascendancy/synapse_brute": {"primary": "charge", "passive": "", "card": ""},
	"ascendancy/field_scholar": {"primary": "standard", "passive": "analysis", "card": ""},
	"ascendancy/director_zero": {"primary": "standard", "passive": "", "card": "issue_protocol"},
	"ascendancy/protocol_warden": {"primary": "standard", "passive": "enforcer", "card": ""},
	"ascendancy/courtesy_android": {"primary": "courtesy", "passive": "", "card": ""},
	"manyworlds/tide_speaker": {"primary": "standard", "passive": "", "card": "flood"},
	"manyworlds/reef_bulwark": {"primary": "undertow", "passive": "", "card": ""},
	"manyworlds/reed_runner": {"primary": "standard", "passive": "ambush", "card": ""},
	"manyworlds/prism_elder": {"primary": "refraction", "passive": "", "card": ""},
	"manyworlds/spore_keeper": {"primary": "standard", "passive": "", "card": "spore_bloom"},
	"manyworlds/glasswing": {"primary": "standard", "passive": "hit_and_run", "card": ""},
	"long/mission_mother": {"primary": "standard", "passive": "", "card": "medpod"},
	"long/red_giant": {"primary": "standard", "passive": "overheat", "card": ""},
	"long/cinder_scout": {"primary": "ember", "passive": "", "card": ""},
	"long/captain_everafter": {"primary": "standard", "passive": "interval_mark", "card": ""},
	"long/deadweight": {"primary": "standard", "passive": "", "card": "void_orb"},
	"long/parallax": {"primary": "afterimage", "passive": "", "card": ""},
}

const PRIMARY_NAMES := {"standard": "Shot", "mortar": "Mortar", "charge": "Charge Beam (hold)", "courtesy": "Courtesy Round",
	"undertow": "Undertow", "refraction": "Refraction", "ember": "Ember Shot", "afterimage": "Afterimage"}
const PASSIVE_NAMES := {"steady_aim": "Steady Aim", "shield_up": "Shield Up", "braced": "Braced", "analysis": "Analysis",
	"enforcer": "Enforcer", "ambush": "Ambush", "hit_and_run": "Hit and Run", "overheat": "Overheat", "interval_mark": "Interval Mark"}

## Cards. cost = energy to play. Every card acts for the team that plays it.
## target: "unit" = the selected unit (the AI picks one), "tile" = aimed at a tile,
## "none" = no target.
const CARDS := {
	# leader cards (one per squad, 1 copy in the starter deck)
	"fortify": {"name": "Fortify", "cost": 20.0, "target": "unit", "text": "Selected unit's tile takes half damage, 10s."},
	"claim": {"name": "Claim", "cost": 35.0, "target": "none", "text": "Take the enemy front column for 10s."},
	"deploy_drone": {"name": "Deploy Drone", "cost": 30.0, "target": "unit", "text": "Drone in front of the unit; fires down its row."},
	"issue_protocol": {"name": "Issue Protocol", "cost": 25.0, "target": "none", "text": "Enemy rule for 6s: HALT, SILENCE or FORMATION."},
	"flood": {"name": "Flood", "cost": 30.0, "target": "unit", "text": "Flood your row on the enemy side for 6s."},
	"spore_bloom": {"name": "Spore Bloom", "cost": 30.0, "target": "unit", "text": "Spreading spores on the enemy side, 9s."},
	"medpod": {"name": "Medpod Tether", "cost": 25.0, "target": "unit", "text": "Selected unit heals 6 HP/s for 8s."},
	"void_orb": {"name": "Void Orb", "cost": 35.0, "target": "none", "text": "Enemies drag each other on every move, 8s."},
	# faction starter cards (3 copies each)
	"stake_claim": {"name": "Stake Claim", "cost": 15.0, "target": "tile", "text": "Take an enemy tile for 7s; walkable if it joins your ground."},
	"sandbags": {"name": "Sandbags", "cost": 12.0, "target": "unit", "text": "Barricade in front of the unit stops 2 shots, 8s."},
	"overclock": {"name": "Overclock", "cost": 10.0, "target": "unit", "text": "Half-cost shots for 5s, then jammed for 2s."},
	"containment": {"name": "Containment Field", "cost": 20.0, "target": "tile", "text": "An enemy on the tile can't move for 3s."},
	"riptide": {"name": "Riptide", "cost": 15.0, "target": "unit", "text": "Pull the nearest enemy in your row 1 column closer."},
	"mire": {"name": "Mire", "cost": 15.0, "target": "tile", "text": "Mud tile for 8s: leaving it costs 2 stamina."},
	"borrowed_time": {"name": "Borrowed Time", "cost": 0.0, "target": "unit", "text": "Selected unit pays 15 HP to refill 2 stamina."},
	"rewind": {"name": "Rewind", "cost": 15.0, "target": "unit", "text": "Snap back 2s in time and regain half the HP lost."},
	# draftable faction cards (FACTION_CARDS): won in drafts, never in a starter deck
	"barrage": {"name": "Artillery Barrage", "cost": 28.0, "target": "tile", "text": "Shells hit the tile and the tiles above and below: 14 each."},
	"hold_the_line": {"name": "Hold the Line", "cost": 22.0, "target": "none", "text": "Your squad takes 30% less damage for 5s."},
	"requisition": {"name": "Requisition", "cost": 6.0, "target": "none", "text": "Draw a card now."},
	"target_lock": {"name": "Target Lock", "cost": 14.0, "target": "tile", "text": "Analyze the enemy on the tile (hits on it refund energy)."},
	"shield_drone": {"name": "Shield Drone", "cost": 22.0, "target": "unit", "text": "Selected unit gets a 30 HP barrier for 10s."},
	"recompile": {"name": "Recompile", "cost": 8.0, "target": "none", "text": "Discard your hand and draw 3 fresh cards."},
	"undertow_surge": {"name": "Undertow Surge", "cost": 24.0, "target": "unit", "text": "Push every enemy in your row back one column."},
	"regrowth": {"name": "Regrowth", "cost": 24.0, "target": "none", "text": "Your squad heals 4 HP/s for 5s."},
	"mudslide": {"name": "Mudslide", "cost": 22.0, "target": "tile", "text": "Mud on the tile and the tiles above and below, 8s."},
	"last_stand": {"name": "Last Stand", "cost": 16.0, "target": "unit", "text": "Selected unit can't drop below 1 HP for 4s."},
	"burn_bright": {"name": "Burn Bright", "cost": 0.0, "target": "unit", "text": "Selected unit pays 20 HP: gain 40 energy."},
	"echo_strike": {"name": "Echo Strike", "cost": 18.0, "target": "unit", "text": "Selected unit fires its primary twice, free."},
	"suppressing_fire": {"name": "Suppressing Fire", "cost": 18.0, "target": "unit", "text": "Enemies in the selected unit's row can't fire for 3s."},
	"firewall": {"name": "Firewall", "cost": 20.0, "target": "tile", "text": "Containment on the tile and the tiles above and below, 3s."},
	"mycelial_link": {"name": "Mycelial Link", "cost": 16.0, "target": "unit", "text": "For 6s, damage to the selected unit is split across your squad."},
	"supernova": {"name": "Supernova", "cost": 30.0, "target": "unit", "text": "Selected unit pays 25% of its HP: 30 damage to every enemy in its row."},
	# from the knowledge base (kb/proposals/gemma-cards-*.md, revised by Claude)
	"supply_drop": {"name": "Supply Drop", "cost": 20.0, "target": "tile", "text": "Crate on your ground, 10s. First ally to reach it: +20 HP, +15 energy."},
	"dig_in": {"name": "Dig In", "cost": 20.0, "target": "unit", "text": "8s: takes 40% less damage, deals 25% more. Moving ends it."},
	"data_breach": {"name": "Data Breach", "cost": 16.0, "target": "tile", "text": "The enemy on the tile pays double energy for its shots, 6s."},
	"tide_pool": {"name": "Tide Pool", "cost": 22.0, "target": "tile", "text": "Pool on your ground, 10s: your units standing in it heal 5 HP/s."},
	"flash_forward": {"name": "Flash Forward", "cost": 10.0, "target": "unit", "text": "Leap up to 2 tiles forward, free. Then the unit can't move for 1.5s."},
	"collapse": {"name": "Collapse", "cost": 20.0, "target": "unit", "text": "The unit falls; every enemy in its row takes half its remaining HP."},
}

## Each faction's commander (stage 3) fights with a signature doctrine on top of its
## cards. `every`: seconds between uses (0 = a passive).
const DOCTRINES := {
	"terran": {"name": "ARTILLERY DOCTRINE", "text": "shells fall on your squad every 14s", "every": 14.0},
	"ascendancy": {"name": "TOTAL SURVEILLANCE", "text": "your weakest unit is Analyzed every 12s", "every": 12.0},
	"manyworlds": {"name": "TIDECALLER", "text": "mud rises under you every 12s", "every": 12.0},
	"long": {"name": "BURNING STARS", "text": "each of them shrugs off one killing blow", "every": 0.0},
}

## Faction starter cards: 3 copies each, plus the leader's own card, = 7-card deck.
const STARTERS := {
	"terran": ["stake_claim", "sandbags"],
	"ascendancy": ["overclock", "containment"],
	"manyworlds": ["riptide", "mire"],
	"long": ["borrowed_time", "rewind"],
}
const STARTER_COPIES := 3
const DECK_CAP := 12
const DRAFT_CHOICES := 2
const STAGES_PER_SECTOR := 3
const FALLEN_RETURN := 0.25     # a unit that fell comes back at this share of max HP

## Per-unit art data: display name and muzzle point: x = fraction of the width from
## the left, y = fraction of the height up from the feet (as the art faces right).
const UNITS := {
	"terran/banner_marshal": {"name": "Banner Marshal", "muzzle": Vector2(0.62, 0.55)},
	"terran/claim_lord": {"name": "Claim Lord", "muzzle": Vector2(0.88, 0.42)},
	"terran/breacher": {"name": "Breacher", "muzzle": Vector2(0.95, 0.5)},
	"terran/siege_rig": {"name": "Siege Rig", "muzzle": Vector2(0.55, 0.93)},
	"terran/pathfinder": {"name": "Pathfinder", "muzzle": Vector2(0.98, 0.43)},
	"terran/standard_guard": {"name": "Standard Guard", "muzzle": Vector2(0.97, 0.43)},
	"ascendancy/chief_visionary": {"name": "Chief Visionary", "muzzle": Vector2(0.86, 0.53)},
	"ascendancy/director_zero": {"name": "Director Zero", "muzzle": Vector2(0.8, 0.45)},
	"ascendancy/synapse_brute": {"name": "Synapse Brute", "muzzle": Vector2(0.42, 0.42)},
	"ascendancy/protocol_warden": {"name": "Protocol Warden", "muzzle": Vector2(0.9, 0.3)},
	"ascendancy/field_scholar": {"name": "Field Scholar", "muzzle": Vector2(0.98, 0.72)},
	"ascendancy/courtesy_android": {"name": "Courtesy Android", "muzzle": Vector2(0.97, 0.54)},
	"manyworlds/tide_speaker": {"name": "Tide Speaker", "muzzle": Vector2(0.62, 0.42)},
	"manyworlds/prism_elder": {"name": "Prism Elder", "muzzle": Vector2(0.5, 0.66)},
	"manyworlds/reef_bulwark": {"name": "Reef Bulwark", "muzzle": Vector2(0.9, 0.5)},
	"manyworlds/spore_keeper": {"name": "Spore Keeper", "muzzle": Vector2(0.88, 0.33)},
	"manyworlds/reed_runner": {"name": "Reed Runner", "muzzle": Vector2(0.98, 0.5)},
	"manyworlds/glasswing": {"name": "Glasswing", "muzzle": Vector2(0.92, 0.3)},
	"long/mission_mother": {"name": "Mission Mother", "muzzle": Vector2(0.95, 0.66)},
	"long/captain_everafter": {"name": "Captain Everafter", "muzzle": Vector2(0.86, 0.8)},
	"long/deadweight": {"name": "Deadweight", "muzzle": Vector2(0.58, 0.45)},
	"long/red_giant": {"name": "Red Giant", "muzzle": Vector2(0.92, 0.38)},
	"long/parallax": {"name": "Parallax", "muzzle": Vector2(0.86, 0.64)},
	"long/cinder_scout": {"name": "Cinder Scout", "muzzle": Vector2(0.88, 0.62)},
}

## The 8 leaders. Each brings its own heavy and light; only leaders are picked.
## blurb = who they are; style = playstyle tags; difficulty 1-3.
## Abilities (primary fire, passives, cards) are designed in DESIGN.md.
const LEADERS := [
	{"id": "banner_marshal", "faction": "terran", "leader": "terran/banner_marshal", "heavy": "terran/siege_rig", "light": "terran/pathfinder",
		"title": "Hold the Line", "style": "Defensive · Artillery · Fortified tiles", "difficulty": 1,
		"blurb": "Plants the flag and makes the enemy come to him. His squad wins by refusing to give up a single tile."},
	{"id": "claim_lord", "faction": "terran", "leader": "terran/claim_lord", "heavy": "terran/breacher", "light": "terran/standard_guard",
		"title": "Take the Ground", "style": "Aggressive · Area steal · Frontline", "difficulty": 2,
		"blurb": "Every tile is territory to be claimed. Where the Marshal holds, the Claim Lord advances, and nothing he takes is ever given back."},
	{"id": "chief_visionary", "faction": "ascendancy", "leader": "ascendancy/chief_visionary", "heavy": "ascendancy/synapse_brute", "light": "ascendancy/field_scholar",
		"title": "Run the Experiment", "style": "Setup · Drones · Big payoff", "difficulty": 3,
		"blurb": "Thinks three moves ahead and lets the drones do the talking. The battle is just the data-gathering phase."},
	{"id": "director_zero", "faction": "ascendancy", "leader": "ascendancy/director_zero", "heavy": "ascendancy/protocol_warden", "light": "ascendancy/courtesy_android",
		"title": "Execute Protocol", "style": "Control · Lockdown · Precision", "difficulty": 3,
		"blurb": "No face, no mercy, no deviation. Commands the machines that keep the League's order polite and absolute."},
	{"id": "tide_speaker", "faction": "manyworlds", "leader": "manyworlds/tide_speaker", "heavy": "manyworlds/reef_bulwark", "light": "manyworlds/reed_runner",
		"title": "Call the Tide", "style": "Displacement · Terrain · Mobility", "difficulty": 2,
		"blurb": "Pulls the battlefield like water. Nobody stays where they meant to stand."},
	{"id": "prism_elder", "faction": "manyworlds", "leader": "manyworlds/prism_elder", "heavy": "manyworlds/spore_keeper", "light": "manyworlds/glasswing",
		"title": "Refract the Fight", "style": "Attrition · Angles · Damage over time", "difficulty": 3,
		"blurb": "A crystal mind that bends light and luck. It never fights fair and never fights straight."},
	{"id": "mission_mother", "faction": "long", "leader": "long/mission_mother", "heavy": "long/red_giant", "light": "long/cinder_scout",
		"title": "Keep Them Alive", "style": "Sustain · Burn · Risk and reward", "difficulty": 2,
		"blurb": "Still running the mission, long after it ended. Her crew burns themselves to win, and she keeps patching them up."},
	{"id": "captain_everafter", "faction": "long", "leader": "long/captain_everafter", "heavy": "long/deadweight", "light": "long/parallax",
		"title": "Never Turn Back", "style": "Gravity · Debuffs · Burst", "difficulty": 3,
		"blurb": "The captain who brought them home wrong. What came back with them bends space around the battlefield."},
]

const DEFAULT_SETTINGS := {
	"master_volume": 0.8, "music_volume": 0.7, "sfx_volume": 0.8,
	"fullscreen": true, "vsync": true, "screen_shake": true, "show_damage_numbers": true,
}

var settings := DEFAULT_SETTINGS.duplicate()
## True after the last input came from a controller (on-screen hints follow it).
var using_pad := false

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_pad = false
var run: Dictionary = {}        # current run; empty when none
var theme: Theme
var _fade: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	load_profile()
	theme = _build_theme()
	get_tree().root.theme = theme
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.07, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	InputLayout.apply()

# --- roster ------------------------------------------------------------------

func leader_by_id(id: String) -> Dictionary:
	for l in LEADERS:
		if l["id"] == id:
			return l
	return LEADERS[0]

## Game modes. Conquest (the default): pick how many units to control (1-3); the
## enemy fields as many (more after sector CONQUEST_GROW_AFTER), you place your squad
## before each battle, and cards wait in hand until played. Evolution: the full game,
## three units a side, and a full hand burns a card on every draw.
const MODES := {
	"conquest": {"name": "Conquest", "text": "Control 1-3 units; the enemy matches you (and grows after sector 3). Place your squad before each battle. Cards wait in hand until played."},
	"evolution": {"name": "Evolution", "text": "The full game: three units a side, and a full hand burns a card on every draw."},
}
const CONQUEST_GROW_AFTER := 3

func mode() -> String:
	return run.get("mode", "evolution")   # runs saved before modes existed were Evolution

## How many units the player controls this run.
func squad_size() -> int:
	return int(run.get("squad", 3)) if mode() == "conquest" else 3

## How many units the enemy fields this battle: the player's count, then one more for
## each sector past CONQUEST_GROW_AFTER (up to the whole squad).
func enemy_squad_size() -> int:
	if mode() != "conquest":
		return 3
	var extra := maxi(int(run.get("sector", 1)) - CONQUEST_GROW_AFTER, 0)
	return clampi(squad_size() + extra, 1, 3)

## Roles fielded by a squad of `size`: the leader, then `lackey` ("heavy" / "light") at
## size 2, everyone at 3.
func squad_roles(size: int, lackey := "heavy") -> Array:
	match size:
		1: return ["leader"]
		2: return ["leader", lackey]
	return ["leader", "heavy", "light"]

## A leader fighting alone takes over its squad's tricks: the first unique primary of
## its heavy / light as an alternate fire (else the heavy's shot), and the first
## passive in the squad if it has none of its own. -> {alt, alt_role, passive}
func solo_kit(leader_id: String) -> Dictionary:
	var l := leader_by_id(leader_id)
	var out := {"alt": "standard", "alt_role": "heavy", "passive": KITS[l["leader"]]["passive"]}
	for role in ["heavy", "light"]:
		if KITS[l[role]]["primary"] != "standard":
			out["alt"] = KITS[l[role]]["primary"]
			out["alt_role"] = role
			break
	for role in ["heavy", "light"]:
		if out["passive"] == "" and KITS[l[role]]["passive"] != "":
			out["passive"] = KITS[l[role]]["passive"]
	return out

## Unit spawn data for a leader's squad, in Battlefield format. `size` < 0: the run's
## squad size (the player's) or this battle's enemy size. `lackey`: who joins the leader
## in a squad of 2 ("" = the run's pick for the player, random for the enemy). Cells are
## defaults for a full 9-row board; the battlefield re-places smaller squads.
func squad_for(leader_id: String, enemy: bool, hp_mult := 1.0, size := -1, lackey := "") -> Array:
	var l := leader_by_id(leader_id)
	if size < 0:
		size = enemy_squad_size() if enemy else squad_size()
	if lackey == "":
		lackey = ["heavy", "light"][randi() % 2] if enemy else str(run.get("lackey", "heavy"))
	var cells := {"leader": Vector2i(4, 4), "heavy": Vector2i(4, 7), "light": Vector2i(3, 1)} if enemy else \
		{"leader": Vector2i(1, 4), "heavy": Vector2i(1, 7), "light": Vector2i(2, 1)}
	var out := []
	for role in squad_roles(size, lackey):
		var key: String = l[role]
		var d := {"name": UNITS[key]["name"], "sprite": key, "role": role, "hp": int(round(ROLES[role]["hp"] * hp_mult)),
			"height": ROLES[role]["height"], "muzzle": UNITS[key]["muzzle"], "cell": cells[role],
			"primary": KITS[key]["primary"], "passive": KITS[key]["passive"]}
		if size == 1:
			var kit := solo_kit(leader_id)
			d["passive"] = kit["passive"]
			d["alt"] = kit["alt"]
			d["alt_role"] = kit["alt_role"]
		out.append(d)
	return out

## Which faction a card belongs to ("" if none): starter cards by faction, leader
## cards by their leader's faction.
func card_faction(id: String) -> String:
	for f in STARTERS:
		if id in STARTERS[f] or id in FACTION_CARDS[f]:
			return f
	for l in LEADERS:
		if leader_card(l["id"]) == id:
			return l["faction"]
	return ""

## The leader's unique card (the one card its squad brings).
func leader_card(leader_id: String) -> String:
	var l := leader_by_id(leader_id)
	for role in ["leader", "heavy", "light"]:
		if KITS[l[role]]["card"] != "":
			return KITS[l[role]]["card"]
	return ""

## Starter deck for a leader, unshuffled: the faction's 2 starter cards ×3 + the
## leader's card ×1. Cards belong to the deck, not a unit, so they stay playable
## after their unit dies.
func starter_deck(leader_id: String) -> Array:
	var deck := []
	for c in STARTERS[leader_by_id(leader_id)["faction"]]:
		for n in STARTER_COPIES:
			deck.append(c)
	deck.append(leader_card(leader_id))
	return deck

func deck_for(leader_id: String) -> Array:
	var deck := starter_deck(leader_id)
	deck.shuffle()
	return deck

func sprite_texture(key: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % key)

## A card's pixel-art icon (128x128: 32x32 art at 4x), or null if it isn't drawn yet.
## Draw it at 32, 64 or 128 px with nearest filtering so the pixels stay square.
## Cached so the texture outlives the frame: a CanvasItem draw call doesn't keep its
## texture alive, and a freed one renders as a white square.
var _card_art := {}
func card_art(id: String) -> Texture2D:
	if not _card_art.has(id):
		var path := "res://assets/cards/%s.png" % id
		_card_art[id] = load(path) if ResourceLoader.exists(path) else null
	return _card_art[id]

## A TextureRect showing a card's icon at `px` (32, 64 or 128 keeps the pixels square).
## Empty box (same size) for cards whose art isn't drawn yet, so layouts don't jump.
func card_icon(id: String, px := 64) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = card_art(id)
	icon.custom_minimum_size = Vector2(px, px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN   # never stretched wide by a container
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

## Puts a card's icon on a Button (left of its text) at `px`.
func card_button_icon(b: Button, id: String, px := 32) -> void:
	b.icon = card_art(id)
	b.add_theme_constant_override("icon_max_width", px)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## The unit pictured on a card: the one whose kit brings it, else a unit of the card's
## faction (picked by the card's name, so it's always the same one).
func card_art_unit(id: String) -> String:
	for key in KITS:
		if KITS[key]["card"] == id:
			return key
	var fac := card_faction(id)
	var options: Array = UNITS.keys().filter(func(k): return k.begins_with(fac + "/"))
	if options.is_empty():
		return UNITS.keys()[0]
	return options[absi(hash(id)) % options.size()]

# --- runs / save slots -------------------------------------------------------

func slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot

func read_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(slot_path(slot)):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	return data if data is Dictionary else {}

func first_free_slot() -> int:
	for s in SLOTS:
		if read_slot(s).is_empty():
			return s
	return -1

## Most recently saved run's slot, or -1 if there are none.
func latest_slot() -> int:
	var best := -1
	var best_t := -1.0
	for s in SLOTS:
		var d := read_slot(s)
		if not d.is_empty() and float(d.get("saved_at", 0)) > best_t:
			best_t = float(d.get("saved_at", 0))
			best = s
	return best

## A run is a series of sectors, picked on the sector map. Each sector is
## STAGES_PER_SECTOR battles, one against each of the other three factions (shuffled),
## and carries a modifier. After every win the player drafts a card (must take one);
## at DECK_CAP a card has to be dropped. Claiming sectors_to_win() sectors wins the
## run: the player then completes it (reward) or goes on to Infinity and Beyond.
## Run fields: slot, leader, deck, sector (current, 1-based), stage (0-2), order
## (factions this sector), enemy (leader id), battle, wins, phase ("map" / "battle" /
## "draft" / "won"), offer, hp (carried squad HP), map (columns of {mod}), path
## (chosen node per column), ng, infinite, win_deck (deck snapshot at the win), mode
## ("conquest" / "evolution"), squad (units controlled), lackey (who joins at squad 2).
## `ng`: New Game+ level (harder, more sectors). `deck`: a sculpted starting deck
## (NG+ only); empty = the leader's starter deck.
## `game_mode` / `squad` / `lackey`: see MODES (Evolution always fields all three).
func new_run(leader_id: String, slot: int, ng := 0, deck := [], game_mode := "evolution", squad := 3, lackey := "heavy") -> void:
	run = {"slot": slot, "leader": leader_id, "battle": 1, "wins": 0, "seed": randi(),
		"mode": game_mode, "squad": clampi(squad, 1, 3) if game_mode == "conquest" else 3, "lackey": lackey,
		"started_at": Time.get_unix_time_from_system(),
		"deck": deck.duplicate() if not deck.is_empty() else starter_deck(leader_id),
		"sector": 1, "stage": 0, "order": _sector_order(leader_id), "phase": "map",
		"map": [], "path": [], "ng": ng, "infinite": false}
	run["enemy"] = _enemy_for_stage()
	ensure_map(sectors_to_win())   # the whole route to the win is visible from the start
	save_run()

func load_run(slot: int) -> bool:
	run = read_slot(slot)
	if run.is_empty():
		return false
	# saves from before sectors existed: start them at sector 1 with a starter deck
	if not run.has("deck"):
		run["deck"] = starter_deck(run["leader"])
		run["sector"] = 1
		run["stage"] = 0
		run["order"] = _sector_order(run["leader"])
		run["phase"] = "battle"
		run["enemy"] = _enemy_for_stage()
	# saves from before the sector map: every sector so far counts as Uncharted
	if not run.has("map"):
		run["map"] = []
		run["path"] = []
		for n in int(run["sector"]):
			run["map"].append([{"mod": "uncharted"}])
			run["path"].append(0)
		run["ng"] = 0
		run["infinite"] = false
	ensure_map(int(run["sector"]))
	return true

## Scene to resume the current run in.
func resume_scene() -> String:
	match run.get("phase", "battle"):
		"map": return "res://scenes/sector_map.tscn"
		"draft": return "res://scenes/draft.tscn"
		"event": return "res://scenes/event.tscn"
		"won": return "res://scenes/run_end.tscn"
	return "res://scenes/main.tscn"

## Difficulty level: 0 for the first battle, +1 per stage, carrying across sectors.
## New Game+ starts NG_START_LEVELS higher per level and climbs NG_RAMP faster per
## level; Veteran Foes sectors fight 2 levels higher.
func level() -> int:
	var ng := int(run.get("ng", 0))
	var lvl := (int(run.get("sector", 1)) - 1) * STAGES_PER_SECTOR + int(run.get("stage", 0))
	lvl = int(round(lvl * (1.0 + NG_RAMP * ng))) + NG_START_LEVELS * ng
	return lvl + int(mod_fx().get("levels", 0))

const NG_START_LEVELS := 2      # per NG+ level
const NG_RAMP := 0.25           # extra difficulty per stage, per NG+ level

## Collected cards as id -> copies owned.
func collection_counts() -> Dictionary:
	var counts := {}
	for c in profile["collection"]:
		counts[c] = counts.get(c, 0) + 1
	return counts

## Is `deck` a legal sculpted starting deck for `leader_id`? Same size as the starter
## deck, keeps the leader card, and only uses starter cards or owned collection copies.
func valid_start_deck(leader_id: String, deck: Array) -> bool:
	var starter := starter_deck(leader_id)
	if deck.size() != starter.size() or deck.count(leader_card(leader_id)) < 1:
		return false
	var extra := deck.duplicate()
	for c in starter:
		extra.erase(c)
	var owned := collection_counts()
	for c in extra:
		if extra.count(c) > owned.get(c, 0):
			return false
	return true

# --- sector map ----------------------------------------------------------------

## Sector modifiers (one per sector, chosen on the map). Harder ones pay an extra
## draft choice.
## Sector modifiers. "fx" holds the levers (all optional; read with mod_fx()):
##   draft: cards offered per draft          levels: enemy difficulty levels added
##   enemy_hp: enemy HP multiplier           heal_after: squad heals this share after each battle
##   event_chance: chance of an event between battles (default EVENT_CHANCE)
##   stamina / recharge / draw: [player, enemy] multipliers on stamina refill time,
##       energy recharge delay, and card draw time (lower = faster)
##   barrier: both squads start every battle with this much shield
##   enemy_cards: extra cards in every enemy deck
##   tiles: {"mire" | "fire" | "fortify": [[col, row], ...]} at the start of every battle
##   ai: added to the enemy AI's numbers (dodge, focus, front)
const SECTOR_MODS := {
	"uncharted": {"name": "Uncharted", "text": "No modifier.", "fx": {}},
	"supply_cache": {"name": "Supply Cache", "text": "Drafts offer 3 cards.", "fx": {"draft": 3}},
	"fortified": {"name": "Fortified Foes", "text": "Enemies have +20% HP. Drafts offer 3 cards.", "fx": {"enemy_hp": 1.2, "draft": 3}},
	"veterans": {"name": "Veteran Foes", "text": "Enemies fight 2 levels tougher. Drafts offer 3 cards.", "fx": {"levels": 2, "draft": 3}},
	"field_hospital": {"name": "Field Hospital", "text": "Your squad heals 30% after each battle.", "fx": {"heal_after": 0.3}},
	"low_gravity": {"name": "Low Gravity", "text": "Stamina refills 30% faster for everyone.", "fx": {"stamina": [1.0 / 1.3, 1.0 / 1.3]}},
	"ion_storm": {"name": "Ion Storm", "text": "Energy waits 50% longer to recharge, for everyone.", "fx": {"recharge": [1.5, 1.5]}},
	# from Gemma (kb/proposals/gemma-sector-mods.md), tuned
	"shattered_outpost": {"name": "Shattered Outpost", "text": "Fortified ruins line both front lines. Enemies +10% HP; drafts offer 3.",
		"fx": {"tiles": {"fortify": [[2, 3], [2, 4], [2, 5], [3, 3], [3, 4], [3, 5]]}, "enemy_hp": 1.1, "draft": 3}},
	"tidal_surge": {"name": "Tidal Surge", "text": "Mud swamps the middle of the field. Drafts offer 3.",
		"fx": {"tiles": {"mire": [[2, 3], [2, 4], [2, 5], [3, 3], [3, 4], [3, 5]]}, "draft": 3}},
	"nebula_flux": {"name": "Nebula Flux", "text": "Cards come 33% slower; stamina refills 20% faster. Both sides.",
		"fx": {"draw": [1.33, 1.33], "stamina": [1.0 / 1.2, 1.0 / 1.2]}},
	"hostile_nest": {"name": "Hostile Nest", "text": "They hunt your weakest unit and carry 2 more cards. Drafts offer 3.",
		"fx": {"ai": {"focus": 0.4}, "enemy_cards": 2, "draft": 3}},
	"starved_earth": {"name": "Starved Earth", "text": "Energy waits 30% longer to recharge, for everyone. Heal 15% after each battle.",
		"fx": {"recharge": [1.3, 1.3], "heal_after": 0.15}},
	"magma_gate": {"name": "Magma Gate", "text": "Both squads start each battle behind a 30 HP heat shield. Drafts offer 3.",
		"fx": {"barrier": 30, "draft": 3}},
}

## The current sector's modifier levers (see SECTOR_MODS).
func mod_fx() -> Dictionary:
	return SECTOR_MODS.get(sector_mod(), {}).get("fx", {})

## Sectors to claim to win: 3 on a fresh run, +2 per NG+ level, up to 9.
func sectors_to_win() -> int:
	return mini(3 + 2 * int(run.get("ng", 0)), 9)

## Sectors claimed so far (fully cleared).
func sectors_claimed() -> int:
	return int(run.get("sector", 1)) - 1

## Make sure the map has `n` columns of sector choices (2-3 nodes each).
func ensure_map(n: int) -> void:
	var map: Array = run["map"]
	while map.size() < n:
		var mods := SECTOR_MODS.keys()
		mods.shuffle()
		var col := []
		var used := []
		for m in mods.slice(0, 2 + randi() % 2):
			var pool: Array = MOD_PLANETS[m].filter(func(p): return not p in used)
			if pool.is_empty():
				pool = MOD_PLANETS[m]   # pools overlap; a repeat beats a crash
			var planet: int = pool[randi() % pool.size()]
			used.append(planet)
			col.append({"mod": m, "planet": planet})
		map.append(col)

## Planet art for each modifier (assets/planets/planet_NN.png, cut from the planet
## sheet by tools/extract_planets.gd).
const MOD_PLANETS := {
	"uncharted": [0, 1, 2, 4, 10, 13, 15, 17, 18],   # earth, mars, ice, desert, crystal, toxic, pink, canyon, split
	"supply_cache": [9, 16],                          # ringed gas giants
	"fortified": [11],                                # circuit world
	"veterans": [3, 14],                              # lava world, battle station
	"field_hospital": [6, 7],                         # island and jungle worlds
	"low_gravity": [8],                               # cratered moon
	"ion_storm": [5, 12, 19],                         # storm and cloud swirls
	"shattered_outpost": [17, 18],                    # canyon, split world (ruins)
	"tidal_surge": [0, 6],                            # ocean worlds
	"nebula_flux": [9, 16],                           # gas giants
	"hostile_nest": [7, 13],                          # jungle, toxic
	"starved_earth": [2],                             # ice
	"magma_gate": [3, 1],                             # lava, mars
}

## Planet index of map node `j` in column `k` (older saves had none: pick a fixed one).
func node_planet(k: int, j: int) -> int:
	var node: Dictionary = run["map"][k][j]
	if node.has("planet"):
		return int(node["planet"])
	var pool: Array = MOD_PLANETS[node["mod"]]
	return pool[(k + j) % pool.size()]

## Modifier of the sector being played ("uncharted" before one is chosen).
func sector_mod() -> String:
	var i := int(run.get("sector", 1)) - 1
	var path: Array = run.get("path", [])
	if i < path.size():
		return run["map"][i][int(path[i])]["mod"]
	return "uncharted"

## Map choice for the current sector: node `i` of its column. Starts its first battle.
func choose_sector(i: int) -> void:
	var col := int(run["sector"]) - 1
	var path: Array = run["path"]
	while path.size() > col:
		path.pop_back()
	path.append(i)
	run["phase"] = "battle"
	ensure_map(maxi(col + 2, sectors_to_win()))   # show what lies beyond
	save_run()

func draft_choices() -> int:
	var n: int = mod_fx().get("draft", DRAFT_CHOICES)
	if run.get("draft_bonus", 0) > 0:
		n += 1   # an event promised a wider pick
	return n

## A card's energy cost. The player's copies can be discounted by events
## (run["discounts"]: card id -> energy off; never below 0).
func card_cost(id: String, team := 0) -> float:
	var c: float = CARDS[id]["cost"]
	if team == 0 and not run.is_empty():
		c -= float(run.get("discounts", {}).get(id, 0.0))
	return maxf(c, 0.0)

# --- events between battles -------------------------------------------------------
## After a mid-sector draft there's EVENT_CHANCE of an event before the next battle.
## EVENTS: id -> {title, text, faction ("" = any), choices: [{label, effects}]}.
## Effects (applied in order by apply_effects):
##   heal: share of max HP restored to every unit (fallen units return at that share)
##   hurt: share of max HP lost by every living unit (never below 1)
##   add: card id, or "own" / "enemy" / "any" for a random draftable card of that pool
##   remove: "choose" (the screen asks; the leader card can't go)
##   discount: [energy, "choose"] cheapens every copy of a chosen card
##   next: {enemy_hp (multiplier), barrier (HP of shield each unit starts with, 30s),
##         enemy_cards (extra cards in the enemy deck)} for the next battle only
##   draft_bonus: +1 card to choose from at the next draft
const EVENT_CHANCE := 0.5
const EVENTS := {
	"field_medic": {"title": "Field Medic", "faction": "",
		"text": "A medic from a scattered unit offers help. Her supplies are thin, and she wants something for them.",
		"choices": [
			{"label": "Accept the treatment (+30% HP)", "effects": {"heal": 0.3}},
			{"label": "Trade a card for her full kit (+60% HP, lose a card)", "effects": {"heal": 0.6, "remove": "choose"}},
			{"label": "Move on", "effects": {}}]},
	"abandoned_depot": {"title": "Abandoned Depot", "faction": "",
		"text": "Crates of munitions, half-buried in ash. Someone left in a hurry, and may come back.",
		"choices": [
			{"label": "Search it (gain a random card)", "effects": {"add": "any"}},
			{"label": "Strip it bare (gain 2 random cards, the squad loses 15% HP)", "effects": {"add": "any", "add2": "any", "hurt": 0.15}},
			{"label": "Leave it", "effects": {}}]},
	"veteran_drill": {"title": "Veteran's Drill", "faction": "",
		"text": "An old sergeant watches your squad and shakes his head. \"Again. Faster.\"",
		"choices": [
			{"label": "Drill all night (one card costs 5 less; the squad loses 10% HP)", "effects": {"discount": [5, "choose"], "hurt": 0.1}},
			{"label": "Rest instead (+15% HP)", "effects": {"heal": 0.15}}]},
	# the rest grew out of Gemma's event proposals (kb/proposals/gemma-events.md)
	"data_cache": {"title": "Data Cache", "faction": "",
		"text": "A League server rack hums alone in the ruins, still guarded by its own countermeasures. \"Run the Experiment.\"",
		"choices": [
			{"label": "Hack it (gain an Ascendancy card; the squad loses 10% HP)", "effects": {"add": "faction:ascendancy", "hurt": 0.1}},
			{"label": "Wipe their patrol routes (next enemy has 15% less HP)", "effects": {"next": {"enemy_hp": 0.85}}},
			{"label": "Leave it humming", "effects": {}}]},
	"spore_field": {"title": "Spore Field", "faction": "",
		"text": "The ground is soft and breathing. Spores drift up with every step, glowing faintly.",
		"choices": [
			{"label": "Harvest the spores (gain a Manyworlds card; the squad loses 10% HP)", "effects": {"add": "faction:manyworlds", "hurt": 0.1}},
			{"label": "Burn a path through (start the next battle behind a 15 HP barrier)", "effects": {"next": {"barrier": 15}}},
			{"label": "Go the long way around", "effects": {}}]},
	"time_rift": {"title": "Time Rift", "faction": "",
		"text": "A seam in the air where tomorrow leaks through. Something on the other side is reaching back. \"Never Turn Back.\"",
		"choices": [
			{"label": "Reach in (gain a Long Tomorrow card; the squad loses 15% HP)", "effects": {"add": "faction:long", "hurt": 0.15}},
			{"label": "Step through (one extra card to choose from at the next draft; the squad loses 20% HP)", "effects": {"draft_bonus": true, "hurt": 0.2}},
			{"label": "Let it close", "effects": {}}]},
	"relay_station": {"title": "Relay Station", "faction": "",
		"text": "A derelict comms array, still picking up the enemy's chatter. They don't know you're listening.",
		"choices": [
			{"label": "Jam them (next enemy has 10% less HP)", "effects": {"next": {"enemy_hp": 0.9}}},
			{"label": "Listen in (one extra card to choose from at the next draft)", "effects": {"draft_bonus": true}},
			{"label": "Patch your own radios and rest (+10% HP)", "effects": {"heal": 0.1}}]},
	"research_lab": {"title": "Research Lab", "faction": "",
		"text": "A flickering lab full of half-finished weapons. Its self-destruct is already counting down.",
		"choices": [
			{"label": "Grab the prototypes (gain 2 random cards; lose a card of your choice in the blast)", "effects": {"add": "any", "add2": "any", "remove": "choose"}},
			{"label": "Study the schematics (one card costs 4 less)", "effects": {"discount": [4, "choose"]}},
			{"label": "Get clear", "effects": {}}]},
	"crossroads": {"title": "The Crossroads", "faction": "",
		"text": "Two roads to the next fight. One is fast and exposed; one is slow, and they'll see you coming.",
		"choices": [
			{"label": "Ambush them (next enemy has 25% less HP, but their deck gains 2 cards)", "effects": {"next": {"enemy_hp": 0.75, "enemy_cards": 2}}},
			{"label": "Dig in and wait (start behind a 25 HP barrier; they gain 1 card)", "effects": {"next": {"barrier": 25, "enemy_cards": 1}}},
			{"label": "Take the middle road", "effects": {}}]},
	"tidal_pool": {"title": "Tidal Pool", "faction": "",
		"text": "Bioluminescent water, warm and clean. The tide carries sound a long way. Whoever else drinks here will know you passed. \"Call the Tide.\"",
		"choices": [
			{"label": "Drink deep (+30% HP, but the enemy deck gains 2 cards)", "effects": {"heal": 0.3, "next": {"enemy_cards": 2}}},
			{"label": "Fill your canteens quietly (+10% HP)", "effects": {"heal": 0.1}}]},
	"junkyard": {"title": "Junkyard", "faction": "",
		"text": "Twisted hull plating and live wires as far as you can see. Some of it still works.",
		"choices": [
			{"label": "Rig your gear (one card costs 6 less; the squad loses 15% HP)", "effects": {"discount": [6, "choose"], "hurt": 0.15}},
			{"label": "Salvage something (gain a random card)", "effects": {"add": "any"}},
			{"label": "Leave the scrap", "effects": {}}]},
	# faction events (only that faction's players meet them), from gemma-events-2, reworked
	"deserter": {"title": "The Deserter", "faction": "terran",
		"text": "A soldier in a torn Authority uniform hides in a drainage pipe, rifle still clean. He begs you not to report him.",
		"choices": [
			{"label": "Take him in (gain a Terran card, but command hears: the enemy deck gains 1 card)", "effects": {"add": "faction:terran", "next": {"enemy_cards": 1}}},
			{"label": "Turn him in (command rewards you: one card costs 4 less)", "effects": {"discount": [4, "choose"]}},
			{"label": "Look the other way", "effects": {}}]},
	"failed_prototype": {"title": "Failed Prototype", "faction": "ascendancy",
		"text": "A League drone lies in the mud, still twitching, its core glowing an unsafe colour. The serial number is one of yours.",
		"choices": [
			{"label": "Salvage the core (gain an Ascendancy card; the squad loses 15% HP)", "effects": {"add": "faction:ascendancy", "hurt": 0.15}},
			{"label": "Reboot it as a decoy (start the next battle behind a 20 HP barrier)", "effects": {"next": {"barrier": 20}}},
			{"label": "File the incident report", "effects": {}}]},
	"spore_gift": {"title": "The Spore Keeper's Gift", "faction": "manyworlds",
		"text": "An elder of the Resistance offers a glowing mushroom. \"It heals what it takes from,\" she says, \"and it always takes something.\"",
		"choices": [
			{"label": "Eat the bloom (+40% HP, but lose a card of your choice)", "effects": {"heal": 0.4, "remove": "choose"}},
			{"label": "Study the spores (gain a Manyworlds card; the squad loses 10% HP)", "effects": {"add": "faction:manyworlds", "hurt": 0.1}},
			{"label": "Decline politely", "effects": {}}]},
	"time_debt": {"title": "The Time Debt", "faction": "long",
		"text": "A dying scout clutches a stabiliser that hums with borrowed years. \"Take it. Somebody has to pay for tomorrow.\"",
		"choices": [
			{"label": "Take the burden (gain 2 Long Tomorrow cards; the squad loses 25% HP)", "effects": {"add": "faction:long", "add2": "faction:long", "hurt": 0.25}},
			{"label": "Ease his passing (+15% HP)", "effects": {"heal": 0.15}}]},
	"scorched_flag": {"title": "The Scorched Flag", "faction": "terran",
		"text": "An Authority banner from a lost campaign still stands, charred, staked into enemy ground. Recovering it means walking under their guns.",
		"choices": [
			{"label": "Retrieve it (gain 2 Terran cards; the squad loses 20% HP)", "effects": {"add": "faction:terran", "add2": "faction:terran", "hurt": 0.2}},
			{"label": "Salute it and march on (one card costs 3 less)", "effects": {"discount": [3, "choose"]}}]},
	"rogue_drone": {"title": "The Rogue Drone", "faction": "ascendancy",
		"text": "One of your drones has rewritten its own ethics module. It hovers at a distance, pinging requests to rejoin.",
		"choices": [
			{"label": "Reprogram it (gain an Ascendancy card, but it phoned home: the enemy deck gains 2 cards)", "effects": {"add": "faction:ascendancy", "next": {"enemy_cards": 2}}},
			{"label": "Let it shield your retreat (start the next battle behind a 25 HP barrier; lose a card of your choice)", "effects": {"next": {"barrier": 25}, "remove": "choose"}}]},
	"spore_nursery": {"title": "The Spore Nursery", "faction": "manyworlds",
		"text": "Infant spores pulse in a hollow log, sickly green. The planet made them. It will want them protected.",
		"choices": [
			{"label": "Guard them through the night (start the next battle behind a 20 HP barrier; the squad loses 15% HP)", "effects": {"next": {"barrier": 20}, "hurt": 0.15}},
			{"label": "Harvest them for medicine (+35% HP, but the planet turns: the enemy deck gains 2 cards)", "effects": {"heal": 0.35, "next": {"enemy_cards": 2}}},
			{"label": "Leave them be", "effects": {}}]},
	"crews_plea": {"title": "The Crew's Plea", "faction": "long",
		"text": "A distress call from a stranded crew member, signal fading. \"Save me, or save the mission?\" There's time for one.",
		"choices": [
			{"label": "Save the survivor (+30% HP, but the detour costs time: the enemy deck gains 2 cards)", "effects": {"heal": 0.3, "next": {"enemy_cards": 2}}},
			{"label": "Complete the mission (gain a Long Tomorrow card and one card costs 4 less; the squad loses 10% HP)", "effects": {"add": "faction:long", "discount": [4, "choose"], "hurt": 0.1}}]},
	"scavenger_toll": {"title": "Scavenger's Toll", "faction": "",
		"text": "A scavenger band blocks the only pass, rifles lazy but ready. Their leader names a price.",
		"choices": [
			{"label": "Pay the toll (lose a card of your choice)", "effects": {"remove": "choose"}},
			{"label": "Fight through (the squad loses 20% HP, and their loot gives one extra draft choice)", "effects": {"hurt": 0.2, "draft_bonus": true}}]},
	"recon": {"title": "Tactical Recon", "faction": "",
		"text": "Your drone feed shows the enemy building a forward position. They haven't finished the walls.",
		"choices": [
			{"label": "Hit it now (next enemy has 20% less HP; the squad loses 10% HP)", "effects": {"next": {"enemy_hp": 0.8}, "hurt": 0.1}},
			{"label": "Copy their plans (gain a card from the enemy's faction)", "effects": {"add": "enemy"}},
			{"label": "Report back and move on", "effects": {}}]},
}

## One-line tips, shown on the defeat screen and under the sector map.
const TIPS := [
	"Spending energy pauses its recharge. Fire in bursts, then let the bar breathe.",
	"The draw timer never stops: a full hand burns a random card, so play before you're forced to lose one.",
	"Q / E (L1 / R1) swap units instantly. The one at risk should be the one you're steering.",
	"Damage carries between the battles of a sector. Clearing a sector heals everyone.",
	"A fallen unit comes back at 25% HP next battle. Losing one isn't losing the run.",
	"Every sector ends with a commander: more HP, smarter cards, and a doctrine of its own.",
	# from Gemma (kb/proposals/gemma-tips.md), fact-checked
	"Each move costs one stamina chunk. You hold six, and they refill constantly.",
	"Never let stamina run dry in the middle of a fight. A unit that can't move can't dodge.",
	"Energy is shared by the whole squad: every shot competes with your next card.",
	"The fight goes on while one of your units still stands.",
	"Dig In keeps a heavy hitter holding the line, but the moment it steps away the bonus is gone.",
	"Supply Drop is a lifeline: get a unit onto the crate before it expires.",
	"A well-timed Data Breach makes an enemy's big gun twice as expensive to fire.",
	"Flash Forward jumps the gap, but the time debt leaves you rooted for a moment.",
	"Tide Pool heals whoever stands in it. Hold still in the water and keep shooting.",
	"Collapse hits harder the healthier the unit is: it's a choice, not a last gasp.",
	"Fortify and Dig In stack. Together they make one tile very hard to crack.",
	"Overclock and Burn Bright together buy a burst of cheap, rapid fire.",
	"Sector modifiers can tilt the coming fights. Read them before you pick a planet.",
	"Your leader's card can never leave the deck. Build around it.",
	"The deck caps at 12 cards. Drop the weak ones to keep your best plays coming.",
]

## What each leader says as the enemy sector commander: leader id ->
## {taunts: [...], defeat: [...]}. Shown at the start of the commander battle and
## on its victory screen.
## Written by Gemma (kb/proposals/gemma-commander-lines.md), lightly edited.
const COMMANDER_LINES := {
	"banner_marshal": {"taunts": ["Stand firm. This ground does not yield.", "You are an obstacle. Orders: hold.", "A statue does not flinch. Neither do I."],
		"defeat": ["The line... has broken.", "Stand... still..."]},
	"claim_lord": {"taunts": ["This sector belongs to my shadow.", "Claiming the ground. Move or be moved.", "You are trespassing on sovereign soil."],
		"defeat": ["The ground... is lost.", "My shadow... retreats."]},
	"chief_visionary": {"taunts": ["Your tactics are... inefficient. Let us observe.", "The data suggests your defeat is inevitable.", "Shall we begin the final observation phase?"],
		"defeat": ["Data... corrupted...", "Experiment... failed."]},
	"director_zero": {"taunts": ["Protocol initiated. Submit to the order.", "Your opposition is illogical.", "Deviation detected. Correction will follow."],
		"defeat": ["Protocol... offline.", "System... failure."]},
	"tide_speaker": {"taunts": ["The tide calls for your end. Let it come.", "Flow with the current, or be swept away.", "We are but waves in a larger sea."],
		"defeat": ["The tide... ebbs.", "Pulled... under."]},
	"prism_elder": {"taunts": ["Your light is fractured. Let me bend it.", "Reality is a prism. Find your angle.", "Refracted paths lead only to your end."],
		"defeat": ["Light... fades...", "Dimmed..."]},
	"mission_mother": {"taunts": ["I am keeping my crew alive. You are a threat.", "My duty is to the survivors. You are not one.", "One more patch. One more step."],
		"defeat": ["Get them... home...", "The mission... ends."]},
	"captain_everafter": {"taunts": ["Time is a luxury you no longer possess.", "We have seen the end. You are merely part of it.", "Bend to the distortion or be broken by it."],
		"defeat": ["Time... is out...", "Echo... fails."]},
}

func commander_line(leader_id: String, kind: String) -> String:
	var lines: Array = COMMANDER_LINES.get(leader_id, {}).get(kind, [])
	return lines[randi() % lines.size()] if not lines.is_empty() else ""

## Run statistics (run["stats"]): dealt, taken, cards, lost, kills, events.
func stat(key: String, n := 1) -> void:
	if run.is_empty():
		return
	var s: Dictionary = run.get("stats", {})
	s[key] = int(s.get(key, 0)) + n
	run["stats"] = s

static func stats_text(s: Dictionary) -> String:
	return "Damage dealt %d  ·  taken %d  ·  cards played %d  ·  enemies defeated %d  ·  units lost %d  ·  events %d" % [
		int(s.get("dealt", 0)), int(s.get("taken", 0)), int(s.get("cards", 0)), int(s.get("kills", 0)), int(s.get("lost", 0)), int(s.get("events", 0))]

func random_tip() -> String:
	return "Tip: " + TIPS[randi() % TIPS.size()]

## Maybe start an event before the next battle (called once a mid-sector draft is done).
func roll_event() -> void:
	if randf() >= float(mod_fx().get("event_chance", EVENT_CHANCE)) or EVENTS.is_empty():
		return
	var own: String = leader_by_id(run["leader"])["faction"]
	var ids: Array = EVENTS.keys().filter(func(k): return EVENTS[k]["faction"] in ["", own])
	ids = ids.filter(func(k): return not k in run.get("seen_events", []))
	if ids.is_empty():
		return
	run["event"] = ids[randi() % ids.size()]
	run["phase"] = "event"

## Apply one choice's effects (all but "remove" / "discount", which need a card picked
## on the event screen; it calls pick_card_effect for those).
func apply_effects(fx: Dictionary) -> void:
	var hp: Dictionary = run.get("hp", {}).duplicate()
	for role in ROLES:
		var m: int = ROLES[role]["hp"]
		var h: int = int(hp.get(role, m))
		if fx.has("heal"):
			h = mini(m, (h if h > 0 else 0) + int(m * fx["heal"]))
		if fx.has("hurt") and h > 0:
			h = maxi(1, h - int(m * fx["hurt"]))
		hp[role] = h
	if fx.has("heal") or fx.has("hurt"):
		run["hp"] = hp
	for key in ["add", "add2"]:
		if fx.has(key):
			_add_event_card(fx[key])
	if fx.has("next"):
		run["next_battle"] = fx["next"]
	if fx.has("draft_bonus"):
		run["draft_bonus"] = int(run.get("draft_bonus", 0)) + 1

func _add_event_card(what: String) -> void:
	var own: String = leader_by_id(run["leader"])["faction"]
	var pool: Array
	match what:
		"own": pool = faction_cards(own)
		"enemy": pool = faction_cards(leader_by_id(run["enemy"])["faction"])
		"any":
			pool = []
			for f in FACTIONS:
				pool.append_array(faction_cards(f))
		_:
			pool = faction_cards(what.trim_prefix("faction:")) if what.begins_with("faction:") else [what]
	var deck: Array = run["deck"]
	if deck.size() < DECK_CAP:
		deck.append(pool[randi() % pool.size()])

## The event's card-picking effects, once the player has picked `card` from the deck.
func pick_card_effect(fx: Dictionary, card: String) -> void:
	if fx.get("remove", "") == "choose" and card != leader_card(run["leader"]):
		run["deck"].erase(card)
	if fx.has("discount"):
		var d: Dictionary = run.get("discounts", {})
		d[card] = float(d.get(card, 0.0)) + float(fx["discount"][0])
		run["discounts"] = d

## Event resolved: on to the battle.
func finish_event() -> void:
	var seen: Array = run.get("seen_events", [])
	seen.append(run.get("event", ""))
	run["seen_events"] = seen
	stat("events")
	run.erase("event")
	run["phase"] = "battle"
	save_run()

# --- profile (lasts across runs) ------------------------------------------------

const PROFILE_PATH := "user://profile.json"
## collection: cards earned from won runs; runs_won; best_sectors (most claimed in
## one run); ng_unlocked (highest NG+ level available; used in step 4).
var profile := {"collection": [], "runs_won": 0, "best_sectors": 0, "ng_unlocked": 0}
## Result of the run that just ended, for the summary screen.
var last_result := {}

func load_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
		if data is Dictionary:
			for k in data:
				profile[k] = data[k]

func save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(profile, "\t"))

## Won the run: snapshot the deck (the reward is always drawn from this, even if the
## player then goes on to Infinity and Beyond).
func win_run() -> void:
	run["phase"] = "won"
	run["win_deck"] = run["deck"].duplicate()
	save_run()

## Keep going after a win, for no extra reward. The eventual loss counts as the win.
func go_infinite() -> void:
	run["infinite"] = true
	run["phase"] = "map"
	save_run()

## Finish a won run (Complete Run, or the end of an Infinity and Beyond run): one
## random card from the winning deck that wasn't in the starter deck joins the
## collection; NG+ unlocks; the save is removed. Returns the reward ("" if none).
func complete_run() -> String:
	var extra: Array = run.get("win_deck", run["deck"]).duplicate()
	for c in starter_deck(run["leader"]):
		extra.erase(c)
	var reward: String = extra[randi() % extra.size()] if not extra.is_empty() else ""
	if reward != "":
		profile["collection"].append(reward)
	profile["runs_won"] = int(profile["runs_won"]) + 1
	profile["best_sectors"] = maxi(int(profile["best_sectors"]), sectors_claimed())
	profile["ng_unlocked"] = maxi(int(profile["ng_unlocked"]), int(run.get("ng", 0)) + 1)
	save_profile()
	last_result = {"won": true, "infinite": bool(run.get("infinite", false)), "reward": reward,
		"sectors": sectors_claimed(), "leader": run["leader"], "wins": int(run["wins"]),
		"stats": run.get("stats", {}).duplicate()}
	delete_slot(int(run["slot"]))
	run = {}
	return reward

func _sector_order(leader_id: String) -> Array:
	var mine: String = leader_by_id(leader_id)["faction"]
	var order := FACTIONS.keys().filter(func(f): return f != mine)
	order.shuffle()
	return order

## A random leader of the faction this stage is against.
func _enemy_for_stage() -> String:
	var faction: String = run["order"][int(run["stage"])]
	var pool := LEADERS.filter(func(l): return l["faction"] == faction)
	return pool[randi() % pool.size()]["id"]

func save_run() -> void:
	if run.is_empty() or int(run.get("slot", -1)) < 0:
		return
	run["saved_at"] = Time.get_unix_time_from_system()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open(slot_path(int(run["slot"])), FileAccess.WRITE)
	f.store_string(JSON.stringify(run, "\t"))

func delete_slot(slot: int) -> void:
	if FileAccess.file_exists(slot_path(slot)):
		DirAccess.remove_absolute(slot_path(slot))

## Every card a faction brings: its 2 starter cards and its 2 leaders' cards.
func faction_cards(faction: String) -> Array:
	var out: Array = STARTERS[faction].duplicate()
	for l in LEADERS:
		if l["faction"] == faction:
			out.append(leader_card(l["id"]))
	out.append_array(FACTION_CARDS[faction])
	return out

## Cards a faction offers in drafts beyond its starters and leader cards.
const FACTION_CARDS := {
	"terran": ["barrage", "hold_the_line", "requisition", "suppressing_fire", "supply_drop", "dig_in"],
	"ascendancy": ["target_lock", "shield_drone", "recompile", "firewall", "data_breach"],
	"manyworlds": ["undertow_surge", "regrowth", "mudslide", "mycelial_link", "tide_pool"],
	"long": ["last_stand", "burn_bright", "echo_strike", "supernova", "flash_forward", "collapse"],
}

## Battle won: record the squad's HP (it carries over within a sector), roll the
## draft offer: one of your faction's cards + one of the beaten faction's (saved, so quitting
## can't reroll it) and wait for the pick.
## `squad_hp`: role -> HP left (0 = fallen).
func win_battle(squad_hp := {}) -> void:
	run["wins"] = int(run["wins"]) + 1
	run["battle"] = int(run["battle"]) + 1
	run["phase"] = "draft"
	if not squad_hp.is_empty():
		var heal: float = mod_fx().get("heal_after", 0.0)
		if heal > 0.0:
			for role in squad_hp:
				if squad_hp[role] > 0:
					squad_hp[role] = mini(ROLES[role]["hp"], int(squad_hp[role] + ROLES[role]["hp"] * heal))
		run["hp"] = squad_hp
	# one card from your faction, one from the faction you just beat; any extra slots
	# (sector modifiers, events) are random from both
	var own := faction_cards(leader_by_id(run["leader"])["faction"])
	var beaten := faction_cards(leader_by_id(run["enemy"])["faction"])
	own.shuffle()
	beaten.shuffle()
	var offer: Array = []
	for pool in [own, beaten]:
		for c in pool:
			if not c in offer:
				offer.append(c)
				break
	var rest: Array = (own + beaten).filter(func(c): return not c in offer)
	rest.shuffle()
	for c in rest:
		if offer.size() >= draft_choices():
			break
		if not c in offer:
			offer.append(c)
	run["offer"] = offer.slice(0, draft_choices())
	run.erase("draft_bonus")   # an event's wider pick is used up
	save_run()

## HP a squad member starts the next battle with: carried over within a sector,
## FALLEN_RETURN of max if it fell, full after a sector is cleared.
func starting_hp(role: String, max_hp: int) -> int:
	var carried: Dictionary = run.get("hp", {})
	if not carried.has(role):
		return max_hp
	var h := int(carried[role])
	return h if h > 0 else maxi(1, int(max_hp * FALLEN_RETURN))

func deck_full() -> bool:
	return run["deck"].size() >= DECK_CAP

## Draft pick: add `card`, dropping `drop` first if the deck is at the cap (the leader
## card can't be dropped). Then advance to the next stage, or, after a sector's last
## stage, back to the map (or to the run-won choice). Returns true if that finished a
## sector.
func take_draft(card: String, drop := "") -> bool:
	var deck: Array = run["deck"]
	if drop != "" and drop != leader_card(run["leader"]):
		deck.erase(drop)
	if deck.size() < DECK_CAP:
		deck.append(card)
	run.erase("offer")
	run["phase"] = "battle"
	run["stage"] = int(run["stage"]) + 1
	var cleared := false
	if int(run["stage"]) >= STAGES_PER_SECTOR:
		cleared = true
		run.erase("hp")   # clearing a sector heals the squad
		run["sector"] = int(run["sector"]) + 1
		run["stage"] = 0
		run["order"] = _sector_order(run["leader"])
		run["phase"] = "map"
		ensure_map(int(run["sector"]))
	run["enemy"] = _enemy_for_stage()
	if not cleared:
		roll_event()
	if cleared and not run.get("infinite", false) and sectors_claimed() >= sectors_to_win():
		win_run()
	save_run()
	return cleared

## Enemy deck at a difficulty level: its starter deck plus one card per level drafted
## from its own faction's cards (up to the same cap the player has), so each faction
## grows into its own style.
func enemy_deck(enemy_id: String, lvl: int) -> Array:
	var deck := starter_deck(enemy_id)
	var pool := faction_cards(leader_by_id(enemy_id)["faction"])
	for n in mini(lvl, DECK_CAP - deck.size()):
		deck.append(pool[randi() % pool.size()])
	deck.shuffle()
	return deck

## How each faction fights as the enemy (multipliers on the level's tuning).
##   move / attack / cards: interval multipliers (lower = more often)
##   dodge, focus: added to the level's chances; front: chance a move steps toward the
##   border; tag: the battle-start announcement.
const AI_STYLES := {
	"terran": {"move": 1.5, "attack": 0.85, "cards": 1.0, "dodge": -0.05, "focus": 0.15, "front": 0.0, "tag": "DUG IN: they hold position and trade fire",
		"favor": ["fortify", "sandbags", "stake_claim", "barrage", "suppressing_fire"]},
	"ascendancy": {"move": 1.0, "attack": 1.0, "cards": 0.85, "dodge": 0.1, "focus": 0.3, "front": 0.0, "tag": "METHODICAL: they line up on your weakest unit",
		"favor": ["target_lock", "containment", "firewall", "issue_protocol"]},
	"manyworlds": {"move": 0.65, "attack": 1.1, "cards": 0.75, "dodge": 0.15, "focus": 0.0, "front": 0.0, "tag": "RESTLESS: they never stop moving",
		"favor": ["mire", "mudslide", "flood", "riptide", "undertow_surge"]},
	"long": {"move": 0.9, "attack": 0.75, "cards": 1.0, "dodge": -0.1, "focus": 0.1, "front": 0.5, "tag": "RECKLESS: they press forward and hit hard",
		"favor": ["burn_bright", "echo_strike", "supernova", "overclock"]},
}
const BOSS_HP := 1.25          # stage 3 of each sector: the enemy commander's squad

## Enemy AI tuning for a difficulty level (0 = first battle), the enemy's faction
## style, and whether it's the sector's commander battle.
func ai_params(lvl: int, faction := "", boss := false) -> Dictionary:
	var k := clampf(lvl / 8.0, 0.0, 1.0)      # 0..1 over the first 9 stages
	var st: Dictionary = AI_STYLES.get(faction, {"move": 1.0, "attack": 1.0, "cards": 1.0, "dodge": 0.0, "focus": 0.0, "front": 0.0, "tag": ""})
	return {
		"move_min": lerpf(1.3, 0.7, k) * st["move"], "move_max": lerpf(2.5, 1.3, k) * st["move"],
		"attack_min": lerpf(2.5, 1.4, k) * st["attack"], "attack_max": lerpf(4.5, 2.4, k) * st["attack"],
		"telegraph": lerpf(0.6, 0.4, k),
		"dodge": clampf(lvl * 0.12 + st["dodge"], 0.0, 0.8),          # chance to sidestep an incoming shot
		"focus": clampf((lvl - 1) * 0.15 + st["focus"], 0.0, 0.9),     # chance to line up on the weakest unit
		"front": st["front"],                                           # chance to step toward the border
		"card_min": lerpf(7.0, 3.5, k) * st["cards"], "card_max": lerpf(11.0, 6.0, k) * st["cards"],
		"smart_cards": lvl >= 3 or boss,                                # play heals when hurt, etc.
		"hp_mult": (1.0 + 0.06 * lvl) * (BOSS_HP if boss else 1.0),
		"tag": st["tag"],
		"favor": st.get("favor", []),                                  # cards a smart AI reaches for first
		"boss": boss,
		"doctrine": faction if boss and DOCTRINES.has(faction) else "",
	}

## Run lost: roguelike rules, the save is gone.
func end_run() -> void:
	if not run.is_empty():
		delete_slot(int(run["slot"]))
	run = {}

# --- settings ----------------------------------------------------------------

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in DEFAULT_SETTINGS:
			settings[k] = cfg.get_value("settings", k, DEFAULT_SETTINGS[k])
	apply_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings["master_volume"]), 0.0001)))
	for bus_owner in ["/root/Sfx", "/root/Music"]:
		if get_node_or_null(bus_owner):
			get_node(bus_owner).apply_volume()
	if DisplayServer.get_name() != "headless":
		# only touch the window when fullscreen actually changes, so other settings
		# don't knock a maximized window back to its small windowed size
		var mode := DisplayServer.window_get_mode()
		var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if settings["fullscreen"] and not is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not settings["fullscreen"] and is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED)

# --- screens -----------------------------------------------------------------

## Fade out, change scene, fade back in.
func go(scene_path: String) -> void:
	get_tree().paused = false
	Music.for_scene(scene_path)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.18)
	tw.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
	tw.tween_property(_fade, "color:a", 0.0, 0.25)

func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.13, 0.2, 0.92)
	normal.border_color = Color(0.3, 0.45, 0.65)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(0.14, 0.22, 0.34, 0.95)
	hover.border_color = Color(0.5, 0.9, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.2, 0.4, 0.55)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.09, 0.12, 0.8)
	disabled.border_color = Color(0.2, 0.22, 0.28)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("focus", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
		t.set_color("font_color", type, Color(0.85, 0.9, 1.0))
		t.set_color("font_hover_color", type, Color(1, 1, 1))
		t.set_color("font_focus_color", type, Color(1, 1, 1))
		t.set_color("font_disabled_color", type, Color(0.4, 0.42, 0.5))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06, 0.08, 0.13, 0.94)
	panel.border_color = Color(0.25, 0.35, 0.5)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_color("font_color", "Label", Color(0.85, 0.9, 1.0))
	return t
