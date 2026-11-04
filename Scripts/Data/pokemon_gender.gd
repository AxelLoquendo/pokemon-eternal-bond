class_name PokemonGender
extends Object

const UNKNOWN: int = -1
const MALE: int = 0
const FEMALE: int = 1


static func roll(gender_ratio: String) -> int:
	match gender_ratio.strip_edges():
		"Genderless", "AlwaysNone", "":
			return UNKNOWN
		"AlwaysMale":
			return MALE
		"AlwaysFemale":
			return FEMALE
		"FemaleOneEighth":
			return FEMALE if randf() < 0.125 else MALE
		"Female25Percent":
			return FEMALE if randf() < 0.25 else MALE
		"Female50Percent":
			return FEMALE if randf() < 0.5 else MALE
		"Female75Percent":
			return FEMALE if randf() < 0.75 else MALE
		"FemaleSevenEighths":
			return FEMALE if randf() < 0.875 else MALE
		_:
			return FEMALE if randf() < 0.5 else MALE


static func from_species(sp: SpeciesData) -> int:
	if sp == null:
		return UNKNOWN
	return roll(sp.gender_ratio)
