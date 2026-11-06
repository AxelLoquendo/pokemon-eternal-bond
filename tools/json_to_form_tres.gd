@tool
extends EditorScript
## forms.json → Datos/Species/Forms/*.tres
## Ejecutar DESPUÉS de assign_form_sprites (para llevar sprite_folder).

const FORMS_JSON: String = "res://Datos/Species/forms.json"
const OUT_DIR: String = "res://Datos/Species/Forms/"


func _run() -> void:
	if not FileAccess.file_exists(FORMS_JSON):
		printerr("Falta ", FORMS_JSON)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var f: FileAccess = FileAccess.open(FORMS_JSON, FileAccess.READ)
	if f == null:
		printerr("No se abrió forms.json")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		printerr("forms.json no es un array")
		return

	var ok: int = 0
	var skip: int = 0

	for entry: Variant in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			skip += 1
			continue
		var data: FormData = FormData.from_dict(entry)
		if data.species == SpeciesId.Id.NONE or data.form <= 0:
			skip += 1
			continue

		var file_name: String = "%s_%d.tres" % [
			SpeciesId.to_key(data.species).to_lower(),
			data.form,
		]
		var path: String = OUT_DIR.path_join(file_name)
		var err: Error = ResourceSaver.save(data, path)
		if err == OK:
			ok += 1
		else:
			printerr("Error ", path, ": ", error_string(err))

	print("Formas .tres: %d guardadas, %d omitidas → %s" % [ok, skip, OUT_DIR])
