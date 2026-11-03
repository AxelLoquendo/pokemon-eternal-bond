class_name PokemonInstance
extends Resource
## Un ejemplar concreto (equipo, caja, salvaje). La species vive en SpeciesCatalog.

const GENDER_UNKNOWN: int = -1
const GENDER_MALE: int = 0
const GENDER_FEMALE: int = 1

@export var species: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var form: int = 0
@export var level: int = 1
@export var exp: int = 0
@export var hp: int = 0
@export var max_hp: int = 0
@export var ivs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
@export var evs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
@export var nature: String = "HARDY"

# ability_index elige dentro de species.abilities cuando hidden_ability es false
@export var ability_index: int = 0
@export var hidden_ability: bool = false
@export var ability: AbilityId.Id = AbilityId.Id.NONE

@export var moves: Array[MoveId.Id] = []
@export var pp: PackedInt32Array = PackedInt32Array()
@export var status: String = ""
@export var shiny: bool = false
@export var gender: int = GENDER_UNKNOWN

@export var tera_type: TypeId.Id = TypeId.Id.NONE
@export var terastallized: bool = false


func get_species_data() -> SpeciesData:
	if SpeciesCatalog == null:
		return null
	return SpeciesCatalog.get_species_resolved(species, form)


func get_display_name() -> String:
	if not nickname.is_empty():
		return nickname
	if SpeciesCatalog != null:
		return SpeciesCatalog.get_display_name(species, form)
	return SpeciesId.to_key(species)


func is_fainted() -> bool:
	return hp <= 0


func heal_full() -> void:
	recalc_stats()
	hp = max_hp
	status = ""
	terastallized = false
	_refill_pp()


func resolve_ability() -> AbilityId.Id:
	var sp: SpeciesData = get_species_data()
	if sp == null:
		return ability

	if hidden_ability:
		if sp.hidden_abilities.is_empty():
			return AbilityId.Id.NONE
		return sp.hidden_abilities[0]

	if ability_index >= 0 and ability_index < sp.abilities.size():
		return sp.abilities[ability_index]
	if sp.abilities.is_empty():
		return AbilityId.Id.NONE
	return sp.abilities[0]


func sync_ability() -> void:
	ability = resolve_ability()


func get_types() -> Array[TypeId.Id]:
	# Tera sustituye los tipos naturales (Stellar se decide en batalla).
	if terastallized and TypeId.is_battle_type(tera_type):
		var only_tera: Array[TypeId.Id] = [tera_type]
		return only_tera

	var sp: SpeciesData = get_species_data()
	if sp == null:
		var empty: Array[TypeId.Id] = []
		return empty
	return sp.types.duplicate()


func ensure_tera_type() -> void:
	if tera_type != TypeId.Id.NONE:
		return
	var sp: SpeciesData = get_species_data()
	if sp != null and not sp.types.is_empty():
		tera_type = sp.types[0]


func recalc_stats() -> void:
	# Solo HP por ahora; el resto de stats cuando existan natures.
	var sp: SpeciesData = get_species_data()
	_ensure_iv_ev()
	if sp == null:
		max_hp = maxi(1, max_hp)
		hp = clampi(hp, 0, max_hp)
		return

	var iv_hp: int = int(ivs[0])
	var ev_hp: int = int(evs[0])
	max_hp = int((2.0 * sp.base_hp + iv_hp + ev_hp / 4.0) * level / 100.0) + level + 10
	max_hp = maxi(1, max_hp)
	if hp <= 0 or hp > max_hp:
		hp = max_hp


func _ensure_iv_ev() -> void:
	if ivs.size() < 6:
		ivs = PackedInt32Array([0, 0, 0, 0, 0, 0])
	if evs.size() < 6:
		evs = PackedInt32Array([0, 0, 0, 0, 0, 0])


func _refill_pp() -> void:
	pp = PackedInt32Array()
	for mid: MoveId.Id in moves:
		var md: MoveData = null
		if MoveCatalog:
			md = MoveCatalog.get_move(mid)
		pp.append(md.total_pp if md != null else 5)


func _learn_moves_up_to_level(sp: SpeciesData) -> void:
	moves.clear()
	for lm: Dictionary in sp.level_moves:
		if int(lm.get("level", 99)) > level:
			continue
		var mid: MoveId.Id = MoveId.from_token(str(lm.get("move", "")))
		if mid == MoveId.Id.NONE:
			continue
		if mid in moves:
			continue
		if moves.size() >= 4:
			moves.remove_at(0)
		moves.append(mid)


static func create_from_species(
	species_id: SpeciesId.Id,
	p_level: int = 5,
	p_form: int = 0,
	use_hidden_ability: bool = false,
	forced_tera: TypeId.Id = TypeId.Id.NONE
) -> PokemonInstance:
	var inst := PokemonInstance.new()
	inst.species = species_id
	inst.form = p_form
	inst.level = maxi(1, p_level)
	inst.hidden_ability = use_hidden_ability
	inst.ivs = PackedInt32Array([
		randi_range(0, 31), randi_range(0, 31), randi_range(0, 31),
		randi_range(0, 31), randi_range(0, 31), randi_range(0, 31),
	])
	inst.evs = PackedInt32Array([0, 0, 0, 0, 0, 0])

	var sp: SpeciesData = null
	if SpeciesCatalog:
		sp = SpeciesCatalog.get_species_resolved(species_id, p_form)

	if sp != null:
		inst.nickname = sp.name
		inst.sync_ability()
		inst._learn_moves_up_to_level(sp)

	if forced_tera != TypeId.Id.NONE:
		inst.tera_type = forced_tera
	else:
		inst.ensure_tera_type()

	inst.recalc_stats()
	inst.hp = inst.max_hp
	inst._refill_pp()
	return inst
