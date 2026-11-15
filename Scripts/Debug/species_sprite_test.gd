extends Control
## Escena de debug (480×320): front / back / shiny / icon por especie.
##
## Controles:
##   ← →          especie ±1
##   ↑ ↓          ±10
##   PageUp/Down  ±50
##   Home / End   primera / última
##   F            female on/off
##   R            reload texturas
##   Esc          salir

const BG := Color(0.12, 0.12, 0.16)
const OK_COLOR := Color(0.45, 0.85, 0.55)
const MISS_COLOR := Color(0.95, 0.35, 0.35)
const SLOT_SIZE := Vector2(72, 72)
const ICON_SIZE := Vector2(40, 40)

var _ids: Array = []
var _index: int = 0
var _female: bool = false

var _lbl_title: Label
var _lbl_info: Label
var _lbl_status: Label
var _tex_front: TextureRect
var _tex_front_s: TextureRect
var _tex_back: TextureRect
var _tex_back_s: TextureRect
var _tex_icon: TextureRect
var _slot_labels: Array[Label] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	custom_minimum_size = Vector2(480, 320)
	_build_ui()
	if SpeciesCatalog and not SpeciesCatalog.is_ready():
		SpeciesCatalog.warm_index()
		await get_tree().process_frame
		var guard: int = 0
		while SpeciesCatalog and not SpeciesCatalog.is_ready() and guard < 120:
			await get_tree().process_frame
			guard += 1
	_reload_ids()
	_show_current()


func _reload_ids() -> void:
	_ids.clear()
	if SpeciesCatalog == null:
		_lbl_info.text = "SpeciesCatalog no está en autoload"
		return
	_ids = SpeciesCatalog.all_ids()
	_ids = _ids.filter(func(id: Variant) -> bool: return int(id) != int(SpeciesId.Id.NONE))
	if _ids.is_empty():
		_lbl_info.text = "Sin especies (¿import_species_tres?)"
	_index = clampi(_index, 0, maxi(0, _ids.size() - 1))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.offset_left = 6
	root.offset_top = 4
	root.offset_right = -6
	root.offset_bottom = -4
	root.add_theme_constant_override("separation", 3)
	add_child(root)

	_lbl_title = Label.new()
	_lbl_title.text = "Sprite Test"
	_lbl_title.add_theme_font_size_override("font_size", 12)
	root.add_child(_lbl_title)

	_lbl_info = Label.new()
	_lbl_info.add_theme_font_size_override("font_size", 10)
	_lbl_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lbl_info.clip_text = true
	root.add_child(_lbl_info)

	_lbl_status = Label.new()
	_lbl_status.add_theme_font_size_override("font_size", 10)
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lbl_status.clip_text = true
	root.add_child(_lbl_status)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(grid)

	_tex_front = _make_slot(grid, "Front", SLOT_SIZE)
	_tex_front_s = _make_slot(grid, "F.shiny", SLOT_SIZE)
	_tex_back = _make_slot(grid, "Back", SLOT_SIZE)
	_tex_back_s = _make_slot(grid, "B.shiny", SLOT_SIZE)
	_tex_icon = _make_slot(grid, "Icon", ICON_SIZE)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(nav)
	_add_btn(nav, "◀", func() -> void: _step(-1))
	_add_btn(nav, "▶", func() -> void: _step(1))
	_add_btn(nav, "−10", func() -> void: _step(-10))
	_add_btn(nav, "+10", func() -> void: _step(10))
	_add_btn(nav, "♀", func() -> void: _toggle_female())

	var help := Label.new()
	help.text = "←→ ±1  ↑↓ ±10  Pg ±50  Home/End  F♀  R reload  Esc"
	help.add_theme_font_size_override("font_size", 9)
	help.modulate = Color(0.65, 0.65, 0.7)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(help)


func _make_slot(parent: Control, caption: String, size: Vector2) -> TextureRect:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	parent.add_child(col)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = size + Vector2(4, 4)
	col.add_child(frame)

	var tex := TextureRect.new()
	tex.custom_minimum_size = size
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(tex)

	var lbl := Label.new()
	lbl.text = caption
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl)
	_slot_labels.append(lbl)
	return tex


func _add_btn(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(36, 18)
	b.add_theme_font_size_override("font_size", 10)
	b.pressed.connect(cb)
	parent.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: InputEventKey = event
	match k.keycode:
		KEY_LEFT:
			_step(-1)
		KEY_RIGHT:
			_step(1)
		KEY_UP:
			_step(-10)
		KEY_DOWN:
			_step(10)
		KEY_PAGEUP:
			_step(-50)
		KEY_PAGEDOWN:
			_step(50)
		KEY_HOME:
			_index = 0
			_show_current()
		KEY_END:
			_index = maxi(0, _ids.size() - 1)
			_show_current()
		KEY_F:
			_toggle_female()
		KEY_R:
			if PokemonSprites:
				PokemonSprites.clear_cache()
			_show_current()
		KEY_ESCAPE:
			if get_tree().root.get_child_count() > 1:
				queue_free()
			else:
				get_tree().quit()
		_:
			return
	get_viewport().set_input_as_handled()


func _step(delta: int) -> void:
	if _ids.is_empty():
		return
	_index = clampi(_index + delta, 0, _ids.size() - 1)
	_show_current()


func _toggle_female() -> void:
	_female = not _female
	_show_current()


func _show_current() -> void:
	if _ids.is_empty():
		return
	var id: SpeciesId.Id = _ids[_index] as SpeciesId.Id
	var token: String = SpeciesId.to_token(id)
	var sname: String = token
	var dex: int = 0
	if SpeciesCatalog:
		sname = SpeciesCatalog.get_display_name(id)
		dex = SpeciesCatalog.get_national_dex(id)
	var folder: String = PokemonSprites.folder_for(id) if PokemonSprites and PokemonSprites.has_method("folder_for") else SpeciesId.sprite_folder(id)

	_lbl_title.text = "Sprite Test  %d/%d" % [_index + 1, _ids.size()]
	_lbl_info.text = "#%d %s [%s]  dir:%s  ♀:%s" % [
		dex, sname, token,
		folder if not folder.is_empty() else "—",
		"on" if _female else "off",
	]

	if PokemonSprites == null:
		_lbl_status.text = "PokemonSprites no está en autoload"
		_lbl_status.modulate = MISS_COLOR
		return

	var front: Texture2D = PokemonSprites.get_front(id, false, _female)
	var front_s: Texture2D = PokemonSprites.get_front(id, true, _female)
	var back: Texture2D = PokemonSprites.get_back(id, false, _female)
	var back_s: Texture2D = PokemonSprites.get_back(id, true, _female)
	var icon: Texture2D = PokemonSprites.get_icon(id)

	_tex_front.texture = front
	_tex_front_s.texture = front_s
	_tex_back.texture = back
	_tex_back_s.texture = back_s
	_tex_icon.texture = icon

	_paint_label(0, "Front", front != null)
	_paint_label(1, "F.shiny", front_s != null)
	_paint_label(2, "Back", back != null)
	_paint_label(3, "B.shiny", back_s != null)
	_paint_label(4, "Icon", icon != null)

	var missing: PackedStringArray = PackedStringArray()
	if front == null:
		missing.append("front")
	if front_s == null:
		missing.append("f.shiny")
	if back == null:
		missing.append("back")
	if back_s == null:
		missing.append("b.shiny")
	if icon == null:
		missing.append("icon")

	if folder.is_empty():
		_lbl_status.text = "SIN sprite_folder"
		_lbl_status.modulate = MISS_COLOR
	elif missing.is_empty():
		_lbl_status.text = "OK — todos presentes"
		_lbl_status.modulate = OK_COLOR
	else:
		_lbl_status.text = "Faltan: " + ", ".join(missing)
		_lbl_status.modulate = MISS_COLOR


func _paint_label(i: int, base: String, ok: bool) -> void:
	if i < 0 or i >= _slot_labels.size():
		return
	var lbl: Label = _slot_labels[i]
	lbl.text = base + (" ✓" if ok else " ✗")
	lbl.modulate = OK_COLOR if ok else MISS_COLOR
