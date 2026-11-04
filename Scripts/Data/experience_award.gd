class_name ExperienceAward
extends Object
## Exp al derrotar (fórmula Gen 3–4).


static func from_defeat(
	defeated_level: int,
	defeated_base_exp: int,
	participants: int = 1,
	from_trainer: bool = false,
	lucky_egg: bool = false,
	traded: bool = false
) -> int:
	if defeated_level < 1 or defeated_base_exp < 1:
		return 0

	var amount: float = float(defeated_base_exp) * float(defeated_level) / 7.0
	if from_trainer:
		amount *= 1.5
	amount /= float(maxi(1, participants))
	if lucky_egg:
		amount *= 1.5
	if traded:
		amount *= 1.5
	return maxi(1, int(amount))


static func from_species(
	sp: SpeciesData,
	defeated_level: int,
	participants: int = 1,
	from_trainer: bool = false,
	lucky_egg: bool = false,
	traded: bool = false
) -> int:
	if sp == null:
		return 0
	return from_defeat(
		defeated_level, sp.base_exp, participants, from_trainer, lucky_egg, traded
	)
