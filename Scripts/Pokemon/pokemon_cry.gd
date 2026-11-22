class_name PokemonCry
extends Object
## Resuelve y reproduce el grito de una especie.
## Datos: sprite_folder / token → Sfx/se/cries/*.wav
## Reproducción: MusicManager (bus SFX).

const CRIES_DIR: String = "res://Sfx/se/cries/"


static func path_for_species(species_id: SpeciesId.Id) -> String:
	if species_id == SpeciesId.Id.NONE:
		return ""
	var candidates: PackedStringArray = PackedStringArray()
	if SpeciesCatalog:
		var data: SpeciesData = SpeciesCatalog.get_data(species_id)
		if data != null and not data.sprite_folder.is_empty():
			var folder: String = data.sprite_folder.strip_edges().to_lower()
			# terapagos/stellar → terapagos_stellar, terapagos
			candidates.append(folder.replace("/", "_"))
			if "/" in folder:
				candidates.append(folder.get_file())
				candidates.append(folder.get_base_dir().get_file())
	var token: String = SpeciesId.to_token(species_id).to_lower()
	if not token.is_empty():
		candidates.append(token)
		# Quitar sufijos de forma comunes si hace falta
		if "_" in token:
			candidates.append(token.split("_")[0])
	for name: String in candidates:
		if name.is_empty():
			continue
		var path: String = CRIES_DIR + name + ".wav"
		if ResourceLoader.exists(path):
			return path
		path = CRIES_DIR + name + ".ogg"
		if ResourceLoader.exists(path):
			return path
	return ""


static func play(species_id: SpeciesId.Id) -> void:
	var path: String = path_for_species(species_id)
	if path.is_empty():
		return
	if MusicManager and MusicManager.has_method("reproducir_se_ruta"):
		MusicManager.reproducir_se_ruta(path)
