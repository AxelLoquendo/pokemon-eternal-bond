class_name NpcController
extends Node2D

@onready var character_controller: CharacterController = $"../CharacterController"
@onready var states: CharacterStatesController = $"../CharacterStatesController"
@onready var move_route_controller: MoveRouteController = $"../MoveRouteController"

const LOOK_AROUND_DELAY: float = 0.8
const WANDER_DELAY: float = 0.8
const FOLLOW_DISTANCE: float = 32.0
const FOLLOW_DELAY: float = 0.2

var npc_data: NPCData
var look_around_timer: float = 0.0
var wander_timer: float = 0.0
var follow_timer: float = 0.0
var behavior_paused: bool = false
var patrol_started: bool = false


func set_npc_data(new_data: NPCData) -> void:
	npc_data = new_data
	patrol_started = false


func process_behavior(delta: float) -> void:
	if behavior_paused or npc_data == null:
		return
	if states != null and states.is_locked():
		return

	match npc_data.behavior:
		NPCData.Behavior.NONE:
			pass
		NPCData.Behavior.LOOK_AROUND:
			_process_look_around(delta)
		NPCData.Behavior.WANDER:
			_process_wander(delta)
		NPCData.Behavior.PATROL:
			_process_patrol()
		NPCData.Behavior.FOLLOW:
			_process_follow(delta)


func _process_look_around(delta: float) -> void:
	if look_around_timer > 0.0:
		look_around_timer -= delta
		return
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	character_controller.look_direction(directions.pick_random())
	look_around_timer = LOOK_AROUND_DELAY


func _process_wander(delta: float) -> void:
	if character_controller.moving:
		return
	if wander_timer > 0.0:
		wander_timer -= delta
		return
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	character_controller.request_move(directions.pick_random())
	wander_timer = WANDER_DELAY


func _process_patrol() -> void:
	if npc_data.move_route == null or move_route_controller == null:
		return
	if patrol_started:
		return
	patrol_started = true
	move_route_controller.start_route(npc_data.move_route)


func _process_follow(delta: float) -> void:
	if character_controller.moving:
		return
	if follow_timer > 0.0:
		follow_timer -= delta
		return

	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return

	var player_cc: CharacterController = player.get_node_or_null(
		"Controller/CharacterController"
	) as CharacterController
	if player_cc == null:
		return

	var offset: Vector2 = (
		player_cc.get_character_position() - character_controller.get_character_position()
	)
	if offset.length() <= FOLLOW_DISTANCE:
		return

	var direction: Vector2
	if absf(offset.x) > absf(offset.y):
		direction = Vector2.RIGHT if offset.x > 0.0 else Vector2.LEFT
	else:
		direction = Vector2.DOWN if offset.y > 0.0 else Vector2.UP

	character_controller.request_move(direction)
	follow_timer = FOLLOW_DELAY


func pause_behavior(paused: bool = true) -> void:
	behavior_paused = paused
	if paused:
		look_around_timer = 0.0
		wander_timer = 0.0
		follow_timer = 0.0
		if move_route_controller:
			move_route_controller.pause_route()


func resume_behavior() -> void:
	behavior_paused = false
	if npc_data == null:
		return
	if npc_data.behavior != NPCData.Behavior.PATROL:
		return
	if move_route_controller and move_route_controller.has_route():
		patrol_started = true
		move_route_controller.resume_route()
	else:
		patrol_started = false
