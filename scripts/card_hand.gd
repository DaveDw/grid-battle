class_name CardHand
extends Control
## A team's deck and hand. The draw timer never stops: every DRAW_TIME a card is drawn,
## and if the hand is already full a random card in it is burned (discarded) to make
## room. Played and burned cards go to the discard pile, which is shuffled back into
## the deck when the deck runs out. The player's hand is drawn at the bottom of the
## screen (1-3 / X-Y-B / click or tap a card); the enemy's runs hidden.

const HAND_SIZE := 3
const DRAW_TIME := 4.5
const WARN_TIME := 1.2            # draw bar flashes red this long before a burn
const CARD_W := 196.0
const CARD_H := 70.0
const GAP := 12.0

var deck: Array = []
var hand: Array = []
var discard: Array = []
var energy: EnergyBar             # to grey out cards the team can't afford
var armed := -1                   # slot being aimed (tile cards), -1 if none
var team := 0                     # whose hand (event discounts apply to the player's)
var draw_time := DRAW_TIME        # seconds per draw (sector modifiers can change it)
var _draw_t := 0.0
var _played_fx: Array = []        # [card id, slot, time left]
var _burn_fx: Array = []          # [card id, slot, time left]
var _new_fx: Array = []           # [slot, time left] for freshly drawn cards

func setup(cards: Array, team_energy: EnergyBar) -> void:
	deck = cards.duplicate()
	energy = team_energy
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in 2:
		_draw_card_from_deck()

func _draw_card_from_deck() -> bool:
	if deck.is_empty():
		if discard.is_empty():
			return false
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
	hand.append(deck.pop_back())
	_new_fx.append([hand.size() - 1, 0.3])
	if is_visible_in_tree():
		Sfx.card_drawn()
	return true

## Timer filled: draw, burning a random card first if the hand is full.
func _cycle() -> void:
	if hand.size() >= HAND_SIZE:
		var i := randi() % hand.size()
		var id: String = hand[i]
		hand.remove_at(i)
		discard.append(id)
		_burn_fx.append([id, i, 0.5])
		if is_visible_in_tree():
			Sfx.card_burned()
		if armed == i:
			armed = -1
		elif armed > i:
			armed -= 1
	_draw_card_from_deck()

func can_play(i: int) -> bool:
	return i < hand.size() and energy.value >= Game.card_cost(hand[i], team)

func is_full() -> bool:
	return hand.size() >= HAND_SIZE

## Seconds until the next draw.
func time_to_draw() -> float:
	return draw_time - _draw_t

## Remove card `i` from the hand and return its id ("" if the slot is empty).
func take(i: int) -> String:
	if i >= hand.size():
		return ""
	var id: String = hand[i]
	hand.remove_at(i)
	discard.append(id)
	_played_fx.append([id, i, 0.35])
	if armed == i:
		armed = -1
	elif armed > i:
		armed -= 1
	return id

## Hand slot under a point in this control's coordinates, or -1.
func slot_at(local: Vector2) -> int:
	for i in HAND_SIZE:
		if _slot_rect(i).has_point(local):
			return i
	return -1

func _process(delta: float) -> void:
	_draw_t += delta
	if _draw_t >= draw_time:
		_draw_t = 0.0
		_cycle()
	for list in [_played_fx, _burn_fx]:
		for f in list:
			f[2] -= delta
	_played_fx = _played_fx.filter(func(f): return f[2] > 0.0)
	_burn_fx = _burn_fx.filter(func(f): return f[2] > 0.0)
	for f in _new_fx:
		f[1] -= delta
	_new_fx = _new_fx.filter(func(f): return f[1] > 0.0)
	if visible:
		queue_redraw()

func _slot_rect(i: int) -> Rect2:
	return Rect2(i * (CARD_W + GAP), 0, CARD_W, CARD_H)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var t := Time.get_ticks_msec() / 1000.0
	for i in HAND_SIZE:
		var r := _slot_rect(i)
		if i >= hand.size():
			draw_rect(r, Color(0.08, 0.1, 0.15, 0.6))
			draw_rect(r, Color(0.3, 0.35, 0.45, 0.5), false, 1.0)
			continue
		var c: Dictionary = Game.CARDS[hand[i]]
		var ok := can_play(i)
		var lift := 0.0
		for f in _new_fx:
			if f[0] == i:
				lift = f[1] / 0.3 * 14.0
		if armed == i:
			lift -= 8.0
		r.position.y += lift
		draw_rect(r, Color(0.12, 0.17, 0.27) if ok else Color(0.09, 0.1, 0.14))
		var edge := Color(0.55, 0.85, 1.0) if ok else Color(0.3, 0.33, 0.42)
		if armed == i:
			edge = Color(1.0, 0.85, 0.3)
		draw_rect(r, edge, false, 3.0 if armed == i else 2.0)
		draw_string(font, r.position + Vector2(8, 18), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.4))
		var name_size := 15 if c["name"].length() <= 14 else 13
		draw_string(font, r.position + Vector2(24, 18), c["name"], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 64, name_size, Color.WHITE if ok else Color(0.6, 0.62, 0.7))
		draw_string(font, r.position + Vector2(CARD_W - 44, 18), "%d" % int(Game.card_cost(hand[i], team)), HORIZONTAL_ALIGNMENT_RIGHT, 36, 15, Color(0.45, 0.8, 1.0) if ok else Color(0.9, 0.4, 0.4))
		draw_multiline_string(font, r.position + Vector2(8, 38), c["text"], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 16, 12, 2, Color(0.72, 0.78, 0.9) if ok else Color(0.5, 0.52, 0.6))
	for f in _played_fx:
		var r := _slot_rect(f[1])
		var k: float = f[2] / 0.35
		r.position.y -= (1.0 - k) * 60.0
		draw_rect(r, Color(1, 1, 1, 0.5 * k))
		draw_string(font, r.position + Vector2(24, 18), Game.CARDS[f[0]]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.1, 0.2, 0.3, k))
	for f in _burn_fx:
		# burned card: drops and turns to embers
		var r := _slot_rect(f[1])
		var k: float = f[2] / 0.5
		r.position.y += (1.0 - k) * 30.0
		draw_rect(r, Color(0.9, 0.3, 0.15, 0.6 * k))
		draw_string(font, r.position + Vector2(24, 18), Game.CARDS[f[0]]["name"] + "  BURNED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.7, k))
	# draw timer bar under the hand; red flashing when a burn is coming
	var bar := Rect2(0, CARD_H + 5, HAND_SIZE * (CARD_W + GAP) - GAP, 5)
	var f2 := _draw_t / draw_time
	var warn := is_full() and time_to_draw() <= WARN_TIME
	var col := Color(0.5, 0.8, 1.0, 0.8)
	if warn:
		col = Color(1.0, 0.25, 0.2, 0.6 + 0.4 * sin(t * 25.0))
	draw_rect(bar, Color(0.1, 0.12, 0.18))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * f2, bar.size.y)), col)
	var x0 := HAND_SIZE * (CARD_W + GAP)
	draw_string(font, Vector2(x0, 16), "DECK %d" % deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.62, 0.75))
	draw_string(font, Vector2(x0, 32), "USED %d" % discard.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.45, 0.5, 0.6))
	if warn:
		draw_string(font, Vector2(x0, 52), "BURN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.35, 0.3))
