class_name PokemonInstance
extends Resource
## Estado de un Pokémon concreto (equipo / caja / combate).
## Los datos de especie viven en SpeciesData; aquí solo lo mutable.

const MOVE_SLOTS: int = 4
const STAT_COUNT: int = 6
const IV_MAX: int = 31
const EV_MAX_PER_STAT: int = 252
const EV_MAX_TOTAL: int = 510

@export_group("Identity")
@export var species_id: SpeciesId.Id = SpeciesId.Id.NONE
@export var nickname: String = ""
@export var level: int = 1
@export var exp_points: int = 0
@export var nature: PokemonEnums.Nature = PokemonEnums.Nature.HARDY

@export_group("Ability")
## 0 = ability_1, 1 = ability_2, 2 = ability_hidden
@export var ability_slot: int = 0
@export var ability_id: AbilityId.Id = AbilityId.Id.NONE

@export_group("Moves")
@export var moves: Array[MoveId.Id] = []
@export var move_pp: Array[int] = []
@export var move_pp_ups: Array[int] = []

@export_group("IVs / EVs")
## Orden: HP ATK DEF SPE SPA SPD (PokemonEnums.Stat)
@export var ivs: Array[int] = [0, 0, 0, 0, 0, 0]
@export var evs: Array[int] = [0, 0, 0, 0, 0, 0]
@export var hyper_trained: Array[bool] = [false, false, false, false, false, false]

@export_group("Battle state")
@export var hp: int = 1
@export var max_hp: int = 1
@export var status: String = ""
@export var held_item: ItemId.Id = ItemId.Id.NONE
@export var tera_type: TypeId.Id = TypeId.Id.NONE
@export var terastallized: bool = false

@export_group("Misc")
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


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

func is_valid() -> bool:
	return species_id != SpeciesId.Id.NONE and not is_egg


func is_fainted() -> bool:
	return hp <= 0 or status == "FNT"


func display_name() -> String:
	if not nickname.is_empty():
		return nickname
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species_id)
		if data != null:
			return data.display_name
	return SpeciesId.to_token(species_id)


func species() -> SpeciesData:
	if SpeciesCatalog == null:
		return null
	return SpeciesCatalog.get_data(species_id)


## Tipos activos (sin terastalización).
func types() -> Array[TypeId.Id]:
	var data: SpeciesData = species()
	if data == null:
		return []
	return data.types()


# ---------------------------------------------------------------------------
# Curación / PP
# ---------------------------------------------------------------------------

func heal_full() -> void:
	recalculate_stats()
	hp = max_hp
	status = ""
	terastallized = false
	_restore_all_pp()


func set_moves(new_moves: Array[MoveId.Id]) -> void:
	moves.clear()
	move_pp.clear()
	move_pp_ups.clear()
	for i: int in mini(MOVE_SLOTS, new_moves.size()):
		var mid: MoveId.Id = new_moves[i]
		if mid == MoveId.Id.NONE:
			continue
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
	for i: int in moves.size():
		var pp: int = _base_pp(moves[i])
		if i < move_pp_ups.size():
			# Cada PP Up suma 20% del PP base
			pp = int(pp * (1.0 + 0.2 * move_pp_ups[i]))
		if i < move_pp.size():
			move_pp[i] = pp
		else:
			move_pp.append(pp)


# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------

func recalculate_stats() -> void:
	_refresh_max_hp()
	# max_hp es el único que persistimos; el resto se calcula on demand.


func _refresh_max_hp() -> void:
	max_hp = maxi(1, get_stat(PokemonEnums.Stat.HP))


## Stat final (con naturaleza). HP no usa naturaleza.
func get_stat(stat: PokemonEnums.Stat) -> int:
	var data: SpeciesData = species()
	if data == null:
		return 1 if stat == PokemonEnums.Stat.HP else 5

	var base: int = _base_for(data, stat)
	var iv: int = _iv_for(stat)
	var ev: int = _ev_for(stat)

	if stat == PokemonEnums.Stat.HP:
		if base == 1:
			# Shedinja-style
			return 1
		return int((2 * base + iv + ev / 4) * level / 100.0) + level + 10

	var raw: int = int((2 * base + iv + ev / 4) * level / 100.0) + 5
	return maxi(1, int(raw * _nature_mod(stat)))


func _base_for(data: SpeciesData, stat: PokemonEnums.Stat) -> int:
	match stat:
		PokemonEnums.Stat.HP:
			return data.base_hp
		PokemonEnums.Stat.ATK:
			return data.base_atk
		PokemonEnums.Stat.DEF:
			return data.base_def
		PokemonEnums.Stat.SPE:
			return data.base_spe
		PokemonEnums.Stat.SPA:
			return data.base_spa
		PokemonEnums.Stat.SPD:
			return data.base_spd
	return 1


func _iv_for(stat: PokemonEnums.Stat) -> int:
	var i: int = int(stat)
	if i < 0 or i >= ivs.size():
		return 0
	if i < hyper_trained.size() and hyper_trained[i]:
		return IV_MAX
	return clampi(ivs[i], 0, IV_MAX)


func _ev_for(stat: PokemonEnums.Stat) -> int:
	var i: int = int(stat)
	if i < 0 or i >= evs.size():
		return 0
	return clampi(evs[i], 0, EV_MAX_PER_STAT)


## +10% / -10% / neutro según naturaleza.
func _nature_mod(stat: PokemonEnums.Stat) -> float:
	var up: PokemonEnums.Stat = _nature_up(nature)
	var down: PokemonEnums.Stat = _nature_down(nature)
	if up == down:
		return 1.0
	if stat == up:
		return 1.1
	if stat == down:
		return 0.9
	return 1.0


static func _nature_up(n: PokemonEnums.Nature) -> PokemonEnums.Stat:
	match n:
		PokemonEnums.Nature.LONELY, PokemonEnums.Nature.ADAMANT, PokemonEnums.Nature.NAUGHTY, PokemonEnums.Nature.BRAVE:
			return PokemonEnums.Stat.ATK
		PokemonEnums.Nature.BOLD, PokemonEnums.Nature.IMPISH, PokemonEnums.Nature.LAX, PokemonEnums.Nature.RELAXED:
			return PokemonEnums.Stat.DEF
		PokemonEnums.Nature.MODEST, PokemonEnums.Nature.MILD, PokemonEnums.Nature.RASH, PokemonEnums.Nature.QUIET:
			return PokemonEnums.Stat.SPA
		PokemonEnums.Nature.CALM, PokemonEnums.Nature.GENTLE, PokemonEnums.Nature.CAREFUL, PokemonEnums.Nature.SASSY:
			return PokemonEnums.Stat.SPD
		PokemonEnums.Nature.TIMID, PokemonEnums.Nature.HASTY, PokemonEnums.Nature.JOLLY, PokemonEnums.Nature.NAIVE:
			return PokemonEnums.Stat.SPE
		_:
			return PokemonEnums.Stat.HP # neutras: up==down vía HP sentinel


static func _nature_down(n: PokemonEnums.Nature) -> PokemonEnums.Stat:
	match n:
		PokemonEnums.Nature.BOLD, PokemonEnums.Nature.MODEST, PokemonEnums.Nature.CALM, PokemonEnums.Nature.TIMID:
			return PokemonEnums.Stat.ATK
		PokemonEnums.Nature.LONELY, PokemonEnums.Nature.MILD, PokemonEnums.Nature.GENTLE, PokemonEnums.Nature.HASTY:
			return PokemonEnums.Stat.DEF
		PokemonEnums.Nature.ADAMANT, PokemonEnums.Nature.IMPISH, PokemonEnums.Nature.CAREFUL, PokemonEnums.Nature.JOLLY:
			return PokemonEnums.Stat.SPA
		PokemonEnums.Nature.NAUGHTY, PokemonEnums.Nature.LAX, PokemonEnums.Nature.RASH, PokemonEnums.Nature.NAIVE:
			return PokemonEnums.Stat.SPD
		PokemonEnums.Nature.BRAVE, PokemonEnums.Nature.RELAXED, PokemonEnums.Nature.QUIET, PokemonEnums.Nature.SASSY:
			return PokemonEnums.Stat.SPE
		_:
			return PokemonEnums.Stat.HP


# ---------------------------------------------------------------------------
# Habilidad según slot
# ---------------------------------------------------------------------------

func resolve_ability_from_species() -> void:
	var data: SpeciesData = species()
	if data == null:
		ability_id = AbilityId.Id.NONE
		return
	match clampi(ability_slot, 0, 2):
		0:
			ability_id = data.ability_1
		1:
			ability_id = data.ability_2 if data.ability_2 != AbilityId.Id.NONE else data.ability_1
		2:
			ability_id = data.ability_hidden if data.ability_hidden != AbilityId.Id.NONE else data.ability_1
		_:
			ability_id = data.ability_1


# ---------------------------------------------------------------------------
# Learnset al crear / subir nivel
# ---------------------------------------------------------------------------

## Últimos hasta MOVE_SLOTS movimientos aprendidos hasta `level`.
func apply_level_up_moves_up_to_level() -> void:
	var data: SpeciesData = species()
	if data == null:
		return
	var learned: Array[MoveId.Id] = []
	for entry: LevelUpMove in data.level_moves:
		if entry == null:
			continue
		if entry.level <= level and entry.move != MoveId.Id.NONE:
			# Evitar duplicados; el más reciente queda al final
			var idx: int = learned.find(entry.move)
			if idx >= 0:
				learned.remove_at(idx)
			learned.append(entry.move)
	# Quedarse con los últimos MOVE_SLOTS
	if learned.size() > MOVE_SLOTS:
		learned = learned.slice(learned.size() - MOVE_SLOTS, learned.size())
	set_moves(learned)


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

static func create(
	species: SpeciesId.Id,
	lvl: int = 5,
	with_moves: bool = true,
	random_ivs: bool = true,
) -> PokemonInstance:
	var mon := PokemonInstance.new()
	mon.species_id = species
	mon.level = clampi(lvl, 1, 100)
	mon.met_level = mon.level
	mon.nature = (randi() % 25) as PokemonEnums.Nature

	if random_ivs:
		mon.ivs = [
			randi() % (IV_MAX + 1),
			randi() % (IV_MAX + 1),
			randi() % (IV_MAX + 1),
			randi() % (IV_MAX + 1),
			randi() % (IV_MAX + 1),
			randi() % (IV_MAX + 1),
		]
	else:
		mon.ivs = [0, 0, 0, 0, 0, 0]
	mon.evs = [0, 0, 0, 0, 0, 0]
	mon.hyper_trained = [false, false, false, false, false, false]

	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species)
		if data != null:
			mon.friendship = data.base_friendship
			mon.gender = _roll_gender(data.gender_ratio)

			# Habilidad: 0 o 1 al azar si existe ability_2; oculta solo si se fuerza fuera
			if data.ability_2 != AbilityId.Id.NONE and (randi() % 2) == 1:
				mon.ability_slot = 1
			else:
				mon.ability_slot = 0
			mon.resolve_ability_from_species()

			if data.force_tera_type != TypeId.Id.NONE:
				mon.tera_type = data.force_tera_type
			elif data.type_1 != TypeId.Id.NONE:
				mon.tera_type = data.type_1

	if with_moves:
		mon.apply_level_up_moves_up_to_level()

	mon.recalculate_stats()
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
