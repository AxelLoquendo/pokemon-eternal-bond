extends Control
## Debug 480×320: sprites + ficha SpeciesData.
##
## 1 Sprites  2 Identidad  3 Stats  4 Abilities  5 Moves  6 Evo
## ←→ especie  ↑↓ ±10  Pg ±50  F female  R reload  Esc → volver/nop

const BG := Color(0.12, 0.12, 0.16)
const OK_COLOR := Color(0.45, 0.85, 0.55)
const MISS_COLOR := Color(0.95, 0.35, 0.35)
const MUTED := Color(0.65, 0.7, 0.75)
const SLOT_SIZE := Vector2(64, 64)
const ICON_SIZE := Vector2(36, 36)

const SECTION_NAMES: PackedStringArray = [
	"1 Sprites",
	"2 Identidad",
	"3 Stats",
	"4 Abilities",
	"5 Moves",
	"6 Evo/Formas",
]

var _ids: Array = []
var _index: int = 0
var _female: bool = false
var _section: int = 0

var _lbl_title: Label
var _lbl_info: Label
var _lbl_tabs: Label
var _lbl_status: Label
var _body: Label
var _panel_sprites: Control
var _tex_front: TextureRect
var _tex_front_s: TextureRect
var _tex_back: TextureRect
var _tex_back_s: TextureRect
var _tex_icon: TextureRect
var _slot_labels: Array[Label] = []
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	custom_minimum_size = Vector2(480, 320)
	_build_ui()
	# Un frame para que autoloads terminen su _ready
	await get_tree().process_frame
	if SpeciesCatalog != null and SpeciesCatalog.has_method("warm_index"):
		SpeciesCatalog.warm_index()
	await get_tree().process_frame
	_reload_ids()
	_show_current()


func _reload_ids() -> void:
	_ids.clear()
	if SpeciesCatalog == null:
		_lbl_info.text = "SpeciesCatalog no está en autoload"
		return
	if not SpeciesCatalog.is_ready():
		SpeciesCatalog.warm_index()
	var raw: Array = SpeciesCatalog.all_ids()
	for v: Variant in raw:
		var n: int = int(v)
		if n != int(SpeciesId.Id.NONE):
			_ids.append(n)
	if _ids.is_empty():
		_lbl_info.text = "Índice vacío — rebuild_species_index"
	_index = clampi(_index, 0, maxi(_ids.size() - 1, 0))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	_lbl_title = _mk_label(Vector2(6, 2), Vector2(300, 16), 12)
	_lbl_title.modulate = Color(0.9, 0.92, 1.0)
	add_child(_lbl_title)

	_lbl_tabs = _mk_label(Vector2(6, 18), Vector2(468, 14), 10)
	_lbl_tabs.modulate = MUTED
	add_child(_lbl_tabs)

	_lbl_info = _mk_label(Vector2(6, 32), Vector2(468, 28), 11)
	_lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_lbl_info)

	_panel_sprites = Control.new()
	_panel_sprites.position = Vector2(6, 64)
	_panel_sprites.size = Vector2(468, 220)
	add_child(_panel_sprites)

	for i: int in 5:
		var x: float = i * 92.0
		var box := ColorRect.new()
		box.color = Color(0.18, 0.18, 0.22)
		box.position = Vector2(x, 0)
		box.size = Vector2(88, 88)
		_panel_sprites.add_child(box)

		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(x + 8, 8)
		tr.size = ICON_SIZE if i == 4 else SLOT_SIZE
		_panel_sprites.add_child(tr)

		var lbl := _mk_label(Vector2(x, 90), Vector2(88, 14), 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel_sprites.add_child(lbl)
		_slot_labels.append(lbl)

		match i:
			0: _tex_front = tr
			1: _tex_front_s = tr
			2: _tex_back = tr
			3: _tex_back_s = tr
			4: _tex_icon = tr

	var help := _mk_label(Vector2(0, 112), Vector2(468, 40), 10)
	help.modulate = MUTED
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "←→ especie  ↑↓ ±10  Pg ±50  1-6 sección  F female  R reload"
	_panel_sprites.add_child(help)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(6, 64)
	_scroll.size = Vector2(468, 220)
	_scroll.visible = false
	add_child(_scroll)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(450, 0)
	_body.add_theme_font_size_override("font_size", 11)
	_body.modulate = Color(0.92, 0.93, 0.95)
	_scroll.add_child(_body)

	_lbl_status = _mk_label(Vector2(6, 300), Vector2(468, 16), 11)
	add_child(_lbl_status)


func _mk_label(pos: Vector2, size: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = size
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = (event as InputEventKey).keycode
	match key:
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
			if not _ids.is_empty():
				_index = _ids.size() - 1
			_show_current()
		KEY_F:
			_female = not _female
			_show_current()
		KEY_R:
			if PokemonSprites != null and PokemonSprites.has_method("clear_cache"):
				PokemonSprites.clear_cache()
			if SpeciesCatalog != null and SpeciesCatalog.has_method("clear_cache"):
				SpeciesCatalog.clear_cache()
			_reload_ids()
			_show_current()
		KEY_1:
			_section = 0
			_show_current()
		KEY_2:
			_section = 1
			_show_current()
		KEY_3:
			_section = 2
			_show_current()
		KEY_4:
			_section = 3
			_show_current()
		KEY_5:
			_section = 4
			_show_current()
		KEY_6:
			_section = 5
			_show_current()
		# Esc: no quit() — cerraba la app / el play del editor de golpe


func _step(delta: int) -> void:
	if _ids.is_empty():
		return
	_index = posmod(_index + delta, _ids.size())
	_show_current()


func _show_current() -> void:
	_refresh_tabs()
	if _ids.is_empty():
		_lbl_title.text = "Species Test  0/0"
		_lbl_info.text = "Sin especies en el índice"
		_lbl_status.text = ""
		_panel_sprites.visible = _section == 0
		_scroll.visible = _section != 0
		if _section != 0:
			_body.text = "Sin datos"
		return

	var id: SpeciesId.Id = _ids[_index] as SpeciesId.Id
	var token: String = SpeciesId.to_token(id)
	var data: SpeciesData = null
	if SpeciesCatalog != null:
		data = SpeciesCatalog.get_data(id)

	var sname: String = token
	var dex: int = 0
	var folder: String = ""
	if data != null:
		if not data.display_name.is_empty():
			sname = data.display_name
		dex = data.national_dex
		folder = str(data.sprite_folder)
	elif SpeciesCatalog != null:
		sname = SpeciesCatalog.get_display_name(id)
		dex = SpeciesCatalog.get_national_dex(id)

	_lbl_title.text = "Species Test  %d/%d" % [_index + 1, _ids.size()]
	_lbl_info.text = "#%d %s  [%s]\ndir:%s  ♀:%s  data:%s" % [
		dex, sname, token,
		folder if not folder.is_empty() else "—",
		"on" if _female else "off",
		"OK" if data != null else "NULL",
	]

	var show_sprites: bool = _section == 0
	_panel_sprites.visible = show_sprites
	_scroll.visible = not show_sprites

	if show_sprites:
		_fill_sprites(id, folder)
	else:
		_fill_section(data, token)


func _refresh_tabs() -> void:
	var parts: PackedStringArray = PackedStringArray()
	for i: int in SECTION_NAMES.size():
		var n: String = SECTION_NAMES[i]
		parts.append("[%s]" % n if i == _section else n)
	_lbl_tabs.text = "  ".join(parts)


func _fill_sprites(id: SpeciesId.Id, folder: String) -> void:
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

	_paint_slot(0, "Front", front != null)
	_paint_slot(1, "F.shiny", front_s != null)
	_paint_slot(2, "Back", back != null)
	_paint_slot(3, "B.shiny", back_s != null)
	_paint_slot(4, "Icon", icon != null)

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
		_lbl_status.text = "SIN sprite_folder en el .tres"
		_lbl_status.modulate = MISS_COLOR
	elif missing.is_empty():
		_lbl_status.text = "OK — todos los sprites"
		_lbl_status.modulate = OK_COLOR
	else:
		_lbl_status.text = "Faltan: " + ", ".join(missing)
		_lbl_status.modulate = MISS_COLOR


func _paint_slot(i: int, base: String, ok: bool) -> void:
	if i < 0 or i >= _slot_labels.size():
		return
	_slot_labels[i].text = base + (" ✓" if ok else " ✗")
	_slot_labels[i].modulate = OK_COLOR if ok else MISS_COLOR


func _fill_section(data: SpeciesData, token: String) -> void:
	if data == null:
		_body.text = "SpeciesData NULL para %s\nRevisa species_paths.res / rebuild" % token
		_lbl_status.text = "DATA NULL"
		_lbl_status.modulate = MISS_COLOR
		return

	match _section:
		1:
			_body.text = _section_identity(data, token)
		2:
			_body.text = _section_stats(data)
		3:
			_body.text = _section_abilities(data)
		4:
			_body.text = _section_moves(data)
		5:
			_body.text = _section_evo(data)
		_:
			_body.text = ""

	_lbl_status.text = "sección %s — .tres OK" % SECTION_NAMES[_section]
	_lbl_status.modulate = OK_COLOR


func _en(v: Variant) -> String:
	return str(v)


func _section_identity(data: SpeciesData, token: String) -> String:
	var flags: PackedStringArray = PackedStringArray()
	if data.is_restricted_legendary:
		flags.append("legendary")
	if data.is_sub_legendary:
		flags.append("sub_leg")
	if data.is_mythical:
		flags.append("mythical")
	if data.is_ultra_beast:
		flags.append("UB")
	if data.is_paradox:
		flags.append("paradox")
	if data.is_mega:
		flags.append("mega")
	if data.is_gigantamax:
		flags.append("gmax")
	if data.is_alolan:
		flags.append("alolan")
	if data.is_galarian:
		flags.append("galarian")
	if data.is_hisuian:
		flags.append("hisuian")
	if data.is_paldean:
		flags.append("paldean")
	return "\n".join(PackedStringArray([
		"token: %s" % token,
		"name: %s" % data.display_name,
		"category: %s" % data.category,
		"dex: %d" % data.national_dex,
		"sprite_folder: %s" % data.sprite_folder,
		"type_1: %s" % _en(data.type_1),
		"type_2: %s" % _en(data.type_2),
		"force_tera: %s" % _en(data.force_tera_type),
		"height_dm: %d  weight_hg: %d" % [data.height_dm, data.weight_hg],
		"body_color: %s  no_flip: %s" % [_en(data.body_color), str(data.no_flip)],
		"flags: %s" % (", ".join(flags) if not flags.is_empty() else "—"),
		"",
		"pokedex:",
		data.pokedex if not data.pokedex.is_empty() else "(vacío)",
	]))


func _section_stats(data: SpeciesData) -> String:
	var bst: int = (
		data.base_hp + data.base_atk + data.base_def
		+ data.base_spa + data.base_spd + data.base_spe
	)
	return "\n".join(PackedStringArray([
		"BASE     HP  Atk Def Spa Spd Spe | BST",
		"      %4d %4d %4d %4d %4d %4d | %d" % [
			data.base_hp, data.base_atk, data.base_def,
			data.base_spa, data.base_spd, data.base_spe, bst,
		],
		"",
		"EV yield HP  Atk Def Spa Spd Spe",
		"      %4d %4d %4d %4d %4d %4d" % [
			data.ev_hp, data.ev_atk, data.ev_def,
			data.ev_spa, data.ev_spd, data.ev_spe,
		],
		"",
		"catch_rate: %d" % data.catch_rate,
		"base_exp: %d" % data.base_exp,
		"friendship: %d" % data.base_friendship,
		"gender_ratio: %d" % data.gender_ratio,
		"growth: %s" % _en(data.growth_rate),
		"egg_cycles: %d" % data.egg_cycles,
		"egg_group_1: %s" % _en(data.egg_group_1),
		"egg_group_2: %s" % _en(data.egg_group_2),
	]))


func _section_abilities(data: SpeciesData) -> String:
	return "\n".join(PackedStringArray([
		"ability_1: %s" % _en(data.ability_1),
		"ability_2: %s" % _en(data.ability_2),
		"hidden:    %s" % _en(data.ability_hidden),
		"",
		"item_common: %s" % _en(data.item_common),
		"item_rare:   %s" % _en(data.item_rare),
	]))


func _section_moves(data: SpeciesData) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("level_moves (%d):" % data.level_moves.size())
	if data.level_moves.is_empty():
		lines.append("  (vacío)")
	else:
		for i: int in data.level_moves.size():
			var lm: LevelUpMove = data.level_moves[i]
			if lm == null:
				continue
			lines.append("  Lv%3d  %s" % [lm.level, _en(lm.move)])
	lines.append("")
	lines.append("egg_moves (%d):" % data.egg_moves.size())
	if data.egg_moves.is_empty():
		lines.append("  (vacío)")
	else:
		for j: int in data.egg_moves.size():
			lines.append("  %s" % _en(data.egg_moves[j]))
	lines.append("")
	lines.append("tutor_moves (%d):" % data.tutor_moves.size())
	if data.tutor_moves.is_empty():
		lines.append("  (vacío)")
	else:
		for k: int in data.tutor_moves.size():
			lines.append("  %s" % _en(data.tutor_moves[k]))
	return "\n".join(lines)


func _section_evo(data: SpeciesData) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("evolutions (%d):" % data.evolutions.size())
	if data.evolutions.is_empty():
		lines.append("  (ninguna)")
	else:
		for i: int in data.evolutions.size():
			var evo: EvolutionData = data.evolutions[i]
			if evo == null:
				continue
			lines.append("  %s  param=%s  → %s" % [
				evo.method, evo.param, SpeciesId.to_token(evo.target),
			])
	lines.append("")
	lines.append("form_species (%d):" % data.form_species.size())
	if data.form_species.is_empty():
		lines.append("  (ninguna)")
	else:
		for j: int in data.form_species.size():
			lines.append("  %s" % SpeciesId.to_token(data.form_species[j]))
	lines.append("")
	lines.append("form_changes (%d):" % data.form_changes.size())
	if data.form_changes.is_empty():
		lines.append("  (ninguno)")
	else:
		for k: int in data.form_changes.size():
			var fc: FormChangeData = data.form_changes[k]
			if fc == null:
				continue
			lines.append("  %s → %s (%s,%s)" % [
				fc.method, SpeciesId.to_token(fc.target), fc.param1, fc.param2,
			])
	return "\n".join(lines)
