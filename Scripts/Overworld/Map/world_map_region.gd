@tool
class_name WorldMapRegion
extends Marker2D
## Zona del world map / town map.
## Posición = esquina superior-izquierda del rect (en px del mapa).
## Ancho/alto en píxeles de la textura del world map.

@export var map_id: MapSection.MapID = MapSection.MapID.NONE
@export var display_name: String = ""
## Tamaño del área en el dibujo del mapa (px).
@export var region_size: Vector2i = Vector2i(16, 16):
	set(value):
		region_size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		queue_redraw()

@export_group("Town Map / Fly (futuro)")
@export var show_on_town_map: bool = true
@export var can_fly: bool = false
@export var fly_arrival_tile: Vector2i = Vector2i.ZERO

@export_group("Editor")
@export var show_debug: bool = true
@export var debug_color: Color = Color(0.2, 0.8, 1.0, 0.35)


func _ready() -> void:
	add_to_group(&"world_map_regions")
	z_index = 50
	if Engine.is_editor_hint():
		queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func get_rect() -> Rect2:
	return Rect2(position, Vector2(region_size))


func contains_point(local_point: Vector2) -> bool:
	return get_rect().has_point(local_point)


func resolved_name() -> String:
	if not display_name.strip_edges().is_empty():
		return display_name
	return _enum_name(map_id)


func _enum_name(id: MapSection.MapID) -> String:
	match id:
		MapSection.MapID.MAPSEC_PRADO_NATAL:
			return "Prado Natal"
		MapSection.MapID.MAPSEC_PUEBLO_ALBA:
			return "Pueblo Alba"
		_:
			return "???"


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_debug:
		return
	var r := Rect2(Vector2.ZERO, Vector2(region_size))
	draw_rect(r, debug_color, true)
	draw_rect(r, debug_color.darkened(0.3), false, 1.0)
	# Etiqueta simple
	draw_string(
		ThemeDB.fallback_font,
		Vector2(2, 12),
		resolved_name(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color.WHITE
	)
