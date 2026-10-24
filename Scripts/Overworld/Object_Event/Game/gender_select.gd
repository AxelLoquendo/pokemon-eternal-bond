extends Node2D
## GenderSelect — Kael (der) / Kaida (izq)

@onready var anim: AnimationPlayer = $Animaciones

var _male: bool = true
var _busy: bool = true


func _ready() -> void:
	NewGameState.reset()
	_apply_visual(false)
	if FadeScreen:
		FadeScreen.set_clear()
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, TitleConfig.FADE_DURATION).finished
	_busy = false


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return

	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_set_gender(false)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_set_gender(true)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm()

	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


func _set_gender(male: bool) -> void:
	if _male == male:
		return
	_male = male
	_apply_visual(true)


func _apply_visual(animated: bool) -> void:
	if anim == null:
		return

	# Una sola animación por estado (no apilar dos plays)
	var name: StringName = &"Seleccionado_M" if _male else &"Seleccionado_F"
	if not anim.has_animation(name):
		return

	if animated:
		anim.play(name)
	else:
		anim.play(name)
		anim.seek(anim.current_animation_length, true)  # frame final al entrar


func _confirm() -> void:
	_busy = true
	NewGameState.apply_gender(_male)
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	get_tree().change_scene_to_file(TitleConfig.NAMING_SCENE)


func _back() -> void:
	_busy = true
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	get_tree().change_scene_to_file(TitleConfig.MAIN_MENU_SCENE)
