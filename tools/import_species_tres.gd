@tool
extends EditorScript
## MIGRACIÓN opcional JSON → .tres (una vez).
## Flujo diario: editar .tres + tools/rebuild_species_index.gd

## Convierte Datos/Pokemon/species.json → un .tres por especie + índice de paths.
##
## Uso:
##   1. Abre este script en el editor
##   2. File → Run
##   3. Revisa la consola
##
## Salida:
##   res://Datos/Pokemon/Resources/gen_N/<TOKEN>.tres
##   res://Datos/Pokemon/species_paths.res
##
## Vuelve a ejecutarlo tras regenerar species.json (import desde expansion
## o tools/expand_missing_forms.py).

const JSON_PATH: String = "res://Datos/Pokemon/species.json"
const OUT_DIR: String = "res://Datos/Pokemon/Resources"
const INDEX_PATH: String = "res://Datos/Pokemon/species_paths.res"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_error("import_species_tres: no existe %s" % JSON_PATH)
		return

	var t0: int = Time.get_ticks_msec()
	var text: String = FileAccess.get_file_as_string(JSON_PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = ""
	if typeof(parsed) != TYPE_ARRAY:
		push_error("import_species_tres: JSON inválido (se esperaba Array)")
		return

	_ensure_dir(OUT_DIR)

	var index := SpeciesPathsIndex.new()
	index.source_json = JSON_PATH
	index.built_at = Time.get_datetime_string_from_system(true)
	index.paths = {}
	index.display_names = {}
	index.national_dex = {}
	index.ids = []

	var ok: int = 0
	var skipped: int = 0
	var errors: int = 0

	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			skipped += 1
			continue
		var d: Dictionary = entry
		var token: String = str(d.get("id", "")).strip_edges()
		if token.is_empty():
			skipped += 1
			continue
		var sid: SpeciesId.Id = SpeciesId.from_token(token)
		if sid == SpeciesId.Id.NONE:
			skipped += 1
			push_warning("import_species_tres: token desconocido %s" % token)
			continue

		var data: SpeciesData = _from_dict(d, sid)
		if data == null:
			errors += 1
			push_warning("import_species_tres: null %s" % token)
			continue
		# Formas cosméticas del expansion a veces vienen sin display_name.
		if data.display_name.is_empty():
			data.display_name = _fallback_display_name(token, d)
		if data.id == SpeciesId.Id.NONE:
			errors += 1
			push_warning("import_species_tres: id NONE %s" % token)
			continue

		var gen: int = _gen_folder(data.national_dex)
		var folder: String = OUT_DIR.path_join("gen_%d" % gen)
		_ensure_dir(folder)
		var path: String = folder.path_join("%s.tres" % token)

		var err: Error = ResourceSaver.save(data, path)
		if err != OK:
			errors += 1
			push_error("import_species_tres: no se pudo guardar %s (%s)" % [path, error_string(err)])
			continue

		var key: int = int(sid)
		index.paths[key] = path
		index.display_names[key] = data.display_name
		index.national_dex[key] = data.national_dex
		index.ids.append(key)
		ok += 1

	index.entry_count = index.ids.size()
	var ierr: Error = ResourceSaver.save(index, INDEX_PATH)
	if ierr != OK:
		push_error("import_species_tres: no se pudo guardar índice %s (%s)" % [INDEX_PATH, error_string(ierr)])
		return

	var dt: int = Time.get_ticks_msec() - t0
	print(
		"import_species_tres: OK — %d .tres, %d omitidas, %d errores, %d ms → %s"
		% [ok, skipped, errors, dt, INDEX_PATH]
	)


func _ensure_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	var err: Error = DirAccess.make_dir_recursive_absolute(path)
	if err != OK:
		push_error("import_species_tres: no se pudo crear %s (%s)" % [path, error_string(err)])


## Nombre legible cuando el JSON no trae display_name (formas de color, etc.).
func _fallback_display_name(token: String, entry: Dictionary) -> String:
	var form_name: String = str(entry.get("form_name", "")).strip_edges()
	if not form_name.is_empty():
		return form_name
	var parts: PackedStringArray = token.split("_")
	var words: PackedStringArray = []
	for p: String in parts:
		if p.is_empty():
			continue
		words.append(p.capitalize())
	if words.is_empty():
		return token
	return " ".join(words)


func _gen_folder(national_dex: int) -> int:
	if national_dex <= 0:
		return 0
	if national_dex <= 151:
		return 1
	if national_dex <= 251:
		return 2
	if national_dex <= 386:
		return 3
	if national_dex <= 493:
		return 4
	if national_dex <= 649:
		return 5
	if national_dex <= 721:
		return 6
	if national_dex <= 809:
		return 7
	if national_dex <= 905:
		return 8
	if national_dex <= 1025:
		return 9
	return 0


func _from_dict(e: Dictionary, id: SpeciesId.Id) -> SpeciesData:
	var data := SpeciesData.new()
	data.id = id
	data.display_name = str(e.get("display_name", ""))
	data.category = str(e.get("category", ""))
	data.national_dex = int(e.get("national_dex", 0))
	data.pokedex = str(e.get("pokedex", ""))

	var type_list: Array = e.get("types", [])
	if type_list.size() >= 1:
		data.type_1 = TypeId.from_token(str(type_list[0]))
	if type_list.size() >= 2:
		data.type_2 = TypeId.from_token(str(type_list[1]))
	data.force_tera_type = TypeId.from_token(str(e.get("force_tera_type", "NONE")))

	data.base_hp = int(e.get("base_hp", 1))
	data.base_atk = int(e.get("base_atk", 1))
	data.base_def = int(e.get("base_def", 1))
	data.base_spa = int(e.get("base_spa", 1))
	data.base_spd = int(e.get("base_spd", 1))
	data.base_spe = int(e.get("base_spe", 1))

	data.ev_hp = int(e.get("ev_hp", 0))
	data.ev_atk = int(e.get("ev_atk", 0))
	data.ev_def = int(e.get("ev_def", 0))
	data.ev_spa = int(e.get("ev_spa", 0))
	data.ev_spd = int(e.get("ev_spd", 0))
	data.ev_spe = int(e.get("ev_spe", 0))

	data.catch_rate = int(e.get("catch_rate", 45))
	data.base_exp = int(e.get("base_exp", 0))
	data.base_friendship = int(e.get("base_friendship", 50))
	data.gender_ratio = int(e.get("gender_ratio", 127))
	data.growth_rate = _growth(str(e.get("growth_rate", "MEDIUM_FAST")))
	data.egg_cycles = int(e.get("egg_cycles", 20))

	var groups: Array = e.get("egg_groups", [])
	if groups.size() >= 1:
		data.egg_group_1 = _egg_group(str(groups[0]))
	if groups.size() >= 2:
		data.egg_group_2 = _egg_group(str(groups[1]))

	var abs: Array = e.get("abilities", [])
	if abs.size() >= 1:
		data.ability_1 = AbilityId.from_token(str(abs[0]))
	if abs.size() >= 2:
		data.ability_2 = AbilityId.from_token(str(abs[1]))
	if abs.size() >= 3:
		data.ability_hidden = AbilityId.from_token(str(abs[2]))

	data.item_common = ItemId.from_token(str(e.get("item_common", "")))
	data.item_rare = ItemId.from_token(str(e.get("item_rare", "")))

	data.height_dm = int(e.get("height_dm", 0))
	data.weight_hg = int(e.get("weight_hg", 0))
	data.body_color = _body_color(str(e.get("body_color", "RED")))
	data.no_flip = bool(e.get("no_flip", false))
	data.perfect_iv_count = int(e.get("perfect_iv_count", 0))
	data.cannot_be_traded = bool(e.get("cannot_be_traded", false))

	data.sprite_folder = str(e.get("sprite_folder", "")).strip_edges()

	data.is_restricted_legendary = bool(e.get("is_restricted_legendary", false))
	data.is_sub_legendary = bool(e.get("is_sub_legendary", false))
	data.is_mythical = bool(e.get("is_mythical", false))
	data.is_ultra_beast = bool(e.get("is_ultra_beast", false))
	data.is_paradox = bool(e.get("is_paradox", false))
	data.is_totem = bool(e.get("is_totem", false))
	data.is_mega = bool(e.get("is_mega", false))
	data.is_primal = bool(e.get("is_primal", false))
	data.is_ultra_burst = bool(e.get("is_ultra_burst", false))
	data.is_gigantamax = bool(e.get("is_gigantamax", false))
	data.is_tera_form = bool(e.get("is_tera_form", false))
	data.is_alolan = bool(e.get("is_alolan", false))
	data.is_galarian = bool(e.get("is_galarian", false))
	data.is_hisuian = bool(e.get("is_hisuian", false))
	data.is_paldean = bool(e.get("is_paldean", false))

	data.level_moves.clear()
	for m: Variant in e.get("level_moves", []):
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var md: Dictionary = m
		var lm := LevelUpMove.new()
		lm.level = int(md.get("level", 1))
		lm.move = MoveId.from_token(str(md.get("move", "")))
		data.level_moves.append(lm)

	data.tutor_moves.clear()
	for m: Variant in e.get("tutor_moves", []):
		var mid: MoveId.Id = MoveId.from_token(str(m))
		if mid != MoveId.Id.NONE:
			data.tutor_moves.append(mid)

	data.egg_moves.clear()
	for m: Variant in e.get("egg_moves", []):
		var mid2: MoveId.Id = MoveId.from_token(str(m))
		if mid2 != MoveId.Id.NONE:
			data.egg_moves.append(mid2)

	data.evolutions.clear()
	for raw: Variant in e.get("evolutions", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var ed: Dictionary = raw
		var evo := EvolutionData.new()
		evo.method = str(ed.get("method", ""))
		evo.param = str(ed.get("param", ""))
		evo.target = SpeciesId.from_token(str(ed.get("target", "")))
		if ed.has("conditions") and typeof(ed["conditions"]) == TYPE_ARRAY:
			for c: Variant in ed["conditions"]:
				if typeof(c) == TYPE_DICTIONARY:
					evo.conditions.append(c)
		data.evolutions.append(evo)

	data.form_species.clear()
	for s: Variant in e.get("form_species", []):
		var fsid: SpeciesId.Id = SpeciesId.from_token(str(s))
		if fsid != SpeciesId.Id.NONE:
			data.form_species.append(fsid)

	data.form_changes.clear()
	for raw2: Variant in e.get("form_changes", []):
		if typeof(raw2) != TYPE_DICTIONARY:
			continue
		var fd: Dictionary = raw2
		var fc := FormChangeData.new()
		fc.method = str(fd.get("method", ""))
		fc.target = SpeciesId.from_token(str(fd.get("target", "")))
		fc.param1 = str(fd.get("param1", ""))
		fc.param2 = str(fd.get("param2", ""))
		fc.param3 = str(fd.get("param3", ""))
		fc.param4 = str(fd.get("param4", ""))
		data.form_changes.append(fc)

	return data


func _growth(token: String) -> PokemonEnums.Growth:
	match token:
		"ERRATIC":
			return PokemonEnums.Growth.ERRATIC
		"FLUCTUATING":
			return PokemonEnums.Growth.FLUCTUATING
		"MEDIUM_SLOW":
			return PokemonEnums.Growth.MEDIUM_SLOW
		"FAST":
			return PokemonEnums.Growth.FAST
		"SLOW":
			return PokemonEnums.Growth.SLOW
		_:
			return PokemonEnums.Growth.MEDIUM_FAST


func _egg_group(token: String) -> PokemonEnums.EggGroup:
	match token:
		"MONSTER":
			return PokemonEnums.EggGroup.MONSTER
		"WATER_1":
			return PokemonEnums.EggGroup.WATER_1
		"BUG":
			return PokemonEnums.EggGroup.BUG
		"FLYING":
			return PokemonEnums.EggGroup.FLYING
		"FIELD":
			return PokemonEnums.EggGroup.FIELD
		"FAIRY":
			return PokemonEnums.EggGroup.FAIRY
		"GRASS":
			return PokemonEnums.EggGroup.GRASS
		"HUMAN_LIKE":
			return PokemonEnums.EggGroup.HUMAN_LIKE
		"WATER_3":
			return PokemonEnums.EggGroup.WATER_3
		"MINERAL":
			return PokemonEnums.EggGroup.MINERAL
		"AMORPHOUS":
			return PokemonEnums.EggGroup.AMORPHOUS
		"WATER_2":
			return PokemonEnums.EggGroup.WATER_2
		"DITTO":
			return PokemonEnums.EggGroup.DITTO
		"DRAGON":
			return PokemonEnums.EggGroup.DRAGON
		"NO_EGGS":
			return PokemonEnums.EggGroup.NO_EGGS
		_:
			return PokemonEnums.EggGroup.NONE


func _body_color(token: String) -> PokemonEnums.BodyColor:
	match token:
		"BLUE":
			return PokemonEnums.BodyColor.BLUE
		"YELLOW":
			return PokemonEnums.BodyColor.YELLOW
		"GREEN":
			return PokemonEnums.BodyColor.GREEN
		"BLACK":
			return PokemonEnums.BodyColor.BLACK
		"BROWN":
			return PokemonEnums.BodyColor.BROWN
		"PURPLE":
			return PokemonEnums.BodyColor.PURPLE
		"GRAY", "GREY":
			return PokemonEnums.BodyColor.GRAY
		"WHITE":
			return PokemonEnums.BodyColor.WHITE
		"PINK":
			return PokemonEnums.BodyColor.PINK
		_:
			return PokemonEnums.BodyColor.RED
