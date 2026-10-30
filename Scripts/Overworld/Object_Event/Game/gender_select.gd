extends Node2D
## GenderSelect — slide + resalte + walk solo en el elegido

@onready var anim_m: AnimationPlayer = $Animaciones_M
@onready var anim_f: AnimationPlayer = $Animaciones_F
@onready var male_root: Sprite2D = $Male
@onready var female_root: Sprite2D = $Female
@onready var male_ow: Sprite2D = $Male/Overworld
@onready var female_ow: Sprite2D = $Female/Overworld

var _male: bool = true
var _busy: bool = true

## Walk cycle del sheet 3×4 (fila Down = 0): First → Idle → Second → Idle
const WALK_FRAMES: Array[int] = [0, 1, 2, 1]
const WALK_STEP: float = 0.18
const IDLE_FRAME: int = 1

const COL_ON := Color(1, 1, 1, 1)
const COL_OFF := Color(0.55, 0.55, 0.55, 1)

var _walk_time: float = 0.0
var _walk_index: int = 0


func _ready() -> void:
	NewGameState.reset()
	_snap_to_male()
	_refresh_highlight()
	_reset_ow_idle()
	if FadeScreen:
		FadeScreen.set_clear()
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, TitleConfig.FADE_DURATION).finished
	_busy = false


func _process(delta: float) -> void:
	if _busy:
		return
	_walk_time += delta
	if _walk_time < WALK_STEP:
		return
	_walk_time = 0.0
	_walk_index = (_walk_index + 1) % WALK_FRAMES.size()
	var frame: int = WALK_FRAMES[_walk_index]
	if _male:
		if male_ow:
			male_ow.frame = frame
		if female_ow:
			female_ow.frame = IDLE_FRAME
	else:
		if female_ow:
			female_ow.frame = frame
		if male_ow:
			male_ow.frame = IDLE_FRAME


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_reproducir_sound()
		_select(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_reproducir_sound()
		_select(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA") or event.is_action_pressed("ui_accept"):
		_reproducir_sound()
		get_viewport().set_input_as_handled()
		_confirm()
	elif event.is_action_pressed("buttonB") or event.is_action_pressed("ui_cancel"):
		_reproducir_sound()
		get_viewport().set_input_as_handled()
		_back()

func _reproducir_sound() -> void:
	MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)

func _select(male: bool) -> void:
	if _male == male:
		return
	_male = male
	_walk_index = 0
	_walk_time = 0.0
	if _male:
		_play(anim_m, &"Seleccionado_M")
		_play(anim_f, &"No_Seleccionado_F")
	else:
		_play(anim_f, &"Seleccionado_F")
		_play(anim_m, &"No_Seleccionado_M")
	_refresh_highlight()
	_reset_ow_idle()


func _snap_to_male() -> void:
	_male = true
	_play(anim_m, &"Seleccionado_M")
	if anim_m:
		anim_m.seek(anim_m.current_animation_length, true)
	_play(anim_f, &"No_Seleccionado_F")
	if anim_f:
		anim_f.seek(anim_f.current_animation_length, true)


func _refresh_highlight() -> void:
	if male_root:
		male_root.modulate = COL_ON if _male else COL_OFF
	if female_root:
		female_root.modulate = COL_ON if not _male else COL_OFF


func _reset_ow_idle() -> void:
	if male_ow:
		male_ow.frame = IDLE_FRAME
	if female_ow:
		female_ow.frame = IDLE_FRAME


func _play(player: AnimationPlayer, anim_name: StringName) -> void:
	if player and player.has_animation(anim_name):
		player.play(anim_name)


func _confirm() -> void:
	_busy = true
	NewGameState.apply_gender(_male)
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	get_tree().change_scene_to_file(TitleConfig.NAMING_SCENE)


func _back() -> void:
	_busy = true
	await create_tween().tween_property(self, "modulate:a", 0.0, TitleConfig.FADE_DURATION).finished
	get_tree().change_scene_to_file(TitleConfig.MAIN_MENU_SCENE)
