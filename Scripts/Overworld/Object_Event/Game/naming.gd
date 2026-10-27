extends Control
## Naming — preview OW del género + arranque vía SessionBoot → GameSession.

@onready var line: LineEdit = $Text/Print_Name
@onready var pregunta: Label = $Text/Pregunta
@onready var character_root: Node2D = $Character
@onready var mon_root: Node2D = $Mon
@onready var anim_sprite: AnimatedSprite2D = $Character/AnimatedSprite2D

const MAX_LEN: int = 7
const MALE_OW: String = "res://Graficos/Object_Event/player/male/kael/normal.png"
const FEMALE_OW: String = "res://Graficos/Object_Event/player/female/kaida/normal.png"
const GAME_SESSION_SCENE: String = "res://Escenas/Overworld/Game/game_session.tscn"

const WALK: Array[StringName] = [
	&"First_Step_Down",
	&"Idle_Down",
	&"Second_Step_Down",
	&"Idle_Down",
]
const WALK_STEP: float = 0.18

var _busy: bool = true
var _walk_time: float = 0.0
var _walk_index: int = 0


func _ready() -> void:
	if mon_root:
		mon_root.visible = false
	if character_root:
		character_root.visible = true

	_apply_gender_sprite()

	if pregunta:
		pregunta.text = "¿Tu nombre?"
	if line:
		line.max_length = MAX_LEN
		line.text = NewGameState.player_name
		line.grab_focus()
		line.caret_column = line.text.length()
		if not line.text_submitted.is_connected(_on_text_submitted):
			line.text_submitted.connect(_on_text_submitted)

	if FadeScreen:
		FadeScreen.set_clear()
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, TitleConfig.FADE_DURATION).finished
	_busy = false


func _process(delta: float) -> void:
	if _busy or anim_sprite == null or anim_sprite.sprite_frames == null:
		return
	_walk_time += delta
	if _walk_time < WALK_STEP:
		return
	_walk_time = 0.0
	_walk_index = (_walk_index + 1) % WALK.size()
	var anim_name: StringName = WALK[_walk_index]
	if anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)


func _apply_gender_sprite() -> void:
	if anim_sprite == null:
		return
	var path: String = MALE_OW if NewGameState.is_male else FEMALE_OW
	if not ResourceLoader.exists(path):
		push_warning("Naming: no hay OW en %s" % path)
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return
	anim_sprite.sprite_frames = _build_frames(texture)
	anim_sprite.play(&"Idle_Down")
	_walk_index = 1
	_walk_time = 0.0


func _build_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var cell: Vector2 = texture.get_size() / Vector2(3, 4)
	var dirs: Dictionary = {"Down": 0, "Up": 1, "Left": 2, "Right": 3}
	var steps: Dictionary = {"First_Step": 0, "Idle": 1, "Second_Step": 2}
	for dir: String in dirs:
		var y: int = dirs[dir]
		for step: String in steps:
			var x: int = steps[step]
			var anim: String = "%s_%s" % [step, dir]
			frames.add_animation(anim)
			frames.set_animation_loop(anim, false)
			frames.set_animation_speed(anim, 6.0)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(x, y) * cell, cell)
			frames.add_frame(anim, atlas)
			if step != "Idle":
				var idle_atlas := AtlasTexture.new()
				idle_atlas.atlas = texture
				idle_atlas.region = Rect2(Vector2(1, y) * cell, cell)
				frames.add_frame(anim, idle_atlas)
	return frames


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("buttonA"):
		get_viewport().set_input_as_handled()
		_confirm()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()


func _on_text_submitted(_text: String) -> void:
	_confirm()


func _confirm() -> void:
	if _busy:
		return
	_busy = true
	NewGameState.set_player_name(line.text if line else "")
	SessionBoot.start_data = NewGameState.build_start_data()
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	if FadeScreen:
		FadeScreen.set_covered()
	if not ResourceLoader.exists(GAME_SESSION_SCENE):
		push_error("Naming: falta %s" % GAME_SESSION_SCENE)
		_busy = false
		return
	get_tree().change_scene_to_file(GAME_SESSION_SCENE)


func _cancel() -> void:
	_busy = true
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	get_tree().change_scene_to_file(TitleConfig.GENDER_SCENE)
