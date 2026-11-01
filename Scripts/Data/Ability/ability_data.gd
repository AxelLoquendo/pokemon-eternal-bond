class_name AbilityData
extends Resource

@export var id: AbilityId.Id = AbilityId.Id.NONE
@export var name: String = ""
@export_multiline var description: String = ""


static func from_dict(d: Dictionary) -> AbilityData:
	var data := AbilityData.new()
	data.id = AbilityId.from_token(str(d.get("id", "")))
	data.name = str(d.get("name", ""))
	data.description = str(d.get("description", ""))
	return data
