class_name PokemonInstance
extends Resource
## Un Pokémon concreto (party / caja). No es la species del PBS.

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
@export var ability_index: int = 0
@export var ability: AbilityId.Id = AbilityId.Id.NONE
@export var moves: Array[MoveId.Id] = []
@export var pp: PackedInt32Array = PackedInt32Array()
@export var status: String = ""
@export var shiny: bool = false
@export var gender: int = -1  # -1 unknown, 0 male, 1 female


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
	_refill_pp()


func recalc_stats() -> void:
	## Fórmula simple Gen 3+ (placeholder hasta natures finas).
	var sp: SpeciesData = get_species_data()
	if sp == null:
		max_hp = maxi(1, max_hp)
		hp = mini(hp, max_hp)
		return
	_ensure_iv_ev()
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
		var md: MoveData = MoveCatalog.get_move(mid) if MoveCatalog else null
		var total: int = md.total_pp if md != null else 5
		pp.append(total)


static func create_from_species(
	species_id: SpeciesId.Id,
	p_level: int = 5,
	p_form: int = 0
) -> PokemonInstance:
	var inst := PokemonInstance.new()
	inst.species = species_id
	inst.form = p_form
	inst.level = maxi(1, p_level)
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
		if not sp.abilities.is_empty():
			inst.ability_index = 0
			inst.ability = sp.abilities[0]
		for lm: Dictionary in sp.level_moves:
			if int(lm.get("level", 99)) <= inst.level:
				var mid: MoveId.Id = MoveId.from_token(str(lm.get("move", "")))
				if mid != MoveId.Id.NONE and mid not in inst.moves and inst.moves.size() < 4:
					inst.moves.append(mid)

	inst.recalc_stats()
	inst.hp = inst.max_hp
	inst._refill_pp()
	return inst