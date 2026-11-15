# Índice binario de especies

## Problema

`Datos/Pokemon/species.json` pesa ~3.1 MB. Aunque el catálogo ya era lazy (no creaba todos los `SpeciesData` al arrancar), **parsear ese JSON** en cada lanzamiento seguía costando tiempo y se notaba en el boot.

## Solución

1. **Tool de editor** `tools/build_species_index.gd` lee el JSON **una vez** y genera:
   - `res://Datos/Pokemon/species_index.res` (`SpeciesIndex`)
2. **`SpeciesCatalog`** en runtime carga solo el `.res` (deserialización binaria de Godot, mucho más rápida que `JSON.parse_string`).
3. `get_data(id)` sigue materializando `SpeciesData` solo cuando hace falta.

El JSON se puede dejar en el proyecto como fuente editable / generada por `import_expansion.py`. No hace falta cargarlo en el juego si el índice existe.

## Cómo generar / actualizar el índice

En el editor de Godot:

1. Abre `tools/build_species_index.gd`
2. **File → Run** (EditorScript)
3. En la consola deberías ver algo como:
   ```text
   build_species_index: OK — N especies, 0 omitidas, X ms → res://Datos/Pokemon/species_index.res
   ```

Vuelve a ejecutarlo cada vez que regeneres o edites `species.json`.

## Arranque del juego

- Si existe `species_index.res` → carga rápida.
- Si no existe → fallback al JSON + warning en consola pidiendo que ejecutes el tool.

## API del catálogo (sin cambios de uso)

```gdscript
SpeciesCatalog.warm_index()           # opcional; ya se llama en _ready diferido
SpeciesCatalog.is_ready() -> bool
SpeciesCatalog.get_data(id) -> SpeciesData
SpeciesCatalog.get_display_name(id) -> String
SpeciesCatalog.get_national_dex(id) -> int
SpeciesCatalog.has_species(id) -> bool
SpeciesCatalog.count() -> int
SpeciesCatalog.all_ids() -> Array
SpeciesCatalog.clear_cache()
SpeciesCatalog.reload()
```

## Regla de boot

En título / menú principal **no** llames `count()`, `all_ids()` ni `get_data()` hasta que el jugador entre al overworld o abra la Pokédex. Solo `warm_index()` (o nada: el autoload ya lo hace diferido).

## Archivos tocados

| Ruta | Rol |
|------|-----|
| `Scripts/Pokemon/species_index.gd` | Resource del índice |
| `Scripts/Pokemon/species_catalog.gd` | Catálogo runtime (reemplaza el anterior) |
| `tools/build_species_index.gd` | EditorScript que genera el `.res` |
| `Datos/Pokemon/species_index.res` | Generado (añadir al repo tras el primer Run) |

## Siguiente paso opcional (Moves / Items)

El mismo patrón aplica a `moves.json` e `items.json` si el boot sigue pesado. Abilities es pequeño y puede quedarse como está.
