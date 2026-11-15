# Especies como `.tres` (lazy por path)

## Modelo

Igual que PokeDot-Engine:

1. **Una ficha = un archivo**  
   `res://Datos/Pokemon/Resources/gen_N/BULBASAUR.tres` (`SpeciesData`)

2. **Índice ligero al arrancar**  
   `res://Datos/Pokemon/species_paths.res` (`SpeciesPathsIndex`)  
   Solo: `id → path`, nombres y national_dex.

3. **Carga bajo demanda**  
   `SpeciesCatalog.get_data(id)` hace `ResourceLoader.load(path)` y cachea.

El JSON `species.json` queda como **fuente de import**. El runtime no lo parsea.

## Layout de `SpeciesData` (Inspector)

Campos fijos van como **enum suelto** (no arrays):

| Antes | Ahora |
|-------|--------|
| `types: Array[TypeId]` | `type_1`, `type_2` |
| `abilities: Array[AbilityId]` | `ability_1`, `ability_2`, `ability_hidden` |
| `egg_groups: Array[EggGroup]` | `egg_group_1`, `egg_group_2` |
| `level_moves: Array[Dictionary]` | `level_moves: Array[LevelUpMove]` |

Helpers de compatibilidad:

- `types()` → Array de tipos no-NONE  
- `abilities()` → `[ability_1, ability_2, ability_hidden]`  
- `egg_groups()` → grupos no-NONE  
- `hidden_ability()` → `ability_hidden`

Si tenías código que leía `data.types` o `data.abilities` como propiedad, pásalo a los helpers o a los campos nuevos y **reimporta** los `.tres`.

## Cómo generar

1. Copia los scripts a tu proyecto.
2. Abre `tools/import_species_tres.gd`
3. **File → Run**
4. Consola: `import_species_tres: OK — N .tres …`

Repite el Run cada vez que regeneres `species.json`.

## API del catálogo

```gdscript
SpeciesCatalog.get_data(id) -> SpeciesData
SpeciesCatalog.get_display_name(id) -> String
SpeciesCatalog.get_national_dex(id) -> int
SpeciesCatalog.has_species(id) -> bool
SpeciesCatalog.preload_ids(ids: Array)
```

## Archivos

| Ruta | Rol |
|------|-----|
| `Scripts/Pokemon/species_data.gd` | Resource con grupos + enums sueltos |
| `Scripts/Pokemon/level_up_move.gd` | Entrada de learnset |
| `Scripts/Pokemon/species_paths_index.gd` | Índice de paths |
| `Scripts/Pokemon/species_catalog.gd` | Autoload runtime |
| `tools/import_species_tres.gd` | JSON → .tres + índice |
