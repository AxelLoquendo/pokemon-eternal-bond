extends Control
## Naming con tu LineEdit y preview Character / Mon.

@onready var line: LineEdit = $Text/Print_Name
@onready var pregunta: Label = $Text/Pregunta
@onready var character_root: Node2D = $Character
@onready var mon_root: Node2D = $Mon
@onready var anim_sprite: AnimatedSprite2D = $Character/AnimatedSprite2D

const MAX_LEN: int = 7

var _busy: bool = true


func _ready() -> void:
	if character_root:
		character_root.visible = true
	if mon_root:
		mon_root.visible = false

	if pregunta:
		pregunta.text = "¿Tu nombre?" if NewGameState.is_male else "¿Tu nombre?"

	if line:
		line.max_length = MAX_LEN
		line.text = NewGameState.player_name
		line.grab_focus()
		line.caret_column = line.text.length()
		# Enter del LineEdit
		if not line.text_submitted.is_connected(_on_text_submitted):
			line.text_submitted.connect(_on_text_submitted)

	# Preview: podrías cambiar sprite frames según género si tienes tres distintos
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(&"Idle_Down"):
		anim_sprite.play(&"Idle_Down")

	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("set_clear"):
		FadeScreen.set_clear()
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, TitleConfig.FADE_DURATION)
	await tw.finished
	_busy = false


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	# Z / buttonA también confirma (además de Enter del LineEdit)
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
	var raw: String = line.text if line else ""
	NewGameState.set_player_name(raw)
	await _fade_out()
	_go_to_game()


func _cancel() -> void:
	_busy = true
	await _fade_out()
	get_tree().change_scene_to_file(TitleConfig.GENDER_SCENE)


func _fade_out() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION)
	await tw.finished
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("set_covered"):
		FadeScreen.set_covered()


func _go_to_game() -> void:
	var path: String = TitleConfig.START_MAP_SCENE
	if not ResourceLoader.exists(path):
		push_error("Naming: no existe mapa de inicio: %s" % path)
		_busy = false
		return
	# Aquí más adelante: NewGameState.build_start_data() → GameSession
	get_tree().change_scene_to_file(path)
