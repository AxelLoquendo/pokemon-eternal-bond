class_name CatchCalc
extends Object
## Captura Gen 3/4 simplificada (sin dark grass).


static func shake_probability(
	max_hp: int,
	current_hp: int,
	catch_rate: int,
	ball_mult: float = 1.0,
	status_mult: float = 1.0
) -> float:
	if max_hp <= 0:
		return 0.0
	var a: float = float(3 * max_hp - 2 * current_hp) * float(catch_rate) * ball_mult
	a = a / float(3 * max_hp)
	a *= status_mult
	a = clampf(a, 0.0, 255.0)
	if a >= 255.0:
		return 1.0
	# Probabilidad de un shake; 4 shakes = captura
	var b: float = 1048560.0 / sqrt(sqrt(16711680.0 / a))
	return clampf(b / 65536.0, 0.0, 1.0)


static func try_catch(
	max_hp: int,
	current_hp: int,
	catch_rate: int,
	ball_mult: float = 1.0,
	status_mult: float = 1.0
) -> bool:
	var p: float = shake_probability(max_hp, current_hp, catch_rate, ball_mult, status_mult)
	if p >= 1.0:
		return true
	for i: int in 4:
		if randf() >= p:
			return false
	return true
