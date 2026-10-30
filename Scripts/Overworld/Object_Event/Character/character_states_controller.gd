class_name CharacterStatesController
extends Node2D

@onready var controller: CharacterController = $"../CharacterController"
@onready var animation_controller: CharacterAnimatedController = $"../CharacterAnimatedController"

enum State { IDLE, WALK, RUN, STAIRS, LOCKED }

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var _stairs_direction: Vector2 = Vector2.ZERO


func process_state(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_idle()
		State.WALK:
			_walk()
		State.RUN:
			_run()
		State.STAIRS:
			_stairs()
		State.LOCKED:
			_locked()
	if current_state != previous_state:
		_on_state_changed()
	previous_state = current_state


func change_state(new_state: State) -> void:
	current_state = new_state
	if new_state != State.STAIRS:
		_stairs_direction = Vector2.ZERO


func begin_stairs(direction: Vector2) -> void:
	_stairs_direction = direction
	change_state(State.STAIRS)


func consume_stairs_input(direction: Vector2, next_cell_is_stairs: bool) -> bool:
	if current_state != State.STAIRS:
		return false
	if direction == _stairs_direction and next_cell_is_stairs:
		return true
	change_state(State.IDLE)
	return false


func is_locked() -> bool:
	return current_state == State.LOCKED


func _on_state_changed() -> void:
	match current_state:
		State.IDLE, State.LOCKED:
			if controller and not controller.is_bumping() and animation_controller:
				animation_controller.play_idle_animation(controller.last_direction)
		State.WALK, State.RUN, State.STAIRS:
			pass


func _idle() -> void:
	if controller == null:
		return
	if controller.moving:
		change_state(State.WALK)
		return
	if controller.is_bumping():
		return
	if animation_controller:
		animation_controller.play_idle_animation(controller.last_direction)


func _walk() -> void:
	if controller == null:
		return
	if controller.moving:
		return
	change_state(State.IDLE)


func _run() -> void:
	pass


func _stairs() -> void:
	# CharacterController decide cuándo la transición terminó y cuándo
	# consumir o reanudar la dirección de entrada.
	pass


func _locked() -> void:
	if controller == null:
		return
	if controller.is_bumping():
		return
	if animation_controller:
		animation_controller.play_idle_animation(controller.last_direction)
