class_name IceBehavior
extends TileBehaviorHandler


func can_enter(_ctx: TileBehaviorContext) -> bool:
	return true


func on_landed(ctx: TileBehaviorContext) -> void:
	if ctx.controller == null:
		return
	var dir: Vector2 = ctx.direction
	if dir == Vector2.ZERO:
		return
	# Empuja un paso más en la misma dirección si no está bloqueado
	if ctx.controller.has_method("start_move"):
		ctx.controller.call_deferred("start_move", dir)
