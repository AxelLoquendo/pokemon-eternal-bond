class_name StairsBehavior
extends TileBehaviorHandler

## LOWER se marca en la casilla inferior para subir; UPPER en la superior para bajar.
## El vector mueve una casilla en X y otra en Y en un solo paso.
var diagonal: Vector2

func _init(move: Vector2 = Vector2.ZERO) -> void:
	diagonal = move

func can_enter(ctx: TileBehaviorContext) -> bool:
	# Evita cruzar la escalera de lado contrario cuando no se activa
	# la transición diagonal (por ejemplo, desde el extremo de salida).
	return ctx.direction.x * diagonal.x > 0.0


func movement_for(direction: Vector2) -> Vector2:
	if direction.x == 0.0 or direction.x * diagonal.x <= 0.0:
		return Vector2.ZERO
	return diagonal


static func is_stairs(behavior_id: int) -> bool:
	return behavior_id in [
		TileBehaviorId.Id.STAIRS_RIGHT_LOWER,
		TileBehaviorId.Id.STAIRS_RIGHT_UPPER,
		TileBehaviorId.Id.STAIRS_LEFT_LOWER,
		TileBehaviorId.Id.STAIRS_LEFT_UPPER,
	]
