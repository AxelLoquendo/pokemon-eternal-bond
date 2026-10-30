class_name CollisionFacade
extends RefCounted
## Fachada de movimiento: entidad OR tile OR behavior (ledge, etc.).
## CharacterController solo habla con esta clase para decidir el paso.

const TILE_SIZE: float = 16.0


static func is_stairs_tile(world_position: Vector2) -> bool:
	return StairsBehavior.is_stairs(TileBehaviorReader.get_behavior_at_world(world_position))


static func is_blocked(
	controller: CharacterController,
	target_world: Vector2,
	via_world: Vector2 = Vector2.ZERO,
	is_hop: bool = false,
	is_stairs_transition: bool = false
) -> bool:
	if EntityCollisionSystem.is_position_occupied(target_world, controller):
		return true
	if not MapCollisionSystem.can_enter(
		controller.height_level,
		controller.elevated,
		controller.get_character_position(),
		target_world,
		controller,
		via_world,
		is_hop,
		is_stairs_transition
	):
		return true
	return false


## Resuelve destino real del paso (1 tile o salto de ledge a 2 tiles).
static func resolve_move(
	controller: CharacterController,
	direction: Vector2
) -> MoveStepResult:
	var result: MoveStepResult = MoveStepResult.new()
	if direction == Vector2.ZERO:
		result.blocked = true
		return result

	var from_world: Vector2 = controller.get_character_position()
	var one_step: Vector2 = from_world + direction * TILE_SIZE
	var two_step: Vector2 = from_world + direction * TILE_SIZE * 2.0

	# Las escaleras laterales conservan el paso horizontal, pero desembocan
	# una celda arriba o abajo. La aproximación puede estar bloqueada por el
	# borde; solo se valida la salida diagonal real.
	var stairs_target: Vector2 = TileBehaviorSystem.stairs_target(from_world, direction)
	if stairs_target != Vector2.ZERO:
		result.target_world = stairs_target
		result.behavior_world = one_step
		result.stairs_transition = true
		result.blocked = is_blocked(controller, stairs_target, Vector2.ZERO, false, true)
		return result

	var mid_behavior: int = TileBehaviorReader.get_behavior_at_world(one_step)
	if TileBehaviorSystem.is_ledge_jump_entry(mid_behavior, direction):
		result.behavior_world = one_step
		result.target_world = two_step
		if is_blocked(controller, two_step, one_step, true):
			result.blocked = true
			result.hop = false
		else:
			result.hop = true
		return result

	result.behavior_world = one_step
	result.target_world = one_step
	result.hop = false
	if is_blocked(controller, one_step):
		result.blocked = true
	return result
