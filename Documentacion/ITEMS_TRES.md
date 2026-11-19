# Ítems = recursos `.tres`

## Modelo

```
ItemData (POKE_BALL.tres)
  id, name, pocket, price, effects…
  icon_name = "poke_ball"
       ↓
Graficos/Items/icons/poke_ball.png
```

## Primera vez (migración)

1. Copia los scripts de este zip.
2. Asegúrate de tener `Datos/Items/items.json` y los iconos en `Graficos/Items/icons/`.
3. Godot → `tools/import_items_tres.gd` → **File → Run**.
4. Comprueba `Datos/Items/Resources/` y `item_paths.res`.
5. El JSON ya no se usa en runtime (puedes archivarlo).

## Día a día

- Editar ficha → abrir el `.tres` en el Inspector.
- Nuevo ítem → New Resource `ItemData` + PNG del icono + valor en `ItemId`.
- Tras crear/borrar → `tools/rebuild_items_index.gd` → Run.

## Runtime

`ItemCatalog` solo carga el índice ligero al arrancar.
`get_item(id)` / `get_icon(id)` cargan el `.tres` y el PNG bajo demanda.
