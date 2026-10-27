extends CanvasLayer

const APPEAR: float = 0.35
const LINGER: float = 1.6

var _panel: PanelContainer
var _label: Label
var _last: String = ""
var _tween: Tween


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(8, -48)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	add_child(_panel)
	visible = false


func try_show_for_map(mapa: Map) -> void:
	if mapa == null or mapa.attributes == null:
		return
	if not mapa.attributes.show_location_name:
		return
	var nombre: String = mapa.attributes.map_name.strip_edges()
	if nombre.is_empty() or nombre == _last:
		return
	_last = nombre
	_label.text = nombre
	visible = true
	_panel.position.y = -48.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_panel, "position:y", 8.0, APPEAR)
	_tween.tween_interval(LINGER)
	_tween.tween_property(_panel, "position:y", -48.0, APPEAR)
	_tween.tween_callback(func() -> void: visible = false)
