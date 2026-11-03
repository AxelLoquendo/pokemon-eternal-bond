class_name PokemonInstance
extends Resource
## Ejemplar concreto (equipo, caja, salvaje). La species está en SpeciesCatalog.

const GENDER_UNKNOWN: int = -1
const GENDER_MALE: int = 0
const GENDER_FEMALE: int = 1

# Orden IV/EV alineado con BaseStats del PBS
const IV_HP: int = 0
const IV_ATK: int = 1
const IV_DEF: int = 2
const IV_SPE: int = 3
const IV_SPA: int = 4
const IV_SPD: int = 5

@export var species: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var form: int = 0
@export var level: int = 1
@export var exp: int = 0

@export var hp: int = 0
@export var max_hp: int = 0
@export var attack: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var sp_attack: int = 0
@export var sp_defense: int = 0

@export var ivs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
@export var evs: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
@export var nature: NatureId.Id = NatureId.Id.HARDY

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
	if terastallized and TypeId.is_battle_type(tera_type):
		var only: Array[TypeId.Id] = [tera_type]
		return only
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

func growth_rate() -> String:
	var sp: SpeciesData = get_species_data()
	if sp == null:
		return "Medium"
	return sp.growth_rate


func sync_exp_to_level() -> void:
	## Exp mínima del nivel actual (p. ej. al crear o forzar level).
	exp = ExperienceGrowth.total_exp_at_level(growth_rate(), level)


func exp_needed_for_next_level() -> int:
	return ExperienceGrowth.exp_to_next_level(growth_rate(), level, exp)


## Devuelve cuántos niveles subió (0 si no hubo level up).
func gain_exp(amount: int) -> int:
	if amount <= 0 or level >= ExperienceGrowth.MAX_LEVEL:
		return 0

	var rate: String = growth_rate()
	exp += amount
	var levels_gained: int = 0
	var new_level: int = ExperienceGrowth.level_for_exp(rate, exp)

	while level < new_level:
		level += 1
		levels_gained += 1
		_on_level_up()

	if level >= ExperienceGrowth.MAX_LEVEL:
		level = ExperienceGrowth.MAX_LEVEL
		exp = ExperienceGrowth.total_exp_at_level(rate, ExperienceGrowth.MAX_LEVEL)

	return levels_gained


func _on_level_up() -> void:
	var old_max: int = max_hp
	recalc_stats()
	# Conserva el daño actual al subir HP máximo.
	var missing: int = maxi(0, old_max - hp)
	hp = maxi(1, max_hp - missing)

	var sp: SpeciesData = get_species_data()
	if sp != null:
		_try_learn_moves_at_level(sp, level)


func _try_learn_moves_at_level(sp: SpeciesData, at_level: int) -> void:
	for lm: Dictionary in sp.level_moves:
		if int(lm.get("level", -1)) != at_level:
			continue
		var mid: MoveId.Id = MoveId.from_token(str(lm.get("move", "")))
		if mid == MoveId.Id.NONE or mid in moves:
			continue
		if moves.size() < 4:
			moves.append(mid)
			_refill_pp()
		# Con 4 movimientos: la batalla/UI decidirá a cuál reemplazar.

func recalc_stats() -> void:
	_ensure_iv_ev()
	var sp: SpeciesData = get_species_data()
	if sp == null:
		max_hp = maxi(1, max_hp)
		hp = clampi(hp, 0, max_hp)
		return

	var old_max: int = max_hp
	max_hp = _calc_hp(sp.base_hp, int(ivs[IV_HP]), int(evs[IV_HP]))
	attack = _calc_stat(sp.base_atk, int(ivs[IV_ATK]), int(evs[IV_ATK]), "atk")
	defense = _calc_stat(sp.base_def, int(ivs[IV_DEF]), int(evs[IV_DEF]), "def")
	speed = _calc_stat(sp.base_spe, int(ivs[IV_SPE]), int(evs[IV_SPE]), "spe")
	sp_attack = _calc_stat(sp.base_spa, int(ivs[IV_SPA]), int(evs[IV_SPA]), "spa")
	sp_defense = _calc_stat(sp.base_spd, int(ivs[IV_SPD]), int(evs[IV_SPD]), "spd")

	if old_max <= 0 or hp <= 0:
		hp = max_hp
	elif hp > max_hp:
		hp = max_hp


func _calc_hp(base: int, iv: int, ev: int) -> int:
	# floor((2*B + IV + EV/4) * Level / 100) + Level + 10
	return int((2.0 * base + iv + ev / 4.0) * level / 100.0) + level + 10


func _calc_stat(base: int, iv: int, ev: int, nature_key: String) -> int:
	# floor((floor((2*B + IV + EV/4) * Level / 100) + 5) * nature)
	var raw: int = int((2.0 * base + iv + ev / 4.0) * level / 100.0) + 5
	var mod: float = NatureId.multiplier(nature, nature_key)
	return maxi(1, int(raw * mod))


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
		if mid == MoveId.Id.NONE or mid in moves:
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
	inst.nature = NatureId.random()
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

	inst.sync_exp_to_level()
	inst.recalc_stats()
	inst.hp = inst.max_hp
	inst._refill_pp()
	return inst
