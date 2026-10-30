@tool
class_name Player
extends Node2D

const TILE_SIZE: float = 16.0

@export var character: PlayerData:
	set(value):
		character = value
		_update_visuals()

@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var controller: CharacterController = $Controller/CharacterController
@onready var states: CharacterStatesController = $Controller/CharacterStatesController

var _last_ow: ObjectEvent.owID = ObjectEvent.owID.OBJ_EVENT_NONE
var _last_shadow: ObjectEvent.shadowID = ObjectEvent.shadowID.NONE
var _last_shadow_pos: Vector2 = Vector2.INF
var _script_locked: bool = false


func _ready() -> void:
	_update_visuals()
	if Engine.is_editor_hint():
		return
	add_to_group(&"Player")
	if MessageService != null:
		if not MessageService.message_started.is_connected(_on_message_started):
			MessageService.message_started.connect(_on_message_started)
		if not MessageService.message_finished.is_connected(_on_message_finished):
			MessageService.message_finished.connect(_on_message_finished)
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
	if controller == null or states == null:
		return
	if MessageService != null and MessageService.is_active():
		controller.set_direction(Vector2.ZERO)
		return

	var dir := Vector2.ZERO
	if not _script_locked and not states.is_locked():
		if Input.is_action_pressed("Left") or Input.is_action_pressed("ui_left"):
			dir = Vector2.LEFT
		elif Input.is_action_pressed("Right") or Input.is_action_pressed("ui_right"):
			dir = Vector2.RIGHT
		elif Input.is_action_pressed("Up") or Input.is_action_pressed("ui_up"):
			dir = Vector2.UP
		elif Input.is_action_pressed("Down") or Input.is_action_pressed("ui_down"):
			dir = Vector2.DOWN

	controller.set_direction(dir)
	controller.process_movement(delta)
	if states.has_method("process_state"):
		states.process_state(delta)


func _on_message_started() -> void:
	if controller != null:
		controller.halt_for_interaction()
		controller.set_direction(Vector2.ZERO)


func _on_message_finished() -> void:
	if controller != null:
		controller.set_direction(Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _script_locked:
		return
	if not event.is_action_pressed("buttonA"):
		return
	if controller == null or controller.moving:
		return

	var factory: Node = get_tree().get_first_node_in_group(&"map_factory")
	if factory is MapFactory and MapEventResolver.try_interact(self, factory as MapFactory):
		get_viewport().set_input_as_handled()
		return

	var npc: Node2D = _find_facing_npc()
	if npc != null and npc.has_method("interact"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		npc.call("interact", self)
		get_viewport().set_input_as_handled()


func set_script_locked(locked: bool) -> void:
	_script_locked = locked
	if locked and controller:
		controller.halt_for_interaction()
		controller.set_direction(Vector2.ZERO)


func _find_facing_npc() -> Node2D:
	var facing: Vector2 = controller.last_direction
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN
	var front: Vector2 = controller.get_character_position() + facing * TILE_SIZE
	var tile := Vector2i(int(round(front.x / TILE_SIZE)), int(round(front.y / TILE_SIZE)))
	for node: Node in get_tree().get_nodes_in_group(&"npc"):
		if not node is Node2D:
			continue
		var n: Node2D = node as Node2D
		var nt := Vector2i(int(round(n.global_position.x / TILE_SIZE)), int(round(n.global_position.y / TILE_SIZE)))
		if nt == tile:
			return n
	return null


func _update_visuals() -> void:
	if character == null:
		return
	if not is_node_ready():
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
