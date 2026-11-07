class_name PokemonInstance
extends Resource
## Un Pokémon en partida. Forma actual = species_id.

const MOVE_SLOTS: int = 4

@export var species_id: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var level: int = 1
@export var exp_points: int = 0

@export var hp: int = 1
@export var max_hp: int = 1
@export var status: String = ""

@export var is_shiny: bool = false
@export var is_female: bool = false
@export var friendship: int = 50

@export var ability_id: AbilityId.Id = AbilityId.Id.NONE
@export var moves: Array[MoveId.Id] = []
@export var move_pp: Array[int] = [] ## paralelo a moves


func is_valid() -> bool:
	return species_id != SpeciesId.Id.NONE


func is_fainted() -> bool:
	return hp <= 0 or status == "FNT"


func heal_full() -> void:
	_refresh_max_hp_from_catalog()
	hp = max_hp
	status = ""
	_restore_all_pp()


func display_name() -> String:
	if not nickname.is_empty():
		return nickname
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species_id)
		if data != null:
			return data.display_name
	return SpeciesId.to_token(species_id)


func set_moves(new_moves: Array[MoveId.Id]) -> void:
	moves.clear()
	move_pp.clear()
	for i in mini(MOVE_SLOTS, new_moves.size()):
		var mid: MoveId.Id = new_moves[i]
		moves.append(mid)
		var pp: int = 5
		if MoveCatalog:
			var md: MoveData = MoveCatalog.get_move(mid)
			if md != null:
				pp = md.pp
		move_pp.append(pp)


func _restore_all_pp() -> void:
	for i in moves.size():
		var mid: MoveId.Id = moves[i]
		var pp: int = 5
		if MoveCatalog:
			var md: MoveData = MoveCatalog.get_move(mid)
			if md != null:
				pp = md.pp
		if i < move_pp.size():
			move_pp[i] = pp
		else:
			move_pp.append(pp)


func _refresh_max_hp_from_catalog() -> void:
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


static func create(species: SpeciesId.Id, lvl: int = 5) -> PokemonInstance:
	var mon: PokemonInstance = PokemonInstance.new()
	mon.species_id = species
	mon.level = clampi(lvl, 1, 100)
	mon._refresh_max_hp_from_catalog()
	mon.hp = mon.max_hp
	mon.status = ""
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species)
		if data != null and data.abilities.size() > 0:
			mon.ability_id = data.abilities[0]
	return mon
