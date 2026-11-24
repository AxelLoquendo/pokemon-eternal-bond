extends CanvasLayer

@onready var bg_anim: AnimationPlayer = $BG/BG_Lluvia

@onready var slots: Array[Node2D] = [
	$Party_Slot,
	$Party_Slot2,
	$Party_Slot3,
	$Party_Slot4,
	$Party_Slot5,
	$Party_Slot6
]

func _ready() -> void:
	bg_anim.play("Lluvia_BG")
