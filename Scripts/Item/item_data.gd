class_name ItemData
extends Resource

@export var id: ItemId.Id = ItemId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var pocket: ItemPocket.Id = ItemPocket.Id.ITEMS
@export var price: int = 0
@export var stack_limit: int = 999
@export var important: bool = false

## Tokens de expansion, sin lógica todavía.
@export var hold_effect: String = ""
@export var hold_effect_param: int = 0
@export var field_use: String = ""
@export var battle_use: String = ""
@export var sort_type: String = ""
@export var fling_power: int = 0
## Si es MT/MO, el movimiento que enseña.
@export var tm_move: MoveId.Id = MoveId.Id.NONE


func is_valid() -> bool:
	return id != ItemId.Id.NONE and not display_name.is_empty()
