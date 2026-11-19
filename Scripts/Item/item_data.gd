class_name ItemData
extends Resource
## Ficha de un ítem. Fuente de verdad = este .tres (no el JSON en runtime).

@export_group("Identity")
@export var id: ItemId.Id = ItemId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Bag / economy")
@export var pocket: ItemPocket.Id = ItemPocket.Id.ITEMS
@export var price: int = 0
@export var stack_limit: int = 999
@export var important: bool = false

@export_group("Graphics")
## Relativo a res://Graficos/Items/icons/  (ej. "poke_ball", sin .png).
## Vacío = se deriva del token del id (POKE_BALL → poke_ball).
@export var icon_name: String = ""

@export_group("Effects (tokens expansion)")
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


## Nombre de archivo de icono sin extensión.
func resolved_icon_name() -> String:
	if not icon_name.is_empty():
		return icon_name
	return ItemId.to_token(id).to_lower()
