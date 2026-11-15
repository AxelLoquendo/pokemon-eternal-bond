# Fixes de sprites (3)

## 1. Fallback de carpeta padre
Si falta `icon.png` (u otro archivo) en `pumpkaboo/super/`, se prueba `pumpkaboo/`.

## 2. Overrides de folder
En `PokemonSprites.FOLDER_OVERRIDES`:

- Squawkabilly blue/yellow/white → subcarpetas de color
- Deerling summer/autumn/winter → subcarpetas de estación
- Alcremie strawberry vanilla → `alcremie` (ya no `alcremie/gmax`)

## 3. Resolver Alcremie
Token `ALCREMIE_<SWEET>_<CREAM>`:

| Caso | Path típico |
|------|-------------|
| Strawberry + vanilla | `alcremie/front.png` |
| Strawberry + otra crema | `alcremie/<cream>/front.png` |
| Otro sweet + crema | `alcremie/<sweet>/front_<sweet>_<cream>.png` |
| Icon | casi siempre `alcremie/icon.png` |
| GMAX | `alcremie/gmax/` |

## Instalación
Sustituye `Scripts/Pokemon/pokemon_sprites.gd` por el de este paquete.
Opcional: en el sprite test, la línea de `dir:` usa `PokemonSprites.folder_for(id)`.

## Nota
Los overrides viven en runtime. Si más adelante regeneras `_SPRITE_FOLDER` en `species_id.gd`, conviene alinear esos valores ahí también para no depender solo del override.
