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
	ctx.controller.queue_forced_move(dir)
