@tool
class_name WorldMap
extends Node2D
## Cursor libre en el mapa; al pasar por un WorldMapRegion actualiza Map_Name.
## Idle del cursor: 3 frames del Sprite2D (vframes = 3).

@export var region_id: MapSection.RegionID = MapSection.RegionID.VALTHERION
@export var cursor_speed: float = 180.0
## Límites del cursor en coords de esta escena (ventana de juego).
@export var cursor_bounds: Rect2 = Rect2(0, 0, 480, 320)
@export var idle_frame_time: float = 0.2
@export var test_when_main_scene: bool = true

@onready var background: Sprite2D = $Bg
@onready var player_pin: Sprite2D = $PlayerPin
@onready var cursor: Sprite2D = $Cursor
@onready var regions_root: Node2D = $MapPoints
@onready var map_name_label: Label = $Map_Window/Map_Name
@onready var region_name_label: Label = $Region_Window/Region_Name

var _move: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0
var _idle_frame: int = 0
var _was_moving: bool = false
var _last_region: WorldMapRegion = null
var _test_mode: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_test_mode = test_when_main_scene and get_tree().current_scene == self

	if region_name_label:
		region_name_label.text = _region_title()

	if cursor:
		cursor.frame = 0
		# Asegura que no se salga al arrancar
		cursor.position = _clamp_pos(cursor.position)

	_refresh_region_under_cursor()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if cursor == null:
		return

	# Solo input de prueba / cuando esta escena está activa
	if _test_mode or get_tree().current_scene == self:
		_read_move_input()

	var moving: bool = _move != Vector2.ZERO
	if moving:
		cursor.position = _clamp_pos(cursor.position + _move * cursor_speed * delta)
		_was_moving = true
		_idle_timer = 0.0
		_idle_frame = 0
		cursor.frame = 0
		_refresh_region_under_cursor()
	else:
		_update_idle_anim(delta)


func _read_move_input() -> void:
	_move = Vector2.ZERO
	if Input.is_action_pressed("Left") or Input.is_action_pressed("ui_left"):
		_move.x -= 1.0
	if Input.is_action_pressed("Right") or Input.is_action_pressed("ui_right"):
		_move.x += 1.0
	if Input.is_action_pressed("Up") or Input.is_action_pressed("ui_up"):
		_move.y -= 1.0
	if Input.is_action_pressed("Down") or Input.is_action_pressed("ui_down"):
		_move.y += 1.0
	if _move != Vector2.ZERO:
		_move = _move.normalized()


func _clamp_pos(pos: Vector2) -> Vector2:
	var r: Rect2 = cursor_bounds
	return Vector2(
		clampf(pos.x, r.position.x, r.position.x + r.size.x),
		clampf(pos.y, r.position.y, r.position.y + r.size.y)
	)


func _update_idle_anim(delta: float) -> void:
	if cursor == null:
		return
	var frames: int = maxi(1, cursor.vframes * cursor.hframes)
	if frames <= 1:
		return
	_idle_timer += delta
	if _idle_timer >= idle_frame_time:
		_idle_timer = 0.0
		_idle_frame = (_idle_frame + 1) % mini(3, frames)
		cursor.frame = _idle_frame


func _refresh_region_under_cursor() -> void:
	if cursor == null:
		return
	# Cursor y MapPoints son hijos de WorldMap → misma base si MapPoints está en (0,0)
	var local: Vector2 = cursor.position
	if regions_root:
		local = regions_root.to_local(cursor.global_position)

	var region: WorldMapRegion = find_region_at(local)
	if region == _last_region:
		return
	_last_region = region

	if map_name_label == null:
		return
	if region != null:
		map_name_label.text = region.resolved_name()
	else:
		map_name_label.text = ""  # o "---"


func _region_title() -> String:
	match region_id:
		MapSection.RegionID.VALTHERION:
			return "Valtherion"
		_:
			return str(region_id)


# ----- API regiones -----

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
	for i: int in range(list.size() - 1, -1, -1):
		var r: WorldMapRegion = list[i]
		if r.show_on_town_map and r.contains_point(local_pos):
			return r
	return null


func find_region_by_map_id(id: MapSection.MapID) -> WorldMapRegion:
	for r: WorldMapRegion in get_regions():
		if r.map_id == id:
			return r
	return null


func pin_position_for_map(id: MapSection.MapID) -> Vector2:
	var r: WorldMapRegion = find_region_by_map_id(id)
	if r == null or regions_root == null:
		return Vector2.ZERO
	return regions_root.to_global(r.position + Vector2(r.region_size) * 0.5) - global_position


func place_player_pin(map_id: MapSection.MapID) -> void:
	if player_pin == null:
		return
	player_pin.position = pin_position_for_map(map_id)
	player_pin.visible = map_id != MapSection.MapID.NONE
