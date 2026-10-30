@tool
class_name CharacterController
extends Node2D

@onready var entity_root: Node2D = get_parent().get_parent() as Node2D
@onready var sprite: AnimatedSprite2D = entity_root.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var shadow_sprite: Sprite2D = entity_root.get_node_or_null("ShadowSprite") as Sprite2D
@onready var states: CharacterStatesController = $"../CharacterStatesController"

signal movement_finished
signal movement_blocked
signal facing_changed(direction: Vector2)
signal step_started(direction: Vector2, hop: bool)
signal bump_started(direction: Vector2)
signal bump_ended(direction: Vector2)
signal tile_behavior_landed(behavior_id: int)
signal forced_move_finished

const TILE_SIZE: float = 16.0
const MOVE_SPEED: float = 64.0
const HOLD_THRESHOLD: float = 0.12
const BUMP_COOLDOWN: float = 0.25
const HOP_HEIGHT: float = 11.0
const HOP_PEAK: float = 0.38
const HOP_SPEED_MULT: float = 1.6
const BUMP_ANIM_SPEED: float = 1.0
const Z_GROUND: int = 0
const Z_ELEVATED: int = 3

var current_position: Vector2
var initial_position: Vector2
var target_position: Vector2
var moving: bool = false
var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var move_progress: float = 0.0
var input_direction: Vector2 = Vector2.ZERO
var hold_time: float = 0.0
var waiting_for_move: bool = false
var external_move: bool = false
var bump_cooldown: float = 0.0
var move_speed: float = MOVE_SPEED
var ledge_hop: bool = false
var forced_move_direction: Vector2 = Vector2.ZERO
var _current_move_is_forced: bool = false
var last_completed_move_was_forced: bool = false
var _sprite_base_position: Vector2 = Vector2.ZERO
var _shadow_base_position: Vector2 = Vector2.ZERO
var _visual_offset_from: Vector2 = Vector2.ZERO
var _visual_offset_to: Vector2 = Vector2.ZERO
var _sprite_base_y: float = 0.0

var height_level: int = 0
var elevated: bool = false


func _ready() -> void:
	entity_root.global_position = snap_to_grid(entity_root.global_position)
	current_position = entity_root.global_position
	initial_position = entity_root.global_position
	target_position = entity_root.global_position
	if sprite:
		set_sprite_base_position(sprite.position)
	if shadow_sprite:
		set_shadow_base_position(shadow_sprite.position)


func set_sprite_base_y(y: float) -> void:
	_sprite_base_y = y
	_sprite_base_position.y = y
	_apply_visual_offset(_visual_offset_to)


func set_sprite_base_position(position: Vector2) -> void:
	_sprite_base_position = position
	_sprite_base_y = position.y
	_apply_visual_offset(_visual_offset_to)


func set_shadow_base_position(position: Vector2) -> void:
	_shadow_base_position = position
	_apply_visual_offset(_visual_offset_to)


func set_move_speed(speed: float) -> void:
	if speed <= 0.0:
		return
	move_speed = speed


func is_bumping() -> bool:
	return bump_cooldown > 0.0


func set_direction(new_direction: Vector2) -> void:
	input_direction = new_direction


func get_direction() -> Vector2:
	return input_direction


func request_move(new_direction: Vector2) -> void:
	if states != null and states.is_locked():
		return
	if moving or new_direction == Vector2.ZERO:
		return
	external_move = true
	direction = new_direction
	last_direction = new_direction
	if not start_move():
		external_move = false


func process_movement(delta: float) -> void:
	if states != null and states.is_locked():
		input_direction = Vector2.ZERO
		external_move = false
		waiting_for_move = false
		return

	var was_bumping: bool = bump_cooldown > 0.0
	if bump_cooldown > 0.0:
		bump_cooldown = maxf(bump_cooldown - delta, 0.0)
		if was_bumping and bump_cooldown <= 0.0 and not moving:
			bump_ended.emit(last_direction)

	if moving:
		process_move(delta)
		return
	if waiting_for_move:
		process_input_hold(delta)
		return
	if external_move:
		return
	process_input()


func process_input() -> void:
	var new_direction: Vector2 = get_direction()
	if new_direction == Vector2.ZERO:
		return
	input_direction = new_direction
	if new_direction != last_direction:
		direction = new_direction
		last_direction = new_direction
		hold_time = 0.0
		waiting_for_move = true
		step_started.emit(direction, false)
		return
	direction = new_direction
	start_move()


func process_input_hold(delta: float) -> void:
	var current_dir: Vector2 = get_direction()
	if current_dir == Vector2.ZERO:
		waiting_for_move = false
		hold_time = 0.0
		return
	if current_dir != input_direction:
		input_direction = current_dir
		direction = current_dir
		last_direction = current_dir
		hold_time = 0.0
		step_started.emit(direction, false)
		return
	hold_time += delta
	if hold_time >= HOLD_THRESHOLD:
		waiting_for_move = false
		start_move()


func start_move(is_forced_move: bool = false) -> bool:
	initial_position = entity_root.global_position
	var step: MoveStepResult = CollisionFacade.resolve_move(self, direction)
	if step.blocked:
		_current_move_is_forced = false
		_play_bump()
		movement_blocked.emit()
		return false
	target_position = step.target_world
	ledge_hop = step.hop
	move_progress = 0.0
	moving = true
	_current_move_is_forced = is_forced_move
	last_completed_move_was_forced = false
	var behavior_world: Vector2 = step.behavior_world if step.hop else Vector2.ZERO
	var step_context: TileBehaviorContext = TileBehaviorSystem.build_context(
		self,
		initial_position,
		target_position,
		behavior_world,
		step.hop
	)
	_visual_offset_from = TileBehaviorSystem.visual_offset(step_context.from_behavior)
	_visual_offset_to = TileBehaviorSystem.visual_offset(step_context.to_behavior)
	TileBehaviorSystem.on_step_start(step_context)
	step_started.emit(direction, ledge_hop)
	return true


func process_move(delta: float) -> void:
	var dist: float = initial_position.distance_to(target_position)
	if dist < 0.001:
		dist = TILE_SIZE
	var speed: float = move_speed
	if ledge_hop:
		speed *= HOP_SPEED_MULT
	move_progress += (speed * delta) / dist
	move_progress = minf(move_progress, 1.0)
	entity_root.global_position = initial_position.lerp(target_position, _ease_move(move_progress))
	MapCollisionSystem.preview_render_state(self, initial_position, target_position)
	_apply_visual_offset(_visual_offset_from.lerp(_visual_offset_to, move_progress))
	if sprite:
		if ledge_hop:
			sprite.position.y = _sprite_base_y - _hop_height(move_progress)
		else:
			sprite.position.y = _sprite_base_y
	if move_progress >= 1.0:
		entity_root.global_position = target_position
		if sprite:
			sprite.position.y = _sprite_base_y
		_apply_visual_offset(_visual_offset_to)
		current_position = target_position
		moving = false
		ledge_hop = false
		last_completed_move_was_forced = _current_move_is_forced
		_current_move_is_forced = false

		MapCollisionSystem.apply_cell_state(self, initial_position, target_position)

		movement_finished.emit()
		if forced_move_direction != Vector2.ZERO:
			var forced_direction: Vector2 = forced_move_direction
			forced_move_direction = Vector2.ZERO
			external_move = false
			direction = forced_direction
			last_direction = forced_direction
			input_direction = Vector2.ZERO
			start_move(true)
			return
		if last_completed_move_was_forced:
			forced_move_finished.emit()
		if external_move:
			external_move = false
			return
		var next_dir: Vector2 = get_direction()
		if next_dir != Vector2.ZERO:
			direction = next_dir
			last_direction = next_dir
			start_move()

func look_direction(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return
	direction = new_direction
	last_direction = new_direction
	facing_changed.emit(new_direction)


func halt_for_interaction() -> bool:
	var reached: bool = moving and move_progress >= 0.5
	var tile: Vector2 = snap_to_grid(entity_root.global_position)
	if moving:
		tile = target_position if reached else initial_position
	entity_root.global_position = tile
	if sprite:
		sprite.position.y = _sprite_base_y
	current_position = tile
	initial_position = tile
	target_position = tile
	moving = false
	move_progress = 0.0
	external_move = false
	forced_move_direction = Vector2.ZERO
	input_direction = Vector2.ZERO
	waiting_for_move = false
	hold_time = 0.0
	ledge_hop = false
	_refresh_visual_offset(tile)
	return reached


func teleport_to(world_pos: Vector2) -> void:
	var snapped: Vector2 = snap_to_grid(world_pos)
	entity_root.global_position = snapped
	if sprite:
		sprite.position.y = _sprite_base_y
	current_position = snapped
	initial_position = snapped
	target_position = snapped
	moving = false
	move_progress = 0.0
	external_move = false
	forced_move_direction = Vector2.ZERO
	waiting_for_move = false
	hold_time = 0.0
	ledge_hop = false
	_refresh_visual_offset(snapped)


func get_character_position() -> Vector2:
	return entity_root.global_position


func queue_forced_move(move_direction: Vector2) -> void:
	if move_direction == Vector2.ZERO:
		return
	forced_move_direction = move_direction


func is_forced_move_active() -> bool:
	return moving and _current_move_is_forced


func notify_tile_behavior_landed(behavior_id: int) -> void:
	tile_behavior_landed.emit(behavior_id)


func refresh_behavior_visual(world_position: Vector2) -> void:
	_refresh_visual_offset(world_position)


func _refresh_visual_offset(world_position: Vector2) -> void:
	var behavior_id: int = TileBehaviorReader.get_behavior_at_world(world_position)
	_visual_offset_from = TileBehaviorSystem.visual_offset(behavior_id)
	_visual_offset_to = _visual_offset_from
	_apply_visual_offset(_visual_offset_to)


func _apply_visual_offset(offset: Vector2) -> void:
	if sprite != null:
		sprite.position = _sprite_base_position + offset
	if shadow_sprite != null:
		shadow_sprite.position = _shadow_base_position + offset


@warning_ignore("shadowed_variable_base_class")
func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / TILE_SIZE) * TILE_SIZE,
		round(pos.y / TILE_SIZE) * TILE_SIZE
	)


func _play_bump() -> void:
	if bump_cooldown > 0.0:
		return
	bump_started.emit(direction)
	bump_cooldown = BUMP_COOLDOWN


func _ease_move(t: float) -> float:
	if not ledge_hop:
		return t
	return t * t * (3.0 - 2.0 * t)


func _hop_height(t: float) -> float:
	if t <= HOP_PEAK:
		var u: float = t / HOP_PEAK
		return HOP_HEIGHT * (1.0 - (1.0 - u) * (1.0 - u))
	var v: float = (t - HOP_PEAK) / (1.0 - HOP_PEAK)
	return HOP_HEIGHT * (1.0 - v * v)

func update_render_layer() -> void:
	## Solo ajusta z_index del entity según elevated (puentes / altura).
	if entity_root == null:
		return
	entity_root.z_index = Z_ELEVATED if elevated else Z_GROUND
