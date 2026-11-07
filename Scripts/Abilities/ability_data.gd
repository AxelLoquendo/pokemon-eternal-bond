class_name AbilityData
extends Resource
## Ficha de habilidad. El efecto de batalla se implementará aparte.

@export var id: AbilityId.Id = AbilityId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""


func is_valid() -> bool:
	return id != AbilityId.Id.NONE and not display_name.is_empty()
