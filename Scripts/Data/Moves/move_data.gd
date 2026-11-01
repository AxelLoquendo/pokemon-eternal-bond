class_name MoveData
extends Resource

enum Category { PHYSICAL, SPECIAL, STATUS }

@export var id: MoveId.Id = MoveId.Id.NONE
@export var name: String = ""
@export var type: TypeId.Id = TypeId.Id.NONE
@export var category: Category = Category.STATUS
@export var power: int = 0
@export var accuracy: int = 0
@export var total_pp: int = 5
@export var priority: int = 0
@export var target: String = "NearOther"
@export var function_code: String = "None"
@export var flags: PackedStringArray = PackedStringArray()
@export_multiline var description: String = ""


static func from_dict(d: Dictionary) -> MoveData:
	var data := MoveData.new()
	data.id = MoveId.from_token(str(d.get("id", "")))
	data.name = str(d.get("name", ""))
	data.type = TypeId.from_token(str(d.get("type", "")))
	data.category = _parse_category(str(d.get("category", "Status")))
	data.power = int(d.get("power", 0))
	data.accuracy = int(d.get("accuracy", 0))
	data.total_pp = int(d.get("total_pp", 5))
	data.priority = int(d.get("priority", 0))
	data.target = str(d.get("target", "NearOther"))
	data.function_code = str(d.get("function_code", "None"))
	data.description = str(d.get("description", ""))
	var fl: Variant = d.get("flags", [])
	if fl is Array:
		for x: Variant in fl:
			data.flags.append(str(x))
	return data


static func _parse_category(s: String) -> Category:
	match s.strip_edges().to_lower():
		"physical":
			return Category.PHYSICAL
		"special":
			return Category.SPECIAL
		_:
			return Category.STATUS
