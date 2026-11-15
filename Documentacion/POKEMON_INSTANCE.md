# PokemonInstance — limpieza post SpeciesData

## Qué se rompía

Con el layout nuevo de `SpeciesData`:

- `data.types` y `data.abilities` **ya no son propiedades** (son métodos o campos sueltos).
- `create()` hacía `data.abilities[0]` / `data.types[0]` → error en runtime.

## Cambios

| Tema | Antes | Ahora |
|------|--------|--------|
| Habilidad al crear | `abilities[0]` | `ability_slot` 0/1 + `resolve_ability_from_species()` |
| Tera type | `types[0]` | `type_1` / `force_tera_type` |
| Stats | Solo max HP ad-hoc | `get_stat()` con IVs, EVs, naturaleza |
| Learnset | No asignaba moves | `apply_level_up_moves_up_to_level()` desde `LevelUpMove` |
| IVs | 0 | Aleatorios 0–31 en `create()` |
| Naturaleza | HARDY fijo | Aleatoria |

## API útil

```gdscript
var mon := PokemonInstance.create(SpeciesId.Id.BULBASAUR, 5)
mon.display_name()
mon.get_stat(PokemonEnums.Stat.ATK)
mon.types()          # delega a SpeciesData.types()
mon.heal_full()
mon.set_moves([MoveId.Id.TACKLE, MoveId.Id.GROWL])
```

## Compatibilidad de código

Busca en el proyecto usos de:

- `data.types` → `data.type_1` / `data.type_2` o `data.types()`
- `data.abilities` → `data.ability_1` / `data.ability_2` / `data.ability_hidden` o `data.abilities()`
- `data.egg_groups` → `data.egg_group_1` / `data.egg_group_2` o `data.egg_groups()`
- `level_moves` como Dictionary → `LevelUpMove.level` / `LevelUpMove.move`

## Siguiente limpieza opcional

1. Exp por nivel según `growth_rate` (tabla de experiencia).
2. `PlayerData` starter al new game (Kael/Kaida + Pokémon inicial).
3. Mismo patrón `.tres` para moves/items si el boot sigue pesado.
