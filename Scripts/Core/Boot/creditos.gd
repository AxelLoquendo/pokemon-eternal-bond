extends Node2D
## Créditos / splash inicial → title_screen.

@onready var bg: Sprite2D = $BG

var _busy: bool = true
var _skip: bool = false


func _ready() -> void:
	if bg:
		bg.modulate.a = 0.0
	if typeof(FadeScreen) != TYPE_NIL and FadeScreen.has_method("set_clear"):
		FadeScreen.set_clear()
	await _run()


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed("buttonA") or event.is_action_pressed("buttonStart")
			or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if not _busy:
		_skip = true


func _run() -> void:
	_busy = true
	_skip = false
	await _tween_alpha(bg, 1.0)
	_busy = false

	var t: float = 0.0
	while t < TitleConfig.SECONDS_PER_SPLASH:
		if _skip:
			break
		await get_tree().process_frame
		t += get_process_delta_time()

	_busy = true
	await _tween_alpha(bg, 0.0)
	get_tree().change_scene_to_file(TitleConfig.TITLE_SCENE)


func _tween_alpha(node: CanvasItem, target: float) -> void:
	if node == null:
		return
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", target, TitleConfig.FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	await tw.finished
