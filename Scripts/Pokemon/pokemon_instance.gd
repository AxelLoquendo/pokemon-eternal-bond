class_name PokemonInstance
extends Resource

const MOVE_SLOTS: int = 4
const STAT_COUNT: int = 6

@export var species_id: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var level: int = 1
@export var exp_points: int = 0
@export var nature: PokemonEnums.Nature = PokemonEnums.Nature.HARDY

@export var ability_slot: int = 0 ## 0..2, el 2 es oculta
@export var ability_id: AbilityId.Id = AbilityId.Id.NONE

@export var moves: Array[MoveId.Id] = []
@export var move_pp: Array[int] = []
@export var move_pp_ups: Array[int] = []

@export var ivs: Array[int] = [0, 0, 0, 0, 0, 0] ## HP ATK DEF SPE SPA SPD
@export var evs: Array[int] = [0, 0, 0, 0, 0, 0]
@export var hyper_trained: Array[bool] = [false, false, false, false, false, false]

@export var hp: int = 1
@export var max_hp: int = 1
@export var status: String = ""

@export var held_item: ItemId.Id = ItemId.Id.NONE
@export var tera_type: TypeId.Id = TypeId.Id.NONE
@export var terastallized: bool = false

@export var gender: PokemonEnums.Gender = PokemonEnums.Gender.MALE
@export var is_shiny: bool = false
@export var friendship: int = 50
@export var ball: ItemId.Id = ItemId.Id.POKE_BALL
@export var is_egg: bool = false

@export var dynamax_level: int = 0
@export var gmax_factor: bool = false
@export var pokerus: int = 0

@export var ot_name: String = ""
@export var met_location: String = ""
@export var met_level: int = 1


func is_valid() -> bool:
	return species_id != SpeciesId.Id.NONE and not is_egg


func is_fainted() -> bool:
	return hp <= 0 or status == "FNT"


func heal_full() -> void:
	_refresh_max_hp()
	hp = max_hp
	status = ""
	terastallized = false
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
	move_pp_ups.clear()
	for i in mini(MOVE_SLOTS, new_moves.size()):
		var mid: MoveId.Id = new_moves[i]
		moves.append(mid)
		move_pp.append(_base_pp(mid))
		move_pp_ups.append(0)


func _base_pp(mid: MoveId.Id) -> int:
	if MoveCatalog:
		var md: MoveData = MoveCatalog.get_move(mid)
		if md != null:
			return md.pp
	return 5


func _restore_all_pp() -> void:
	for i in moves.size():
		var pp: int = _base_pp(moves[i])
		if i < move_pp.size():
			move_pp[i] = pp
		else:
			move_pp.append(pp)


func _refresh_max_hp() -> void:
	if SpeciesCatalog == null:
		max_hp = maxi(1, max_hp)
		return
	var data: SpeciesData = SpeciesCatalog.get_data(species_id)
	if data == null:
		max_hp = maxi(1, max_hp)
		return
	var iv: int = ivs[PokemonEnums.Stat.HP] if ivs.size() > PokemonEnums.Stat.HP else 0
	var ev: int = evs[PokemonEnums.Stat.HP] if evs.size() > PokemonEnums.Stat.HP else 0
	max_hp = int((2 * data.base_hp + iv + ev / 4) * level / 100.0) + level + 10
	max_hp = maxi(1, max_hp)


static func create(species: SpeciesId.Id, lvl: int = 5) -> PokemonInstance:
	var mon := PokemonInstance.new()
	mon.species_id = species
	mon.level = clampi(lvl, 1, 100)
	mon.met_level = mon.level
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species)
		if data != null:
			mon.friendship = data.base_friendship
			if data.abilities.size() > 0:
				mon.ability_slot = 0
				mon.ability_id = data.abilities[0]
			if data.force_tera_type != TypeId.Id.NONE:
				mon.tera_type = data.force_tera_type
			elif data.types.size() > 0:
				mon.tera_type = data.types[0]
			mon.gender = _roll_gender(data.gender_ratio)
	mon._refresh_max_hp()
	mon.hp = mon.max_hp
	return mon


static func _roll_gender(ratio: int) -> PokemonEnums.Gender:
	if ratio >= PokemonEnums.GENDER_UNKNOWN:
		return PokemonEnums.Gender.GENDERLESS
	if ratio <= PokemonEnums.GENDER_MALE_ONLY:
		return PokemonEnums.Gender.MALE
	if ratio >= PokemonEnums.GENDER_FEMALE_ONLY:
		return PokemonEnums.Gender.FEMALE
	if randi() % 256 < ratio:
		return PokemonEnums.Gender.FEMALE
	return PokemonEnums.Gender.MALE
