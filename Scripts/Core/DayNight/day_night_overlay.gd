# day_night_overlay.gd
extends CanvasModulate
class_name DayNightOverlay

const LERP_SPEED: float = 1.5


func _ready() -> void:
	color = Color.WHITE


func _process(delta: float) -> void:
	if DayNightManager == null:
		return
	var target: Color = DayNightManager.current_tint()
	color = color.lerp(target, delta * LERP_SPEED)
