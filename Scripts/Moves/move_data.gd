class_name MoveData
extends Resource

@export var id: MoveId.Id = MoveId.Id.NONE
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var type: TypeId.Id = TypeId.Id.NONE
@export var category: MoveCategory.Id = MoveCategory.Id.NONE
@export var power: int = 0
@export var accuracy: int = 100 ## 0 = nunca falla
@export var pp: int = 5
@export var priority: int = 0
@export var target: String = "SELECTED"
@export var effect: String = "EFFECT_HIT"
@export var strike_count: int = 1
@export var critical_stage: int = 0
@export var recoil: int = 0

@export var makes_contact: bool = false
@export var ignores_protect: bool = false
@export var sound: bool = false
@export var punch: bool = false
@export var bite: bool = false
@export var pulse: bool = false
@export var ballistic: bool = false
@export var powder: bool = false
@export var slicing: bool = false
@export var wind: bool = false
@export var dance: bool = false
@export var healing: bool = false
@export var ignores_substitute: bool = false

## Flags que no merecen un bool propio: "metronomeBanned", "mirrorMoveBanned"…
@export var extra_flags: PackedStringArray = PackedStringArray()
@export var z_effect: String = ""


func is_valid() -> bool:
	return id != MoveId.Id.NONE and not display_name.is_empty()

func is_damaging() -> bool:
	return category == MoveCategory.Id.PHYSICAL or category == MoveCategory.Id.SPECIAL
