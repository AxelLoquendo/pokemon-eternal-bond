class_name StairsBehavior
extends TileBehaviorHandler

const VISUAL_SHIFT_PIXELS: float = 4.0

var shift: Vector2  # Dirección visual lateral; no cambia la celda lógica.

func _init(s: Vector2 = Vector2.ZERO) -> void:
	shift = s

func can_enter(_ctx: TileBehaviorContext) -> bool:
	return true


func visual_offset() -> Vector2:
	return Vector2(shift.x * VISUAL_SHIFT_PIXELS, 0.0)
