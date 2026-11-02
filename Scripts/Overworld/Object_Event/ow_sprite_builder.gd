class_name OwSpriteBuilder
extends Object
## Construye SpriteFrames OW. Seguro en @tool (no depende del autoload).

const IDLE_DIRS: Array[String] = ["Down", "Up", "Left", "Right"]
const IDLE_ANIM_SPEED: float = 3.5
const WALK_ANIM_SPEED: float = 6.0


static func idle_anim_path(ow_path: String, direction: String) -> String:
	if ow_path.is_empty():
		return ""
	return ow_path.get_base_dir().path_join("idle_%s_anim.png" % direction.to_lower())


static func build_ow_sprite_frames(
	frames: SpriteFrames,
	classic: Texture2D,
	ow_path: String
) -> Vector2:
	var frame_size: Vector2 = classic.get_size() / Vector2(3, 4)
	var dir_rows: Dictionary = {"Down": 0, "Up": 1, "Left": 2, "Right": 3}

	for direction: String in IDLE_DIRS:
		var y: int = dir_rows[direction]
		for step: String in ["First_Step", "Second_Step"]:
			var x: int = 0 if step == "First_Step" else 2
			var anim_name: String = "%s_%s" % [step, direction]
			_ensure_anim(frames, anim_name, false, WALK_ANIM_SPEED)
			_clear_frames(frames, anim_name)
			_add_cell(frames, anim_name, classic, Vector2(x, y), frame_size)
			_add_cell(frames, anim_name, classic, Vector2(1, y), frame_size)

	for direction: String in IDLE_DIRS:
		var anim_name: String = "Idle_%s" % direction
		var strip_path: String = idle_anim_path(ow_path, direction)
		var used_strip := false

		if strip_path != "" and ResourceLoader.exists(strip_path):
			var strip: Texture2D = load(strip_path) as Texture2D
			if strip != null:
				used_strip = _build_idle_strip(frames, anim_name, strip)

		if not used_strip:
			_ensure_anim(frames, anim_name, false, WALK_ANIM_SPEED)
			_clear_frames(frames, anim_name)
			_add_cell(frames, anim_name, classic, Vector2(1, dir_rows[direction]), frame_size)

	return frame_size


static func _build_idle_strip(frames: SpriteFrames, anim_name: String, strip: Texture2D) -> bool:
	var size: Vector2 = strip.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return false

	var horizontal: bool = size.x >= size.y
	var frame_count: int
	var frame_w: float
	var frame_h: float

	if horizontal:
		frame_h = size.y
		frame_count = maxi(1, int(round(size.x / frame_h)))
		frame_w = size.x / float(frame_count)
	else:
		frame_w = size.x
		frame_count = maxi(1, int(round(size.y / frame_w)))
		frame_h = size.y / float(frame_count)

	_ensure_anim(frames, anim_name, frame_count > 1, IDLE_ANIM_SPEED)
	_clear_frames(frames, anim_name)
	for i: int in frame_count:
		var origin: Vector2 = (
			Vector2(float(i) * frame_w, 0.0) if horizontal
			else Vector2(0.0, float(i) * frame_h)
		)
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(origin, Vector2(frame_w, frame_h))
		frames.add_frame(anim_name, atlas)
	return true


static func _ensure_anim(frames: SpriteFrames, anim_name: String, loop: bool, speed: float) -> void:
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)


static func _clear_frames(frames: SpriteFrames, anim_name: String) -> void:
	while frames.get_frame_count(anim_name) > 0:
		frames.remove_frame(anim_name, 0)


static func _add_cell(
	frames: SpriteFrames,
	anim_name: String,
	atlas_tex: Texture2D,
	cell: Vector2,
	frame_size: Vector2
) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = atlas_tex
	atlas.region = Rect2(cell * frame_size, frame_size)
	frames.add_frame(anim_name, atlas)
