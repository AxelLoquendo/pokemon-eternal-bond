@tool
class_name NPC
extends Node2D

const TILE_SIZE: float = 16.0

@export var character: NPCData:
	set(value):
		character = value
		_update_visuals()
		if not Engine.is_editor_hint() and is_node_ready() and npc_controller:
			npc_controller.set_npc_data(character)

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var controller: CharacterController = $Controller/CharacterController
@onready var states: CharacterStatesController = $Controller/CharacterStatesController
@onready var npc_controller: NpcController = $Controller/NpcController
@onready var move_route_controller: MoveRouteController = $Controller/MoveRouteController

var _last_ow: ObjectEvent.owID = ObjectEvent.owID.OBJ_EVENT_NONE
var _last_shadow: ObjectEvent.shadowID = ObjectEvent.shadowID.NONE
var _last_shadow_pos: Vector2 = Vector2.INF
var _script_locked: bool = false
var _script_running: bool = false


func _ready() -> void:
	add_to_group(&"npc")
	_update_visuals()
	if Engine.is_editor_hint():
		return
	if move_route_controller and controller:
		move_route_controller.setup(controller)
	if npc_controller and character:
		npc_controller.set_npc_data(character)
	if character and controller and character.walk > 0:
		controller.set_move_speed(float(character.walk) * TILE_SIZE)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if character == null:
		return
	if (
		character.ow_sprite != _last_ow
		or character.shadow_sprite != _last_shadow
		or character.shadow_position != _last_shadow_pos
	):
		_update_visuals()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if states == null or controller == null:
		return

	if not states.is_locked() and npc_controller:
		npc_controller.process_behavior(delta)

	controller.process_movement(delta)
	states.process_state(delta)


func can_interact() -> bool:
	if _script_locked or _script_running:
		return false
	if character == null:
		return false
	return not character.script_file.is_empty()

func interact(player: Node2D) -> void:
	if not can_interact():
		return
	_script_running = true
	_script_locked = true
	_freeze_for_interaction(player)
	_start_runner(player)

func _start_runner(player: Node2D) -> void:
	var file_cmd := ScriptCmdTextFile.new()
	file_cmd.script_file_path = character.script_file
	var runner := ScriptRunner.new()
	runner.name = "ScriptRunner"
	add_child(runner)
	runner.script_finished.connect(_on_script_finished.bind(runner), CONNECT_ONE_SHOT)
	# map = padre del NPC (EventObject / Map)
	var map_node: Node = get_parent()
	while map_node and not (map_node is Map):
		map_node = map_node.get_parent()
	runner.start_script([file_cmd], self, player, map_node)

func _on_script_finished(runner: ScriptRunner) -> void:
	_script_running = false
	_end_interaction()
	if is_instance_valid(runner):
		runner.queue_free()

func _freeze_for_interaction(player: Node2D) -> void:
	_script_locked = true
	if states:
		states.change_state(CharacterStatesController.State.LOCKED)
	if npc_controller:
		npc_controller.pause_behavior(true)
	var reached: bool = false
	if controller:
		reached = controller.halt_for_interaction()
	if move_route_controller:
		if reached:
			move_route_controller.complete_current_command()
		move_route_controller.pause_route()
	face_towards(player.global_position)


func _end_interaction() -> void:
	_script_locked = false
	if states and states.is_locked():
		states.change_state(CharacterStatesController.State.IDLE)
	if npc_controller:
		npc_controller.pause_behavior(false)
		npc_controller.resume_behavior()


func face_towards(world_pos: Vector2) -> void:
	if controller == null:
		return
	var delta: Vector2 = world_pos - global_position
	var dir: Vector2
	if absf(delta.x) > absf(delta.y):
		dir = Vector2.RIGHT if delta.x > 0.0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if delta.y > 0.0 else Vector2.UP
	controller.look_direction(dir)


func get_tile_position() -> Vector2i:
	return Vector2i(
		int(round(global_position.x / TILE_SIZE)),
		int(round(global_position.y / TILE_SIZE))
	)


func _update_visuals() -> void:
	if character == null or not is_node_ready():
		return

	var shadow_path: String = ObjectEvent.shadowSprite.get(character.shadow_sprite, "")
	if shadow_sprite:
		if shadow_path != "":
			shadow_sprite.texture = load(shadow_path) as Texture2D
		else:
			shadow_sprite.texture = null
		shadow_sprite.position = character.shadow_position
		if controller:
			controller.set_shadow_base_position(shadow_sprite.position)

	var ow_path: String = ObjectEvent.owSprite.get(character.ow_sprite, "")
	if ow_path != "" and animated_sprite:
		var texture: Texture2D = load(ow_path) as Texture2D
		if texture:
			_apply_ow_texture(texture)

	_last_ow = character.ow_sprite
	_last_shadow = character.shadow_sprite
	_last_shadow_pos = character.shadow_position


func _apply_ow_texture(texture: Texture2D) -> void:
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()
	elif not animated_sprite.sprite_frames.resource_local_to_scene:
		animated_sprite.sprite_frames = animated_sprite.sprite_frames.duplicate()

	var frame_size: Vector2 = texture.get_size() / Vector2(3, 4)
	var directions: Dictionary = {"Down": 0, "Up": 1, "Left": 2, "Right": 3}
	var steps: Dictionary = {"First_Step": 0, "Idle": 1, "Second_Step": 2}

	for direction: String in directions:
		var y: int = directions[direction]
		for step: String in steps:
			var x: int = steps[step]
			var animation_name: String = step + "_" + direction
			if not animated_sprite.sprite_frames.has_animation(animation_name):
				animated_sprite.sprite_frames.add_animation(animation_name)
				animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
				animated_sprite.sprite_frames.set_animation_speed(animation_name, 6.0)

			while animated_sprite.sprite_frames.get_frame_count(animation_name) > 0:
				animated_sprite.sprite_frames.remove_frame(animation_name, 0)

			var atlas_0 := AtlasTexture.new()
			atlas_0.atlas = texture
			atlas_0.region = Rect2(Vector2(x, y) * frame_size, frame_size)
			animated_sprite.sprite_frames.add_frame(animation_name, atlas_0)

			if step != "Idle":
				var atlas_1 := AtlasTexture.new()
				atlas_1.atlas = texture
				atlas_1.region = Rect2(Vector2(1, y) * frame_size, frame_size)
				animated_sprite.sprite_frames.add_frame(animation_name, atlas_1)

	animated_sprite.centered = true
	animated_sprite.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE - frame_size.y * 0.5)
	if controller:
		controller.set_sprite_base_position(animated_sprite.position)
	if animated_sprite.sprite_frames.has_animation("Idle_Down"):
		animated_sprite.animation = &"Idle_Down"
		animated_sprite.frame = 0
