@tool
extends EditorScript
## Asigna sprite_folder a cada SpeciesData si existe la carpeta en Graficos/Pokemon.

const RES_DIR: String = "res://Datos/Species/Resources/"
const SPRITES_DIR: String = "res://Graficos/Pokemon/"


func _run() -> void:
	var dir: DirAccess = DirAccess.open(RES_DIR)
	if dir == null:
		printerr("No existe ", RES_DIR)
		return

	var assigned: int = 0
	var missing: int = 0
	var total: int = 0

	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			total += 1
			var path: String = RES_DIR.path_join(name)
			var res: Resource = load(path)
			if res is SpeciesData:
				var data: SpeciesData = res as SpeciesData
				var folder: String = SpeciesId.to_key(data.id).to_lower()
				var sprite_path: String = SPRITES_DIR.path_join(folder)
				if DirAccess.open(sprite_path) != null:
					data.sprite_folder = folder
					var err: Error = ResourceSaver.save(data, path)
					if err == OK:
						assigned += 1
					else:
						printerr("Error guardando ", path)
				else:
					missing += 1
					print("SIN carpeta de sprites: ", folder)
		name = dir.get_next()
	dir.list_dir_end()

	print("Sprites: %d asignados, %d sin carpeta, %d resources" % [assigned, missing, total])
