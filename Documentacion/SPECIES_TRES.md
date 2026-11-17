# Especies = recursos `.tres` (sin JSON en el día a día)

## Idea

Cada especie/forma es un **SpeciesData** guardado como `.tres`.
Ahí van stats, moves, flags y **`sprite_folder`**.
Los gráficos se resuelven solo con esa ruta: no hay tablas de excepciones.

```
SpeciesData (BULBASAUR.tres)
  id, stats, moves, …
  sprite_folder = "bulbasaur"
       ↓
Graficos/Pokemon/bulbasaur/front.png
```

## Crear un mon o fakemon

1. FileSystem → `Datos/Pokemon/Resources/gen_X/` → New Resource → `SpeciesData`.
2. Rellena el Inspector (incluye **sprite_folder**).
3. PNG en `Graficos/Pokemon/<sprite_folder>/`.
4. Añade el id al enum `SpeciesId.Id` (mientras uses enum).
5. File → Run en `tools/rebuild_species_index.gd`.

## Corregir ruta de gráficos

Abre el `.tres` → **Graphics / sprite_folder** → guarda.
Sprite test → **R** (limpia caché de texturas).

## Migración desde JSON (una vez)

1. JSON con `sprite_folder` en cada ficha.
2. Run `tools/import_species_tres.gd`.
3. Después edita solo `.tres`. El JSON deja de ser el flujo activo.

## Qué ya no manda en runtime

- `species.json` diario
- `SpeciesId._SPRITE_FOLDER`
- `FOLDER_OVERRIDES` / listas de excepciones
