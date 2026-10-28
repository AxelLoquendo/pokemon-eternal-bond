@tool
class_name WorldMap
extends Node2D
## Contenedor del mapa regional. Datos para Town Map / cursor.

@export var region_id: MapSection.RegionID = MapSection.RegionID.VALTHERION
@export var map_texture: Texture2D:
	set(value):
		map_texture = value
		_apply_bg()

@onready var background: Sprite2D = get_node_or_null("Background") as Sprite2D
@onready var regions_root: Node2D = get_node_or_null("Regions") as Node2D
@onready var player_pin: Sprite2D = get_node_or_null("PlayerPin") as Sprite2D


func _ready() -> void:
	_apply_bg()


func _apply_bg() -> void:
	if background and map_texture:
		background.texture = map_texture
		background.centered = false
		background.position = Vector2.ZERO


## Todas las regiones hijas (directas o bajo Regions/).
func get_regions() -> Array[WorldMapRegion]:
	var out: Array[WorldMapRegion] = []
	var root: Node = regions_root if regions_root else self
	_collect_regions(root, out)
	return out


func _collect_regions(node: Node, out: Array[WorldMapRegion]) -> void:
	if node is WorldMapRegion:
		out.append(node as WorldMapRegion)
	for c: Node in node.get_children():
		_collect_regions(c, out)


func find_region_at(local_pos: Vector2) -> WorldMapRegion:
	var list: Array[WorldMapRegion] = get_regions()
	# Última en el árbol gana (como capas)
	for i: int in range(list.size() - 1, -1, -1):
		if list[i].show_on_town_map and list[i].contains_point(local_pos):
			return list[i]
	return null


func find_region_by_map_id(id: MapSection.MapID) -> WorldMapRegion:
	for r: WorldMapRegion in get_regions():
		if r.map_id == id:
			return r
	return null


## Centro del rect de una región (para el pin del player).
func pin_position_for_map(id: MapSection.MapID) -> Vector2:
	var r: WorldMapRegion = find_region_by_map_id(id)
	if r == null:
		return Vector2.ZERO
	var rect: Rect2 = r.get_rect()
	return rect.position + rect.size * 0.5


func place_player_pin(map_id: MapSection.MapID) -> void:
	if player_pin == null:
		return
	player_pin.position = pin_position_for_map(map_id)
	player_pin.visible = map_id != MapSection.MapID.NONE
