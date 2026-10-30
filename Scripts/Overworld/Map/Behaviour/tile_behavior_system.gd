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
	_handlers[TileBehaviorId.Id.STAIRS_LEFT] = StairsBehavior.new(Vector2.LEFT)
	_handlers[TileBehaviorId.Id.STAIRS_RIGHT] = StairsBehavior.new(Vector2.RIGHT)
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
	var from_h: TileBehaviorHandler = get_handler(ctx.from_behavior)
	if not from_h.can_enter(ctx):
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


static func on_step_start(ctx: TileBehaviorContext) -> void:
	get_handler(ctx.from_behavior).on_step_start(ctx)
	if ctx.is_hop:
		get_handler(ctx.via_behavior).on_step_start(ctx)
	get_handler(ctx.to_behavior).on_step_start(ctx)
