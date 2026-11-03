class_name TypeChart
extends Object

# attack -> { defend -> multiplier }  (omitido = 1.0)
const _CHART: Dictionary = {
	TypeId.Id.NORMAL: {
		TypeId.Id.ROCK: 0.5, TypeId.Id.GHOST: 0.0, TypeId.Id.STEEL: 0.5,
	},
	TypeId.Id.FIGHTING: {
		TypeId.Id.NORMAL: 2.0, TypeId.Id.FLYING: 0.5, TypeId.Id.POISON: 0.5,
		TypeId.Id.ROCK: 2.0, TypeId.Id.BUG: 0.5, TypeId.Id.GHOST: 0.0,
		TypeId.Id.STEEL: 2.0, TypeId.Id.PSYCHIC: 0.5, TypeId.Id.ICE: 2.0,
		TypeId.Id.DARK: 2.0, TypeId.Id.FAIRY: 0.5,
	},
	TypeId.Id.FLYING: {
		TypeId.Id.FIGHTING: 2.0, TypeId.Id.ROCK: 0.5, TypeId.Id.BUG: 2.0,
		TypeId.Id.STEEL: 0.5, TypeId.Id.GRASS: 2.0, TypeId.Id.ELECTRIC: 0.5,
	},
	TypeId.Id.POISON: {
		TypeId.Id.POISON: 0.5, TypeId.Id.GROUND: 0.5, TypeId.Id.ROCK: 0.5,
		TypeId.Id.GHOST: 0.5, TypeId.Id.STEEL: 0.0, TypeId.Id.GRASS: 2.0,
		TypeId.Id.FAIRY: 2.0,
	},
	TypeId.Id.GROUND: {
		TypeId.Id.FLYING: 0.0, TypeId.Id.POISON: 2.0, TypeId.Id.ROCK: 2.0,
		TypeId.Id.BUG: 0.5, TypeId.Id.STEEL: 2.0, TypeId.Id.FIRE: 2.0,
		TypeId.Id.GRASS: 0.5, TypeId.Id.ELECTRIC: 2.0,
	},
	TypeId.Id.ROCK: {
		TypeId.Id.FIGHTING: 0.5, TypeId.Id.FLYING: 2.0, TypeId.Id.GROUND: 0.5,
		TypeId.Id.BUG: 2.0, TypeId.Id.STEEL: 0.5, TypeId.Id.FIRE: 2.0,
		TypeId.Id.ICE: 2.0,
	},
	TypeId.Id.BUG: {
		TypeId.Id.FIGHTING: 0.5, TypeId.Id.FLYING: 0.5, TypeId.Id.POISON: 0.5,
		TypeId.Id.GHOST: 0.5, TypeId.Id.STEEL: 0.5, TypeId.Id.FIRE: 0.5,
		TypeId.Id.GRASS: 2.0, TypeId.Id.PSYCHIC: 2.0, TypeId.Id.DARK: 2.0,
		TypeId.Id.FAIRY: 0.5,
	},
	TypeId.Id.GHOST: {
		TypeId.Id.NORMAL: 0.0, TypeId.Id.GHOST: 2.0,
		TypeId.Id.PSYCHIC: 2.0, TypeId.Id.DARK: 0.5,
	},
	TypeId.Id.STEEL: {
		TypeId.Id.ROCK: 2.0, TypeId.Id.STEEL: 0.5, TypeId.Id.FIRE: 0.5,
		TypeId.Id.WATER: 0.5, TypeId.Id.ELECTRIC: 0.5, TypeId.Id.ICE: 2.0,
		TypeId.Id.FAIRY: 2.0,
	},
	TypeId.Id.FIRE: {
		TypeId.Id.ROCK: 0.5, TypeId.Id.BUG: 2.0, TypeId.Id.STEEL: 2.0,
		TypeId.Id.FIRE: 0.5, TypeId.Id.WATER: 0.5, TypeId.Id.GRASS: 2.0,
		TypeId.Id.ICE: 2.0, TypeId.Id.DRAGON: 0.5,
	},
	TypeId.Id.WATER: {
		TypeId.Id.GROUND: 2.0, TypeId.Id.ROCK: 2.0, TypeId.Id.FIRE: 2.0,
		TypeId.Id.WATER: 0.5, TypeId.Id.GRASS: 0.5, TypeId.Id.DRAGON: 0.5,
	},
	TypeId.Id.GRASS: {
		TypeId.Id.FLYING: 0.5, TypeId.Id.POISON: 0.5, TypeId.Id.GROUND: 2.0,
		TypeId.Id.ROCK: 2.0, TypeId.Id.BUG: 0.5, TypeId.Id.STEEL: 0.5,
		TypeId.Id.FIRE: 0.5, TypeId.Id.WATER: 2.0, TypeId.Id.GRASS: 0.5,
		TypeId.Id.DRAGON: 0.5,
	},
	TypeId.Id.ELECTRIC: {
		TypeId.Id.FLYING: 2.0, TypeId.Id.GROUND: 0.0, TypeId.Id.WATER: 2.0,
		TypeId.Id.GRASS: 0.5, TypeId.Id.ELECTRIC: 0.5, TypeId.Id.DRAGON: 0.5,
	},
	TypeId.Id.PSYCHIC: {
		TypeId.Id.FIGHTING: 2.0, TypeId.Id.POISON: 2.0, TypeId.Id.STEEL: 0.5,
		TypeId.Id.PSYCHIC: 0.5, TypeId.Id.DARK: 0.0,
	},
	TypeId.Id.ICE: {
		TypeId.Id.FLYING: 2.0, TypeId.Id.GROUND: 2.0, TypeId.Id.STEEL: 0.5,
		TypeId.Id.FIRE: 0.5, TypeId.Id.WATER: 0.5, TypeId.Id.GRASS: 2.0,
		TypeId.Id.ICE: 0.5, TypeId.Id.DRAGON: 2.0,
	},
	TypeId.Id.DRAGON: {
		TypeId.Id.STEEL: 0.5, TypeId.Id.DRAGON: 2.0, TypeId.Id.FAIRY: 0.0,
	},
	TypeId.Id.DARK: {
		TypeId.Id.FIGHTING: 0.5, TypeId.Id.GHOST: 2.0, TypeId.Id.PSYCHIC: 2.0,
		TypeId.Id.DARK: 0.5, TypeId.Id.FAIRY: 0.5,
	},
	TypeId.Id.FAIRY: {
		TypeId.Id.FIGHTING: 2.0, TypeId.Id.POISON: 0.5, TypeId.Id.STEEL: 0.5,
		TypeId.Id.FIRE: 0.5, TypeId.Id.DRAGON: 2.0, TypeId.Id.DARK: 2.0,
	},
}


static func multiplier(attack: TypeId.Id, defend: TypeId.Id) -> float:
	if attack == TypeId.Id.NONE or defend == TypeId.Id.NONE:
		return 1.0
	if attack == TypeId.Id.STELLAR or defend == TypeId.Id.STELLAR:
		return 1.0
	var row: Variant = _CHART.get(attack)
	if row is Dictionary:
		return float((row as Dictionary).get(defend, 1.0))
	return 1.0


static func against_types(attack: TypeId.Id, defend_types: Array) -> float:
	var total: float = 1.0
	for t: Variant in defend_types:
		total *= multiplier(attack, t as TypeId.Id)
	return total
