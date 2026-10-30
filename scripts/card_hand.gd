class_name CardHand
extends Control
## A team's deck and hand. Two draw rules:
##   burn (Evolution): the draw timer never stops; every draw_time a card is drawn, and
##     if the hand is already full a random card in it is burned (discarded) first.
##   hold (Conquest): cards stay in hand until played. The timer only runs while a slot
##     is empty, and draws one card each time it fills, until the hand is full.
## Played and burned cards go to the discard pile, which is shuffled back into the deck
## when the deck runs out. The player's hand is drawn at the bottom of the screen
## (1-3 / X-Y-B / click or tap a card); the enemy's runs hidden.

const HAND_SIZE := 3
const DRAW_TIME := 7.5            # Evolution
const HOLD_DRAW_TIME := 9.0       # Conquest
const WARN_TIME := 1.6            # draw bar flashes red this long before a burn
const CARD_W := 196.0
const CARD_H := 70.0
const GAP := 12.0

var deck: Array = []
var hand: Array = []
var discard: Array = []
var energy: EnergyBar             # to grey out cards the team can't afford
var armed := -1                   # slot being aimed (tile cards), -1 if none
var team := 0                     # whose hand
var hand_disc: Array = []         # energy off each card in hand (event discounts, per copy)
var _disc_pool := {}              # card id -> discounts of the copies not in hand
var hold := false                 # Conquest rule (see above)
var draw_time := DRAW_TIME        # seconds per draw (sector modifiers can change it)
var _draw_t := 0.0
var _played_fx: Array = []        # [card id, slot, time left]
var _burn_fx: Array = []          # [card id, slot, time left]
var _new_fx: Array = []           # [slot, time left] for freshly drawn cards

## `discounts` (Game.copy_discounts(), player only): id -> one entry per discounted copy.
func setup(cards: Array, team_energy: EnergyBar, discounts := {}) -> void:
	deck = cards.duplicate()
	energy = team_energy
	_disc_pool = discounts.duplicate(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # square pixels for the card icons
	for n in 2:
		_draw_card_from_deck()

func _draw_card_from_deck() -> bool:
	if deck.is_empty():
		if discard.is_empty():
			return false
		deck = discard.duplicate()
		discard.clear()
		deck.shuffle()
	var id: String = deck.pop_back()
	hand.append(id)
	# Is this the discounted copy? Copies are interchangeable until drawn, so the odds
	# are the discounted share of this card's copies outside the hand.
	var pool: Array = _disc_pool.get(id, [])
	var outside := deck.count(id) + discard.count(id) + 1
	hand_disc.append(pool.pop_back() if not pool.is_empty() and randf() * outside < pool.size() else 0.0)
	_new_fx.append([hand.size() - 1, 0.3])
	if is_visible_in_tree():
		Sfx.card_drawn()
	return true

## Timer filled: draw, burning a random card first if the hand is full.
func _cycle() -> void:
	if hand.size() >= HAND_SIZE:
		var i := randi() % hand.size()
		var id: String = hand[i]
		_release(i)
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
	return i < hand.size() and energy.value >= cost_of(i)

## Energy cost of the card in slot `i`, after this copy's discount.
func cost_of(i: int) -> float:
	return maxf(Game.card_cost(hand[i]) - float(hand_disc[i]), 0.0)

## Take slot `i` out of the hand; its discount goes back with the copy.
func _release(i: int) -> void:
	if float(hand_disc[i]) > 0.0:
		var pool: Array = _disc_pool.get(hand[i], [])
		pool.append(hand_disc[i])
		_disc_pool[hand[i]] = pool
	hand.remove_at(i)
	hand_disc.remove_at(i)

## Discard the whole hand (Recompile).
func discard_hand() -> void:
	while not hand.is_empty():
		discard.append(hand[0])
		_release(0)
	armed = -1

func is_full() -> bool:
	return hand.size() >= HAND_SIZE

## Is the draw timer running? (A held hand waits while it is full.)
func drawing() -> bool:
	return not (hold and is_full()) and not (deck.is_empty() and discard.is_empty())

## Seconds until the next draw.
func time_to_draw() -> float:
	return draw_time - _draw_t

## Remove card `i` from the hand and return its id ("" if the slot is empty).
func take(i: int) -> String:
	if i >= hand.size():
		return ""
	var id: String = hand[i]
	_release(i)
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
	if drawing():
		_draw_t += delta
		if _draw_t >= draw_time:
			_draw_t = 0.0
			if hold:
				_draw_card_from_deck()
			else:
				_cycle()
	else:
		_draw_t = 0.0   # a full held hand: the timer starts fresh when a slot opens
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

## Word-wraps text to a pixel width (draw_multiline_string has no line spacing control).
func _wrap(font: Font, text: String, width: float, size: int) -> Array:
	var lines := []
	var line := ""
	for word in text.split(" "):
		var next := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	return lines

func _slot_rect(i: int) -> Rect2:
	return Rect2(i * (CARD_W + GAP), 0, CARD_W, CARD_H)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var cf: Font = Game.FONT_CARD
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
		# left column: the card's icon at 1x (32 px), cost under it, slot key in the corner
		var icon := Rect2(r.position + Vector2(6, 6), Vector2(32, 32))
		var art := Game.card_art(hand[i])
		draw_rect(icon, Color(0, 0, 0, 0.25))
		if art:
			draw_texture_rect(art, icon, false, Color.WHITE if ok else Color(0.55, 0.55, 0.6))
		draw_string(cf, r.position + Vector2(2, 10), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.85, 0.4))
		draw_string(cf, r.position + Vector2(6, 56), "%d" % int(cost_of(i)), HORIZONTAL_ALIGNMENT_CENTER, 32, 10, Color(0.45, 0.8, 1.0) if ok else Color(0.9, 0.4, 0.4))
		# right column: name and rules text
		var tx := 44.0
		var name_size := 8 if c["name"].length() > 14 else 10
		draw_string(cf, r.position + Vector2(tx, 16), c["name"], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - tx - 4, name_size, Color.WHITE if ok else Color(0.6, 0.62, 0.7))
		var lines := _wrap(cf, c["text"], CARD_W - tx - 4, 8)
		for li in mini(lines.size(), 4):
			draw_string(cf, r.position + Vector2(tx, 30 + li * 10), lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.72, 0.78, 0.9) if ok else Color(0.5, 0.52, 0.6))
	for f in _played_fx:
		var r := _slot_rect(f[1])
		var k: float = f[2] / 0.35
		r.position.y -= (1.0 - k) * 60.0
		draw_rect(r, Color(1, 1, 1, 0.5 * k))
		draw_string(cf, r.position + Vector2(22, 18), Game.CARDS[f[0]]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.1, 0.2, 0.3, k))
	for f in _burn_fx:
		# burned card: drops and turns to embers
		var r := _slot_rect(f[1])
		var k: float = f[2] / 0.5
		r.position.y += (1.0 - k) * 30.0
		draw_rect(r, Color(0.9, 0.3, 0.15, 0.6 * k))
		draw_string(cf, r.position + Vector2(22, 18), Game.CARDS[f[0]]["name"] + "  BURNED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.85, 0.7, k))
	# draw timer bar under the hand; red flashing when a burn is coming, dim when a held hand is full
	var bar := Rect2(0, CARD_H + 5, HAND_SIZE * (CARD_W + GAP) - GAP, 5)
	var f2 := _draw_t / draw_time
	var warn := not hold and is_full() and time_to_draw() <= WARN_TIME
	var col := Color(0.5, 0.8, 1.0, 0.8)
	if warn:
		col = Color(1.0, 0.25, 0.2, 0.6 + 0.4 * sin(t * 25.0))
	draw_rect(bar, Color(0.1, 0.12, 0.18))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * f2, bar.size.y)), col)
	var x0 := HAND_SIZE * (CARD_W + GAP)
	draw_string(cf, Vector2(x0, 16), "DECK %d" % deck.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.62, 0.75))
	draw_string(cf, Vector2(x0, 32), "USED %d" % discard.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.45, 0.5, 0.6))
	if warn:
		draw_string(font, Vector2(x0, 52), "BURN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.35, 0.3))
	elif hold and is_full():
		draw_string(font, Vector2(x0, 52), "HAND FULL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.6, 0.75))
