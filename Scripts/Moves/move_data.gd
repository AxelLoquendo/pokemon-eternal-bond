class_name MoveData
extends Resource
## Ficha de movimiento (campos de gMovesInfo que usaremos ya).

@export var id: MoveId.Id = MoveId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var type: TypeId.Id = TypeId.Id.NONE
@export var category: MoveCategory.Id = MoveCategory.Id.NONE
@export var power: int = 0
@export var accuracy: int = 100 ## 0 = nunca falla (como Swift)
@export var pp: int = 5
@export var priority: int = 0
@export var makes_contact: bool = false


func is_valid() -> bool:
	return id != MoveId.Id.NONE and not display_name.is_empty()


func is_damaging() -> bool:
	return category == MoveCategory.Id.PHYSICAL or category == MoveCategory.Id.SPECIAL
