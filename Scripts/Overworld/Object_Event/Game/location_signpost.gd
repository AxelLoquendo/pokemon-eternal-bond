extends CanvasLayer
## Cartel de ubicación al entrar a un mapa.
## BW usa Escenas/UI/Map_Popup/map_popup.tscn; el resto, panel simple.

const APPEAR: float = 0.35
const LINGER: float = 1.6
const BW_POPUP_SCENE: String = "res://Escenas/UI/Map_Popup/map_popup.tscn"

var _panel: PanelContainer
var _label: Label
var _last: String = ""
var _tween: Tween

var _bw_popup: Node2D = null
var _bw_anim: AnimationPlayer = null
var _bw_name: Label = null
var _bw_time: Label = null
var _bw_busy: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_simple_panel()
	_ensure_bw_popup()
	visible = false


func _build_simple_panel() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(8, -48)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false


func _ensure_bw_popup() -> void:
	if _bw_popup != null:
		return
	if not ResourceLoader.exists(BW_POPUP_SCENE):
		push_warning("LocationSignpost: no existe %s" % BW_POPUP_SCENE)
		return
	_bw_popup = (load(BW_POPUP_SCENE) as PackedScene).instantiate() as Node2D
	_bw_popup.name = "MapPopupBW"
	add_child(_bw_popup)
	_bw_anim = _bw_popup.get_node_or_null("Animacion_popup") as AnimationPlayer
	_bw_name = _bw_popup.get_node_or_null("Superior_BG/Map_Name") as Label
	_bw_time = _bw_popup.get_node_or_null("Inferior_BG/Time") as Label
	_bw_popup.visible = false


func try_show_for_map(mapa: Map) -> void:
	if mapa == null or mapa.attributes == null:
		return
	if not mapa.attributes.show_location_name:
		return

	var nombre: String = mapa.attributes.map_name.strip_edges()
	if nombre.is_empty() or nombre == _last:
		return
	_last = nombre

	var style: MapAttributes.LocationStyle = mapa.attributes.location_style
	if style == MapAttributes.LocationStyle.BW:
		_show_bw(nombre)
	else:
		_show_simple(nombre)


func _show_simple(nombre: String) -> void:
	if _bw_popup:
		_bw_popup.visible = false
	_panel.visible = true
	visible = true
	_label.text = nombre
	_panel.position.y = -48.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_panel, "position:y", 8.0, APPEAR)
	_tween.tween_interval(LINGER)
	_tween.tween_property(_panel, "position:y", -48.0, APPEAR)
	_tween.tween_callback(func() -> void:
		_panel.visible = false
		visible = false
	)


func _show_bw(nombre: String) -> void:
	_ensure_bw_popup()
	if _bw_popup == null or _bw_anim == null:
		_show_simple(nombre)
		return

	if _panel:
		_panel.visible = false
	if _bw_busy and _bw_anim.is_playing():
		_bw_anim.stop()

	_bw_busy = true
	visible = true
	_bw_popup.visible = true

	if _bw_name:
		_bw_name.text = nombre
	if _bw_time:
		_bw_time.text = _format_clock()

	# Entrada → espera → Salida
	_bw_anim.play("Entrada")
	await _bw_anim.animation_finished
	await get_tree().create_timer(LINGER).timeout
	if not is_instance_valid(_bw_anim):
		return
	_bw_anim.play("Salida")
	await _bw_anim.animation_finished

	_bw_popup.visible = false
	visible = false
	_bw_busy = false


func _format_clock() -> String:
	var h: int = 12
	var m: int = 0
	if DayNightManager:
		h = DayNightManager.hour
		m = DayNightManager.minute
	else:
		var now: Dictionary = Time.get_datetime_dict_from_system()
		h = int(now.get("hour", 12))
		m = int(now.get("minute", 0))

	var suffix: String = "AM"
	var h12: int = h
	if h >= 12:
		suffix = "PM"
		if h > 12:
			h12 = h - 12
	if h12 == 0:
		h12 = 12
	return "%02d:%02d %s" % [h12, m, suffix]
