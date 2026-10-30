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
	# start_move() no recibe args: usa direction del controller
	ctx.controller.direction = dir
	ctx.controller.last_direction = dir
	ctx.controller.call_deferred("start_move")
