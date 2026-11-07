class_name AbilityData
extends Resource

@export var id: AbilityId.Id = AbilityId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var ai_rating: int = 0

@export var cant_be_copied: bool = false
@export var cant_be_swapped: bool = false
@export var cant_be_traced: bool = false
@export var cant_be_suppressed: bool = false
@export var cant_be_overwritten: bool = false
@export var breakable: bool = false
@export var fails_on_imposter: bool = false


func is_valid() -> bool:
	return id != AbilityId.Id.NONE and not display_name.is_empty()
