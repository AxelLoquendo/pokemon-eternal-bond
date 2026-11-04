class_name SpeedOrder
extends Object
## Quién actúa primero (sin trick room; eso lo aplica batalla invirtiendo).


static func effective_speed(poke: PokemonInstance, speed_stage: int = 0) -> int:
	if poke == null:
		return 0
	return StatStages.apply(poke.speed, speed_stage)


## > 0 atacante más rápido, < 0 defensor, 0 empate (la batalla tira moneda).
static func compare(
	a: PokemonInstance,
	b: PokemonInstance,
	a_stage: int = 0,
	b_stage: int = 0,
	a_priority: int = 0,
	b_priority: int = 0
) -> int:
	if a_priority != b_priority:
		return a_priority - b_priority
	return effective_speed(a, a_stage) - effective_speed(b, b_stage)
