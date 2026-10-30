extends Node2D
## Title screen: espera A/Start → main menu.

@onready var bg: Sprite2D = $BG

var _busy: bool = true
var _ready_for_input: bool = false


func _ready() -> void:
	if bg:
		bg.modulate.a = 0.0
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("set_clear"):
		FadeScreen.set_clear()
	await _open()


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input or _busy:
		return
	if not (event.is_action_pressed("buttonA") or event.is_action_pressed("buttonStart")
			or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	_accept()


func _open() -> void:
	_busy = true
	await _tween_alpha(bg, 1.0)
	# BGM título si tienes el ID en SfxGame; si no, comenta la línea:
	MusicManager.reproducir_mapa(SFXGame.MapMusicID.BGM_TITLE)
	_busy = false
	_ready_for_input = true


func _accept() -> void:
	_busy = true
	_ready_for_input = false
	if typeof(MusicManager) != TYPE_NIL and MusicManager.has_method("reproducir_se"):
		MusicManager.reproducir_se(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
		pass
	await get_tree().create_timer(0.25).timeout
	await _tween_alpha(bg, 0.0)
	if typeof(MusicManager) != TYPE_NIL and MusicManager.has_method("detener"):
		MusicManager.detener()
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("set_covered"):
		FadeScreen.set_covered()
	get_tree().change_scene_to_file(TitleConfig.MAIN_MENU_SCENE)


func _tween_alpha(node: CanvasItem, target: float) -> void:
	if node == null:
		return
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", target, TitleConfig.FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	await tw.finished
