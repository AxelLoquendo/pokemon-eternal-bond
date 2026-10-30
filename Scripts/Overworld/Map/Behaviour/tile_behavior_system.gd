class_name TileBehaviorSystem
extends RefCounted

static var _handlers: Dictionary[int, TileBehaviorHandler] = {}


static func _ensure() -> void:
	if not _handlers.is_empty():
		return
	_handlers[TileBehaviorId.Id.NONE] = TileBehaviorHandler.new()
	_handlers[TileBehaviorId.Id.LEDGE_DOWN] = LedgeBehavior.new(Vector2.DOWN)
	_handlers[TileBehaviorId.Id.LEDGE_UP] = LedgeBehavior.new(Vector2.UP)
	_handlers[TileBehaviorId.Id.LEDGE_LEFT] = LedgeBehavior.new(Vector2.LEFT)
	_handlers[TileBehaviorId.Id.LEDGE_RIGHT] = LedgeBehavior.new(Vector2.RIGHT)
	_handlers[TileBehaviorId.Id.WATER] = WaterBehavior.new()
	_handlers[TileBehaviorId.Id.ICE] = IceBehavior.new()
	# LOWER está en la casilla baja y sube; UPPER está en la casilla alta y baja.
	_handlers[TileBehaviorId.Id.STAIRS_RIGHT_LOWER] = StairsBehavior.new(Vector2(1, -1))
	_handlers[TileBehaviorId.Id.STAIRS_RIGHT_UPPER] = StairsBehavior.new(Vector2(-1, 1))
	_handlers[TileBehaviorId.Id.STAIRS_LEFT_LOWER] = StairsBehavior.new(Vector2(-1, -1))
	_handlers[TileBehaviorId.Id.STAIRS_LEFT_UPPER] = StairsBehavior.new(Vector2(1, 1))
	_handlers[TileBehaviorId.Id.TALL_GRASS] = TallGrassBehavior.new()
	_handlers[TileBehaviorId.Id.SAND] = SandBehavior.new()

static func get_handler(id: int) -> TileBehaviorHandler:
	_ensure()
	if _handlers.has(id):
		return _handlers[id]
	return _handlers[TileBehaviorId.Id.NONE]


static func build_context(
	controller: CharacterController,
	from_world: Vector2,
	to_world: Vector2,
	via_world: Vector2 = Vector2.ZERO,
	is_hop: bool = false
) -> TileBehaviorContext:
	var ctx: TileBehaviorContext = TileBehaviorContext.new()
	ctx.controller = controller
	ctx.from_world = from_world
	ctx.to_world = to_world
	ctx.via_world = via_world
	ctx.is_hop = is_hop
	var delta: Vector2 = to_world - from_world
	if absf(delta.x) > absf(delta.y):
		ctx.direction = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT
	elif delta.y != 0.0:
		ctx.direction = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	else:
		ctx.direction = Vector2.ZERO
	ctx.from_behavior = TileBehaviorReader.get_behavior_at_world(from_world)
	ctx.to_behavior = TileBehaviorReader.get_behavior_at_world(to_world)
	if is_hop:
		ctx.via_behavior = TileBehaviorReader.get_behavior_at_world(via_world)
	return ctx


## ¿Intentar entrar a un tile con behavior de ledge en la dirección del salto?
static func is_ledge_jump_entry(to_behavior: int, direction: Vector2) -> bool:
	match to_behavior:
		TileBehaviorId.Id.LEDGE_DOWN:
			return direction == Vector2.DOWN
		TileBehaviorId.Id.LEDGE_UP:
			return direction == Vector2.UP
		TileBehaviorId.Id.LEDGE_LEFT:
			return direction == Vector2.LEFT
		TileBehaviorId.Id.LEDGE_RIGHT:
			return direction == Vector2.RIGHT
		_:
			return false


static func can_enter(ctx: TileBehaviorContext) -> bool:
	# Las mitades superior e inferior pueden recorrerse verticalmente a pie.
	# Ese movimiento manual ya coloca al actor en la otra celda, así que no
	# debe convertirse en una segunda transición diagonal.
	if (
		StairsBehavior.is_stairs(ctx.from_behavior)
		and StairsBehavior.is_stairs(ctx.to_behavior)
		and ctx.direction.y != 0.0
	):
		return true

	var from_h: TileBehaviorHandler = get_handler(ctx.from_behavior)
	var leaving_stairs: bool = (
		StairsBehavior.is_stairs(ctx.from_behavior)
		and not StairsBehavior.is_stairs(ctx.to_behavior)
	)
	# La dirección del behaviour restringe la entrada a la escalera, no la
	# salida desde su extremo. Al aterrizar en la mitad superior/inferior hay
	# que poder continuar hacia el terreno libre.
	if not leaving_stairs and not from_h.can_enter(ctx):
		return false
	if ctx.is_hop:
		var via_h: TileBehaviorHandler = get_handler(ctx.via_behavior)
		if not via_h.can_enter(ctx):
			return false
	return get_handler(ctx.to_behavior).can_enter(ctx)


static func on_landed(ctx: TileBehaviorContext) -> void:
	if ctx.controller != null and ctx.to_behavior != TileBehaviorId.Id.NONE:
		ctx.controller.notify_tile_behavior_landed(ctx.to_behavior)
	get_handler(ctx.to_behavior).on_landed(ctx)


static func visual_offset(behavior_id: int) -> Vector2:
	return get_handler(behavior_id).visual_offset()


static func stairs_target(from_world: Vector2, direction: Vector2) -> Vector2:
	var entry_world: Vector2 = from_world + direction * 16.0
	var behavior_id: int = TileBehaviorReader.get_behavior_at_world(entry_world)
	var diagonal: Vector2 = _stairs_movement(behavior_id, direction)
	if diagonal != Vector2.ZERO:
		return from_world + diagonal * 16.0

	# Si el actor ya está sobre una mitad marcada y cambia de sentido,
	# permite invertir la marcha desde esa misma casilla.
	behavior_id = TileBehaviorReader.get_behavior_at_world(from_world)
	diagonal = _stairs_movement(behavior_id, direction)
	if diagonal != Vector2.ZERO:
		return from_world + diagonal * 16.0
	return Vector2.ZERO


static func _stairs_movement(behavior_id: int, direction: Vector2) -> Vector2:
	if not StairsBehavior.is_stairs(behavior_id):
		return Vector2.ZERO
	var handler: StairsBehavior = get_handler(behavior_id) as StairsBehavior
	return handler.movement_for(direction)


static func on_step_start(ctx: TileBehaviorContext) -> void:
	get_handler(ctx.from_behavior).on_step_start(ctx)
	if ctx.is_hop:
		get_handler(ctx.via_behavior).on_step_start(ctx)
	get_handler(ctx.to_behavior).on_step_start(ctx)
