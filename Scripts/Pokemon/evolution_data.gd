class_name EvolutionData
extends Resource
## method = token de expansion (LEVEL, ITEM, TRADE, SPIN…).
## param = nivel, ítem, u otro argumento principal.
## conditions = { "kind": "IF_MIN_FRIENDSHIP", "value": "220" } etc.

@export var method: String = ""
@export var param: String = ""
@export var target: SpeciesId.Id = SpeciesId.Id.NONE
@export var conditions: Array[Dictionary] = []
