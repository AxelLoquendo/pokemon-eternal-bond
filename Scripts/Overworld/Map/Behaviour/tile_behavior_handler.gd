class_name TileBehaviorHandler
extends RefCounted


func can_enter(_ctx: TileBehaviorContext) -> bool:
	return true


func on_landed(_ctx: TileBehaviorContext) -> void:
	pass

func on_step_start(_ctx: TileBehaviorContext) -> void:
	pass


func visual_offset() -> Vector2:
	return Vector2.ZERO
