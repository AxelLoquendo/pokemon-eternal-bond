class_name PokemonInstance
extends Resource
## Un Pokémon concreto (party / caja). No es la species del PBS.

var sp: SpeciesData = SpeciesCatalog.get_species_resolved(species, form)

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
@export var gender: int = -1


static func create_from_species(species_id: SpeciesId.Id, level: int = 5) -> PokemonInstance:
	var inst := PokemonInstance.new()
	inst.species = species_id
	inst.level = level
	var sp: SpeciesData = SpeciesCatalog.get_species(species_id) if SpeciesCatalog else null
	if sp != null:
		inst.nickname = sp.name
		if not sp.abilities.is_empty():
			inst.ability = sp.abilities[0]
		# Stats/HP reales cuando tengas la fórmula; placeholder:
		inst.max_hp = maxi(1, sp.base_hp)
		inst.hp = inst.max_hp
		for lm: Dictionary in sp.level_moves:
			if int(lm.get("level", 99)) <= level:
				var mid: MoveId.Id = MoveId.from_token(str(lm.get("move", "")))
				if mid != MoveId.Id.NONE and mid not in inst.moves and inst.moves.size() < 4:
					inst.moves.append(mid)
	return inst
