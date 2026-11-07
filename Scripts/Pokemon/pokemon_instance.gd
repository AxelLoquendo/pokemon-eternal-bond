class_name PokemonInstance
extends Resource
## Un Pokémon en partida (equipo / caja). Forma actual = species_id.

@export var species_id: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var level: int = 1
@export var exp_points: int = 0

@export var hp: int = 1
@export var max_hp: int = 1
@export var status: String = "" ## "", "PSN", "BRN", "PAR", "SLP", "FRZ", "FNT"…

@export var is_shiny: bool = false
@export var is_female: bool = false
@export var friendship: int = 50

## Cuando existan AbilityId / MoveId se tiparán en serio.
@export var ability_token: String = ""
@export var move_tokens: PackedStringArray = PackedStringArray()


func is_valid() -> bool:
	return species_id != SpeciesId.Id.NONE


func is_fainted() -> bool:
	return hp <= 0 or status == "FNT"


func heal_full() -> void:
	_refresh_max_hp_from_catalog()
	hp = max_hp
	if status == "FNT" or status.is_empty() == false:
		status = ""


func display_name() -> String:
	if not nickname.is_empty():
		return nickname
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species_id)
		if data != null:
			return data.display_name
	return SpeciesId.to_token(species_id)


func _refresh_max_hp_from_catalog() -> void:
	## Fórmula mínima hasta tener StatsCalculator.
	## HP = floor((2*base + IV + EV/4) * level / 100) + level + 10
	## Aquí IV=0, EV=0 para el stub.
	if SpeciesCatalog == null:
		max_hp = maxi(1, max_hp)
		return
	var data: SpeciesData = SpeciesCatalog.get_data(species_id)
	if data == null:
		max_hp = maxi(1, max_hp)
		return
	var base: int = data.base_hp
	max_hp = int((2 * base) * level / 100.0) + level + 10
	max_hp = maxi(1, max_hp)


## Factory simple para pruebas / eventos.
static func create(species: SpeciesId.Id, lvl: int = 5) -> PokemonInstance:
	var mon := PokemonInstance.new()
	mon.species_id = species
	mon.level = clampi(lvl, 1, 100)
	mon._refresh_max_hp_from_catalog()
	mon.hp = mon.max_hp
	mon.status = ""
	return mon
