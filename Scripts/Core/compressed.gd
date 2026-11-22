@tool
extends Label

## Ancho máximo en píxeles permitido antes de empezar a comprimir
@export var max_width: float = 120.0:
	set(value):
		max_width = value
		_update_compression()

## Límite mínimo de compresión (ej. 0.5 = máximo 50% de aplastamiento)
@export_range(0.1, 1.0, 0.05) var min_scale_x: float = 0.5:
	set(value):
		min_scale_x = value
		_update_compression()

func _ready() -> void:
	# Evita que el contenedor padre deforme el tamaño automáticamente
	autowrap_mode = TextServer.AUTOWRAP_OFF
	item_rect_changed.connect(_update_compression)
	_update_compression()

func set_compressed_text(new_text: String) -> void:
	text = new_text
	_update_compression()

func _update_compression() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	if not font:
		return
	
	# Mide el ancho exacto del texto sin escalar
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	if text_width > max_width and text_width > 0.0:
		scale.x = clampf(max_width / text_width, min_scale_x, 1.0)
	else:
		scale.x = 1.0
