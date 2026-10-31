class_name RefillClock
extends RefCounted
## Time Debt changes natural refill, not refunds or explicit card gains.
var boost_left := 0.0
var pause_left := 0.0

func trigger() -> void:
	boost_left = 4.0
	pause_left = 3.0

func tick(delta: float) -> float:
	var fast := minf(delta, boost_left)
	boost_left -= fast
	delta -= fast
	var paused := minf(delta, pause_left)
	pause_left -= paused
	return fast * 2.0 + delta - paused
