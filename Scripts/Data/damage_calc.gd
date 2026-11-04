class_name DamageCalc
extends Object
## Daño base Gen 3+ sin efectos de habilidad/campo (eso lo suma la batalla).


static func physical_attack(attacker: PokemonInstance, atk_stage: int = 0) -> int:
	return StatStages.apply(attacker.attack, atk_stage)


static func physical_defense(defender: PokemonInstance, def_stage: int = 0) -> int:
	return StatStages.apply(defender.defense, def_stage)


static func special_attack(attacker: PokemonInstance, spa_stage: int = 0) -> int:
	return StatStages.apply(attacker.sp_attack, spa_stage)


static func special_defense(defender: PokemonInstance, spd_stage: int = 0) -> int:
	return StatStages.apply(defender.sp_defense, spd_stage)


static func stab_multiplier(move_type: TypeId.Id, attacker_types: Array) -> float:
	for t: Variant in attacker_types:
		if (t as TypeId.Id) == move_type and move_type != TypeId.Id.NONE:
			return 1.5
	return 1.0


static func type_multiplier(move_type: TypeId.Id, defender_types: Array) -> float:
	return TypeChart.against_types(move_type, defender_types)


## random_factor: 0.85–1.00; pasa -1.0 para tirar dentro.
static func compute(
	attacker_level: int,
	move_power: int,
	attack_stat: int,
	defense_stat: int,
	stab: float = 1.0,
	type_mult: float = 1.0,
	critical: float = 1.0,
	other_mult: float = 1.0,
	random_factor: float = -1.0
) -> int:
	if move_power <= 0 or attack_stat <= 0 or defense_stat <= 0:
		return 0

	var level_term: float = float(2 * attacker_level / 5 + 2)
	var base: float = level_term * float(move_power) * float(attack_stat) / float(defense_stat)
	base = base / 50.0 + 2.0

	var roll: float = random_factor
	if roll < 0.0:
		roll = randf_range(0.85, 1.0)

	var damage: float = base * critical * roll * stab * type_mult * other_mult
	return maxi(1, int(damage))


## Atajo: elige atk/def según categoría del move.
static func compute_from_move(
	attacker: PokemonInstance,
	defender: PokemonInstance,
	move: MoveData,
	atk_stage: int = 0,
	def_stage: int = 0,
	spa_stage: int = 0,
	spd_stage: int = 0,
	is_critical: bool = false,
	other_mult: float = 1.0
) -> int:
	if move == null or attacker == null or defender == null:
		return 0
	if move.category == MoveData.Category.STATUS or move.power <= 0:
		return 0

	var atk: int
	var def: int
	if move.category == MoveData.Category.PHYSICAL:
		atk = physical_attack(attacker, atk_stage)
		def = physical_defense(defender, def_stage)
	else:
		atk = special_attack(attacker, spa_stage)
		def = special_defense(defender, spd_stage)

	var stab: float = stab_multiplier(move.type, attacker.get_types())
	var types: float = type_multiplier(move.type, defender.get_types())
	var crit: float = CriticalCalc.damage_multiplier(is_critical)

	return compute(
		attacker.level,
		move.power,
		atk,
		def,
		stab,
		types,
		crit,
		other_mult
	)
