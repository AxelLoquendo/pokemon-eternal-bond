@tool
extends Label
## Comprime horizontalmente el texto si supera max_width.
## Guarda reentrada: cambiar scale NO debe reentrar en bucle (crash).

@export var max_width: float = 120.0:
	set(value):
		max_width = value
		_update_compression()

@export_range(0.1, 1.0, 0.05) var min_scale_x: float = 0.5:
	set(value):
		min_scale_x = value
		_update_compression()

var _updating: bool = false


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_OFF
	if not item_rect_changed.is_connected(_on_rect_changed):
		item_rect_changed.connect(_on_rect_changed)
	_update_compression()


func _on_rect_changed() -> void:
	_update_compression()


func set_compressed_text(new_text: String) -> void:
	text = new_text
	_update_compression()


func _update_compression() -> void:
	if _updating:
		return
	_updating = true
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	# LabelSettings del summary tiene prioridad sobre theme
	if label_settings != null:
		if label_settings.font != null:
			font = label_settings.font
		if label_settings.font_size > 0:
			font_size = label_settings.font_size
	if font == null:
		_updating = false
		return
	var text_width: float = font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	var next_scale: float = 1.0
	if text_width > max_width and text_width > 0.0:
		next_scale = clampf(max_width / text_width, min_scale_x, 1.0)
	# Solo asignar si cambia (menos señales basura)
	if not is_equal_approx(scale.x, next_scale):
		scale.x = next_scale
	_updating = false
