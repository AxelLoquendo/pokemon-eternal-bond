class_name StairsBehavior
extends TileBehaviorHandler

var shift: Vector2  # LEFT = (-1,0) visual, no cambia tile logic

func _init(s: Vector2 = Vector2.ZERO) -> void:
	shift = s

func can_enter(_ctx: TileBehaviorContext) -> bool:
	return true
