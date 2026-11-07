class_name ItemData
extends Resource
## Ficha de un ítem (campos que el overworld y la bag necesitan ahora).

@export var id: ItemId.Id = ItemId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var pocket: ItemPocket.Id = ItemPocket.Id.ITEMS
@export var price: int = 0
@export var stack_limit: int = 999
## true = no se tira / no se vende (llaves, etc.)
@export var important: bool = false


func is_valid() -> bool:
	return id != ItemId.Id.NONE and not display_name.is_empty()
