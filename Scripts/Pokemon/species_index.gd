class_name SpeciesIndex
extends Resource
## Índice binario de especies. Se genera con tools/build_species_index.gd
## a partir de Datos/Pokemon/species.json.
##
## Runtime solo carga este .res (rápido). Los SpeciesData se materializan
## bajo demanda desde entries[id].

## SpeciesId.Id (int) -> Dictionary crudo de la entrada JSON
@export var entries: Dictionary = {}

## Orden estable de ids válidos (int = SpeciesId.Id)
@export var ids: Array[int] = []

## SpeciesId.Id (int) -> display_name (lookup sin materializar)
@export var display_names: Dictionary = {}

## SpeciesId.Id (int) -> national_dex
@export var national_dex: Dictionary = {}

## Metadatos del build
@export var source_path: String = "res://Datos/Pokemon/species.json"
@export var built_at: String = ""
@export var entry_count: int = 0


func has_id(id: int) -> bool:
	return entries.has(id) or display_names.has(id)


func get_entry(id: int) -> Dictionary:
	if not entries.has(id):
		return {}
	var v: Variant = entries[id]
	if typeof(v) != TYPE_DICTIONARY:
		return {}
	return v as Dictionary
