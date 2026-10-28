extends CanvasLayer
class_name MapCloudLayer

@export var cloud_textures: Array[Texture2D] = []
@export var cloud_count: int = 6
@export var scroll_speed: Vector2 = Vector2(8.0, 0.0)
@export var cloud_modulate: Color = Color(1, 1, 1, 0.4)
@export var scale_min: float = 1.0
@export var scale_max: float = 2.0
@export var area: Rect2 = Rect2(0, 0, 480, 320)

var _enabled: bool = true
var _clouds: Array[Sprite2D] = []
var _speeds: Array[Vector2] = []


func _ready() -> void:
	# Independiente de la Camera2D del player
	follow_viewport_enabled = false
	follow_viewport_scale = false
	layer = 5
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Sacarlo de GameSession/Player y colgarlo de la raíz
	call_deferred("_detach_to_root")

	_spawn_clouds()
	visible = _enabled


func _detach_to_root() -> void:
	var root: Window = get_tree().root
	if get_parent() == root:
		return
	var keep_pos: Vector2 = Vector2.ZERO
	reparent(root)
	# CanvasLayer no usa position de mundo; los sprites van en coords de pantalla


func set_outdoor(outdoor: bool) -> void:
	_enabled = outdoor
	visible = outdoor
	if outdoor and _clouds.is_empty() and not cloud_textures.is_empty():
		_spawn_clouds()


func set_cloud_modulate(color: Color) -> void:
	cloud_modulate = color
	for spr: Sprite2D in _clouds:
		if is_instance_valid(spr):
			spr.modulate = cloud_modulate


func _spawn_clouds() -> void:
	for c: Sprite2D in _clouds:
		if is_instance_valid(c):
			c.queue_free()
	_clouds.clear()
	_speeds.clear()

	if cloud_textures.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i: int in cloud_count:
		var spr := Sprite2D.new()
		spr.texture = cloud_textures[rng.randi() % cloud_textures.size()]
		spr.centered = true
		spr.modulate = cloud_modulate
		var s: float = rng.randf_range(scale_min, scale_max)
		spr.scale = Vector2(s, s)
		spr.position = Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.position.y + area.size.y * 0.55)
		)
		add_child(spr)
		_clouds.append(spr)
		_speeds.append(scroll_speed * rng.randf_range(0.6, 1.3))


func _process(delta: float) -> void:
	if not _enabled or _clouds.is_empty():
		return

	for i: int in _clouds.size():
		var spr: Sprite2D = _clouds[i]
		if not is_instance_valid(spr):
			continue
		var vel: Vector2 = _speeds[i]
		spr.position += vel * delta

		var half_w: float = 32.0
		if spr.texture:
			half_w = spr.texture.get_width() * absf(spr.scale.x) * 0.5

		if vel.x >= 0.0 and spr.position.x - half_w > area.end.x:
			spr.position.x = area.position.x - half_w
			spr.position.y = randf_range(area.position.y, area.position.y + area.size.y * 0.55)
		elif vel.x < 0.0 and spr.position.x + half_w < area.position.x:
			spr.position.x = area.end.x + half_w
			spr.position.y = randf_range(area.position.y, area.position.y + area.size.y * 0.55)
