@tool
extends EditorScript
## Convierte Datos/Species/species.json → un .tres por especie.
## Ejecutar desde el editor: File → Run o el botón del script.

const JSON_PATH: String = "res://Datos/Species/species.json"
const OUT_DIR: String = "res://Datos/Species/Resources/"
const SCRIPT_PATH: String = "res://Scripts/Data/Species/species_data.gd"


func _run() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		printerr("No existe: ", JSON_PATH)
		return

	var f: FileAccess = FileAccess.open(JSON_PATH, FileAccess.READ)
	if f == null:
		printerr("No se pudo abrir el JSON")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()

	if typeof(parsed) != TYPE_ARRAY:
		printerr("JSON inválido (se esperaba Array)")
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var ok: int = 0
	var skip: int = 0
	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			skip += 1
			continue
		var data: SpeciesData = SpeciesData.from_dict(entry as Dictionary)
		if data.id == SpeciesId.Id.NONE:
			skip += 1
			push_warning("Omitida (id NONE): %s" % str((entry as Dictionary).get("id", "?")))
			continue

		var key: String = SpeciesId.to_key(data.id).to_lower()
		var path: String = OUT_DIR.path_join("%s.tres" % key)

		# Asegura que el resource tenga el script correcto al guardar.
		data.set_script(load(SCRIPT_PATH))

		var err: Error = ResourceSaver.save(data, path)
		if err != OK:
			printerr("Error guardando %s: %s" % [path, error_string(err)])
			continue
		ok += 1

	print("Species .tres: %d generados, %d omitidos → %s" % [ok, skip, OUT_DIR])
