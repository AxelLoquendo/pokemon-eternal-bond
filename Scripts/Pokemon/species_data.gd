class_name SpeciesData
extends Resource
## Datos de una especie o forma concreta.

@export var id: SpeciesId.Id = SpeciesId.Id.NONE
@export var display_name: String = ""
@export var types: Array[TypeId.Id] = []

@export var base_hp: int = 1
@export var base_atk: int = 1
@export var base_def: int = 1
@export var base_spa: int = 1
@export var base_spd: int = 1
@export var base_spe: int = 1

@export var catch_rate: int = 45
@export var base_exp: int = 0
@export var base_friendship: int = 50
@export var gender_ratio: String = "Female50Percent"
@export var growth_rate: String = "MediumFast"

## Tokens de habilidad (cuando exista AbilityId se resolverán ahí).
@export var ability_tokens: PackedStringArray = PackedStringArray()
@export var hidden_ability_tokens: PackedStringArray = PackedStringArray()

@export var height_m: float = 0.0
@export var weight_kg: float = 0.0
@export_multiline var pokedex: String = ""


func is_valid() -> bool:
	return id != SpeciesId.Id.NONE and not display_name.is_empty()
