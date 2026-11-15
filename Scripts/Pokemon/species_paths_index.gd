class_name SpeciesPathsIndex
extends Resource
## Índice ligero: SpeciesId → path del .tres + metadatos baratos.
## Generado por tools/import_species_tres.gd. No contiene SpeciesData.

## int (SpeciesId.Id) → String path "res://Datos/Pokemon/Resources/..."
@export var paths: Dictionary = {}

## int → display_name (sin cargar el .tres)
@export var display_names: Dictionary = {}

## int → national_dex
@export var national_dex: Dictionary = {}

## Orden de ids (int)
@export var ids: Array[int] = []

@export var source_json: String = "res://Datos/Pokemon/species.json"
@export var built_at: String = ""
@export var entry_count: int = 0


func path_for(id: int) -> String:
	if not paths.has(id):
		return ""
	return str(paths[id])


func has_id(id: int) -> bool:
	return paths.has(id)
