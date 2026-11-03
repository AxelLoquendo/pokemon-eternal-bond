class_name ExperienceGrowth
extends Object
## Exp total para alcanzar un nivel (1–100), según growth_rate del PBS.

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 100


static func total_exp_at_level(growth_rate: String, level: int) -> int:
	var n: int = clampi(level, MIN_LEVEL, MAX_LEVEL)
	if n <= 1:
		return 0
	match growth_rate.strip_edges():
		"Fast":
			return _fast(n)
		"Slow":
			return _slow(n)
		"Parabolic":
			return _parabolic(n)
		"Erratic":
			return _erratic(n)
		"Fluctuating":
			return _fluctuating(n)
		_:
			# Medium (Medium Fast)
			return _medium(n)


static func level_for_exp(growth_rate: String, exp_points: int) -> int:
	var exp_clamped: int = maxi(0, exp_points)
	var level: int = MIN_LEVEL
	while level < MAX_LEVEL and total_exp_at_level(growth_rate, level + 1) <= exp_clamped:
		level += 1
	return level


static func exp_to_next_level(growth_rate: String, level: int, current_exp: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	var need: int = total_exp_at_level(growth_rate, level + 1)
	return maxi(0, need - current_exp)


static func _medium(n: int) -> int:
	return n * n * n


static func _fast(n: int) -> int:
	return int(4.0 * n * n * n / 5.0)


static func _slow(n: int) -> int:
	return int(5.0 * n * n * n / 4.0)


static func _parabolic(n: int) -> int:
	# Medium Slow
	return int(1.2 * n * n * n - 15.0 * n * n + 100.0 * n - 140.0)


static func _erratic(n: int) -> int:
	if n <= 50:
		return int(n * n * n * (100.0 - n) / 50.0)
	if n <= 68:
		return int(n * n * n * (150.0 - n) / 100.0)
	if n <= 98:
		return int(n * n * n * floor((1911.0 - 10.0 * n) / 3.0) / 500.0)
	return int(n * n * n * (160.0 - n) / 100.0)


static func _fluctuating(n: int) -> int:
	if n <= 15:
		return int(n * n * n * (floor((n + 1) / 3.0) + 24.0) / 50.0)
	if n <= 36:
		return int(n * n * n * (n + 14.0) / 50.0)
	return int(n * n * n * (floor(n / 2.0) + 32.0) / 50.0)
