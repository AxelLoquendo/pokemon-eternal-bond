class_name SpeciesData
extends Resource
## Ficha de una especie o forma. Una forma = un SpeciesId.

const ABILITY_SLOTS: int = 3 ## [0] y [1] normales, [2] oculta

@export var id: SpeciesId.Id = SpeciesId.Id.NONE
@export var display_name: String = ""
@export var category: String = ""
@export var national_dex: int = 0
@export_multiline var pokedex: String = ""

@export var types: Array[TypeId.Id] = []
## TYPE_NONE = no forzado. Si no es NONE, el individuo nace con este tera.
@export var force_tera_type: TypeId.Id = TypeId.Id.NONE

@export var base_hp: int = 1
@export var base_atk: int = 1
@export var base_def: int = 1
@export var base_spa: int = 1
@export var base_spd: int = 1
@export var base_spe: int = 1

@export var ev_hp: int = 0
@export var ev_atk: int = 0
@export var ev_def: int = 0
@export var ev_spa: int = 0
@export var ev_spd: int = 0
@export var ev_spe: int = 0

@export var catch_rate: int = 45
@export var base_exp: int = 0
@export var base_friendship: int = 50
## Byte de expansion. Ver PokemonEnums.GENDER_*
@export var gender_ratio: int = 127
@export var growth_rate: PokemonEnums.Growth = PokemonEnums.Growth.MEDIUM_FAST
@export var egg_cycles: int = 20
@export var egg_groups: Array[PokemonEnums.EggGroup] = []

@export var abilities: Array[AbilityId.Id] = []
@export var item_common: ItemId.Id = ItemId.Id.NONE
@export var item_rare: ItemId.Id = ItemId.Id.NONE

@export var height_dm: int = 0
@export var weight_hg: int = 0
@export var body_color: PokemonEnums.BodyColor = PokemonEnums.BodyColor.RED
@export var no_flip: bool = false

@export var is_restricted_legendary: bool = false
@export var is_sub_legendary: bool = false
@export var is_mythical: bool = false
@export var is_ultra_beast: bool = false
@export var is_paradox: bool = false
@export var is_totem: bool = false
@export var is_mega: bool = false
@export var is_primal: bool = false
@export var is_ultra_burst: bool = false
@export var is_gigantamax: bool = false
@export var is_tera_form: bool = false
@export var is_alolan: bool = false
@export var is_galarian: bool = false
@export var is_hisuian: bool = false
@export var is_paldean: bool = false
@export var cannot_be_traded: bool = false
@export var perfect_iv_count: int = 0

## { "level": int, "move": MoveId.Id }
@export var level_moves: Array[Dictionary] = []
@export var tutor_moves: Array[MoveId.Id] = []
@export var egg_moves: Array[MoveId.Id] = []
@export var evolutions: Array[EvolutionData] = []
## Otras formas de la misma familia (formSpeciesIdTable).
@export var form_species: Array[SpeciesId.Id] = []
@export var form_changes: Array[FormChangeData] = []


func is_valid() -> bool:
	return id != SpeciesId.Id.NONE and not display_name.is_empty()


func hidden_ability() -> AbilityId.Id:
	if abilities.size() >= ABILITY_SLOTS:
		return abilities[ABILITY_SLOTS - 1]
	return AbilityId.Id.NONE
