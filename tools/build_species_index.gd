@tool
extends EditorScript
## Genera res://Datos/Pokemon/species_index.res desde species.json.
##
## Uso en el editor:
##   1. Abre este script (tools/build_species_index.gd)
##   2. File → Run (o Ctrl+Shift+X según atajos)
##   3. Revisa la consola: debe imprimir cuántas especies indexó
##
## Vuelve a ejecutarlo cada vez que regeneres / edites species.json
## (por ejemplo tras import_expansion.py).

const JSON_PATH: String = "res://Datos/Pokemon/species.json"
const OUT_PATH: String = "res://Datos/Pokemon/species_index.res"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_error("build_species_index: no existe %s" % JSON_PATH)
		return

	var t0: int = Time.get_ticks_msec()
	var text: String = FileAccess.get_file_as_string(JSON_PATH)
	var parsed: Variant = JSON.parse_string(text)
	text = ""
	if typeof(parsed) != TYPE_ARRAY:
		push_error("build_species_index: JSON inválido (se esperaba Array)")
		return

	var index := SpeciesIndex.new()
	index.source_path = JSON_PATH
	index.built_at = Time.get_datetime_string_from_system(true)
	index.entries = {}
	index.ids = []
	index.display_names = {}
	index.national_dex = {}

	var skipped: int = 0
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			skipped += 1
			continue
		var d: Dictionary = entry
		var token: String = str(d.get("id", ""))
		if token.is_empty():
			skipped += 1
			continue
		var sid: SpeciesId.Id = SpeciesId.from_token(token)
		if sid == SpeciesId.Id.NONE:
			# Token desconocido para el enum actual: se ignora.
			skipped += 1
			continue
		var key: int = int(sid)
		# Guardamos el dict tal cual; el catálogo lo convertirá a SpeciesData.
		index.entries[key] = d
		index.ids.append(key)
		index.display_names[key] = str(d.get("display_name", token))
		index.national_dex[key] = int(d.get("national_dex", 0))

	index.entry_count = index.ids.size()

	var err: Error = ResourceSaver.save(index, OUT_PATH)
	if err != OK:
		push_error("build_species_index: ResourceSaver falló (%s) → %s" % [error_string(err), OUT_PATH])
		return

	var dt: int = Time.get_ticks_msec() - t0
	print(
		"build_species_index: OK — %d especies, %d omitidas, %d ms → %s"
		% [index.entry_count, skipped, dt, OUT_PATH]
	)
