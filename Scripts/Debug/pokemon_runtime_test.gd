extends Control
## Prueba de integración: Species + Moves + Ability + Item + sprites.
## Controles: R regenera mon  |  T intenta TM01  |  Esc sale del play (no quit forzado)

const BG := Color(0.1, 0.11, 0.14)

var _mon: PokemonInstance
var _lbl: Label
var _tex: TextureRect
var _log: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)
	_tex = TextureRect.new()
	_tex.position = Vector2(16, 40)
	_tex.size = Vector2(96, 96)
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_tex)
	_lbl = Label.new()
	_lbl.position = Vector2(130, 16)
	_lbl.size = Vector2(330, 200)
	_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl.add_theme_font_size_override("font_size", 12)
	add_child(_lbl)
	_log = Label.new()
	_log.position = Vector2(16, 260)
	_log.size = Vector2(448, 50)
	_log.add_theme_font_size_override("font_size", 11)
	_log.modulate = Color(0.7, 0.85, 0.7)
	add_child(_log)
	await get_tree().process_frame
	_spawn()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			_spawn()
		KEY_T:
			_try_tm()


func _spawn() -> void:
	_mon = PokemonInstance.create(SpeciesId.Id.BULBASAUR, 16, true, true)
	_refresh("Creado Bulbasaur Nv16")


func _try_tm() -> void:
	if _mon == null:
		return
	var r: Dictionary = _mon.learn_from_item(ItemId.Id.TM01, 0)
	_refresh("TM01 → %s (%s)" % [str(r.get("reason")), MoveId.to_token(r.get("move", MoveId.Id.NONE) as MoveId.Id)])


func _refresh(msg: String) -> void:
	_log.text = msg
	if _mon == null:
		_lbl.text = "sin mon"
		return
	_tex.texture = _mon.front_texture(_mon.is_shiny)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s  Nv%d  %s" % [_mon.display_name(), _mon.level, SpeciesId.to_token(_mon.species_id)])
	lines.append("HP %d/%d  Atk %d  Def %d  Spa %d  Spd %d  Spe %d" % [
		_mon.hp, _mon.max_hp,
		_mon.get_stat(PokemonEnums.Stat.ATK),
		_mon.get_stat(PokemonEnums.Stat.DEF),
		_mon.get_stat(PokemonEnums.Stat.SPA),
		_mon.get_stat(PokemonEnums.Stat.SPD),
		_mon.get_stat(PokemonEnums.Stat.SPE),
	])
	lines.append("Hab: %s" % _mon.ability_name())
	var move_bits: PackedStringArray = PackedStringArray()
	for i: int in _mon.moves.size():
		var md: MoveData = _mon.move_data_at(i)
		var nm: String = md.display_name if md else MoveId.to_token(_mon.moves[i])
		move_bits.append("%s (%dpp)" % [nm, _mon.move_pp[i] if i < _mon.move_pp.size() else 0])
	lines.append("Moves: " + ", ".join(move_bits))
	lines.append("R = nuevo mon   T = enseñar TM01 (reemplaza slot 0 si lleno)")
	_lbl.text = "\n".join(lines)
