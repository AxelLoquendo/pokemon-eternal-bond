class_name LedgeBehavior
extends TileBehaviorHandler

var jump_dir: Vector2


func _init(dir: Vector2) -> void:
	jump_dir = dir


func can_enter(ctx: TileBehaviorContext) -> bool:
	var my_id: int = _id_for_dir(jump_dir)
	var crossed_id: int = ctx.via_behavior if ctx.is_hop else ctx.to_behavior

	# El borde solo se cruza con un salto en la dirección marcada.
	if crossed_id == my_id and ctx.direction != jump_dir:
		return false

	# Desde el borde tampoco se puede retroceder hacia la caída.
	if ctx.from_behavior == my_id and ctx.direction != jump_dir:
		return false

	return true


func on_step_start(ctx: TileBehaviorContext) -> void:
	var crossed_id: int = ctx.via_behavior if ctx.is_hop else ctx.to_behavior
	if crossed_id != _id_for_dir(jump_dir):
		return
	if ctx.direction != jump_dir:
		return
	if ctx.controller == null:
		return
	ctx.jump_animation_played = true


static func _id_for_dir(dir: Vector2) -> int:
	if dir == Vector2.DOWN:
		return TileBehaviorId.Id.LEDGE_DOWN
	if dir == Vector2.UP:
		return TileBehaviorId.Id.LEDGE_UP
	if dir == Vector2.LEFT:
		return TileBehaviorId.Id.LEDGE_LEFT
	if dir == Vector2.RIGHT:
		return TileBehaviorId.Id.LEDGE_RIGHT
	return TileBehaviorId.Id.NONE
