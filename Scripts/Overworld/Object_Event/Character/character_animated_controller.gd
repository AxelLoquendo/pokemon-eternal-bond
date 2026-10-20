class_name CharacterAnimatedController
extends Node2D

@onready var entity_root: Node2D = get_parent().get_parent() as Node2D
@onready var sprite: AnimatedSprite2D = entity_root.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var controller: CharacterController = $"../CharacterController"

var step: int = 0

enum AnimStates {
	IDLE_DOWN, IDLE_UP, IDLE_LEFT, IDLE_RIGHT,
	FIRST_STEP_DOWN, FIRST_STEP_UP, FIRST_STEP_LEFT, FIRST_STEP_RIGHT,
	SECOND_STEP_DOWN, SECOND_STEP_UP, SECOND_STEP_LEFT, SECOND_STEP_RIGHT,
}

const Anim: Dictionary = {
	AnimStates.IDLE_DOWN: "Idle_Down",
	AnimStates.IDLE_UP: "Idle_Up",
	AnimStates.IDLE_LEFT: "Idle_Left",
	AnimStates.IDLE_RIGHT: "Idle_Right",
	AnimStates.FIRST_STEP_DOWN: "First_Step_Down",
	AnimStates.FIRST_STEP_UP: "First_Step_Up",
	AnimStates.FIRST_STEP_LEFT: "First_Step_Left",
	AnimStates.FIRST_STEP_RIGHT: "First_Step_Right",
	AnimStates.SECOND_STEP_DOWN: "Second_Step_Down",
	AnimStates.SECOND_STEP_UP: "Second_Step_Up",
	AnimStates.SECOND_STEP_LEFT: "Second_Step_Left",
	AnimStates.SECOND_STEP_RIGHT: "Second_Step_Right",
}


func _ready() -> void:
	if controller == null:
		return
	controller.step_started.connect(_on_step_started)
	controller.facing_changed.connect(play_idle_animation)
	controller.bump_started.connect(_on_bump_started)
	controller.bump_ended.connect(play_idle_animation)


func _on_step_started(direction: Vector2, _hop: bool) -> void:
	play_step_animation(direction)


func _on_bump_started(direction: Vector2) -> void:
	if sprite == null:
		play_step_animation(direction)
		return
	sprite.speed_scale = CharacterController.BUMP_ANIM_SPEED
	play_step_animation(direction)
	_restore_anim_speed()


func _restore_anim_speed() -> void:
	await get_tree().create_timer(CharacterController.BUMP_COOLDOWN).timeout
	if is_instance_valid(sprite):
		sprite.speed_scale = 1.0


func play_step_animation(direction: Vector2) -> void:
	step += 1
	_play(get_step_animation(direction))


func get_step_animation(direction: Vector2) -> String:
	var state: AnimStates
	if step % 2 == 1:
		state = _first_step(direction)
	else:
		state = _second_step(direction)
	return Anim[state]


func _first_step(direction: Vector2) -> AnimStates:
	match direction:
		Vector2.DOWN:
			return AnimStates.FIRST_STEP_DOWN
		Vector2.UP:
			return AnimStates.FIRST_STEP_UP
		Vector2.LEFT:
			return AnimStates.FIRST_STEP_LEFT
		Vector2.RIGHT:
			return AnimStates.FIRST_STEP_RIGHT
	return AnimStates.IDLE_DOWN


func _second_step(direction: Vector2) -> AnimStates:
	match direction:
		Vector2.DOWN:
			return AnimStates.SECOND_STEP_DOWN
		Vector2.UP:
			return AnimStates.SECOND_STEP_UP
		Vector2.LEFT:
			return AnimStates.SECOND_STEP_LEFT
		Vector2.RIGHT:
			return AnimStates.SECOND_STEP_RIGHT
	return AnimStates.IDLE_DOWN


func play_idle_animation(direction: Vector2) -> void:
	_play(get_idle_animation(direction))


func get_idle_animation(direction: Vector2) -> String:
	match direction:
		Vector2.DOWN:
			return Anim[AnimStates.IDLE_DOWN]
		Vector2.UP:
			return Anim[AnimStates.IDLE_UP]
		Vector2.LEFT:
			return Anim[AnimStates.IDLE_LEFT]
		Vector2.RIGHT:
			return Anim[AnimStates.IDLE_RIGHT]
	return Anim[AnimStates.IDLE_DOWN]


func _play(animation_name: String) -> void:
	if sprite == null:
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
