# Mapa, cluster, colisión y eventos de casilla

## 1. Piezas

| Clase | Papel |
|---|---|
| `Map` | Escena de un mapa: tiles, `MapAttributes`, borde, eventos |
| `MapAttributes` | Metadatos exportados (id, nombre, música, clima, conexiones, location_*) |
| `MapFactory` | Cluster continuo: actual + vecinos |
| `MapManager` | Un solo mapa (indoor / API alternativa) |
| `MapCollisionSystem` | Capas de colisión activas del cluster |
| `CollisionFacade` | Un paso → `MoveStepResult` |
| `MapEvent` | Evento de casilla (WARP / COORD / BG) |
| `MapEventResolver` | Evalúa eventos al pisar o al pulsar A |

## 2. Cluster

`MapFactory.load_cluster(map_id, cell, player)`:

1. Descarga el cluster anterior (el player se reparenta fuera antes).
2. Instancia el mapa central y los vecinos según `MapConnectionEntry`.
3. Registra colisión de todo el cluster.
4. Coloca al player en la celda (espacio del mapa) y emite `cluster_loaded`.

`update_current_from_player` detecta si la posición mundial cayó en un vecino; si sí, promueve ese mapa a actual (`current_changed`) y refresca vecinos. `reparent_player_keep_global` conserva la posición mundial.

## 3. Warp

Dos entradas equivalentes en efecto de carga:

1. **Script** `warp MAP_ID x y [dir]` → `ScriptCmdWarp` → fade → `load_cluster` → orientación opcional → fade in. El runner se reparenta a `MapFactory` para no morir con el NPC.
2. **MapEvent WARP** → `MapEventResolver` → mismo `FadeScreen` + `load_cluster`, llegada por `dest_warp_id` o `dest_tile_fallback`.

## 4. Eventos de casilla (`MapEvent`)

`Marker2D` con snap 16×16 en editor. Grupo `map_events`.

| Kind | Cuándo | Qué |
|---|---|---|
| `WARP` | Pisar | Transfer al `dest_map` / `dest_warp_id` |
| `COORD` | Pisar | Script si `condition_ok()` |
| `BG` | A frente a la casilla | Script (cartel); `HIDDEN_ITEM` marca flag si aplica |

Condición: `condition_flag` vacío = siempre; si no, compara `ScriptExecutionContext.global_flags` con `expected_value`.

Cableado:

- Tras cada paso del player: `MapEventResolver.try_step(player, map_factory)`.
- Al pulsar A: `try_interact` antes de buscar NPC.

## 5. Consulta de un paso

`CollisionFacade.resolve_move(controller, direction)` → `MoveStepResult` (`blocked`, `target_world`, `hop`, `behavior_world`).

Orden: entidad y después tile. `EntityCollisionSystem` ocupa casillas de actores. `MapCollisionSystem` lee custom data del tile (`no_block`, altura, puente).

## 6. Comportamientos de tile

`TileBehaviorReader` lee el custom data entero `comportamiento` de las capas visuales, de arriba abajo. El valor se debe asignar en los tiles del TileSet; los gráficos no se clasifican automáticamente.

| Comportamiento | Regla al caminar |
|---|---|
| `LEDGE_*` | Salta una casilla y aterriza en la siguiente solo en la dirección de la caída; no permite cruzarlo lateralmente ni volver hacia arriba. |
| `WATER` | Bloquea el paso. No hay Surf implementado, así que no se permite caminar sobre el agua. |
| `ICE` | Al aterrizar conserva la dirección y desliza hasta salir del hielo o chocar. El choque detiene el deslizamiento. |
| `STAIRS_RIGHT_LOWER/UPPER`, `STAIRS_LEFT_LOWER/UPPER` | Cada tramo lateral usa dos marcas: `LOWER` va en la casilla inferior y sube una casilla en Y al avanzar en X; `UPPER` va en la casilla superior y baja al recorrerla en sentido contrario. La transición es diagonal y reversible; si se cambia de sentido durante el traslado, inicia el regreso al aterrizar. También se puede caminar verticalmente entre ambas casillas sin activar otra diagonal, y salir desde los extremos. |
| `TALL_GRASS` | Transitable; cada aterrizaje emite `CharacterController.tile_behavior_landed(TALL_GRASS)` como punto de integración para hierba/encuentros. El runtime aún no tiene encuentros aleatorios ni efecto visual de hierba. |
| `SAND` | Transitable y emite el mismo evento al aterrizar; puede usarse para pasos/efectos. |

`CollisionFacade` valida el destino antes de empezar. `CharacterController` llama los hooks de inicio y aterrizaje; el aterrizaje aplica primero el estado de altura y luego notifica el comportamiento. Los movimientos forzados por hielo se procesan dentro del controlador y no se confunden con un paso manual de una ruta.

En `Outside.tres`, la escalera lateral derecha asigna `STAIRS_RIGHT_UPPER` al atlas `(18,12)` (casilla superior) y `STAIRS_RIGHT_LOWER` al `(18,13)` (casilla inferior). Los cuatro comportamientos están implementados; los dos de la izquierda quedan disponibles para cuando se marque su tramo correspondiente en el TileSet.

Los valores corresponden a `TileBehaviorId.Id` (`NONE=0`, `LEDGE_DOWN=1`, `LEDGE_UP=2`, `LEDGE_LEFT=3`, `LEDGE_RIGHT=4`, `STAIRS_RIGHT_LOWER=10`, `STAIRS_RIGHT_UPPER=11`, `STAIRS_LEFT_LOWER=12`, `STAIRS_LEFT_UPPER=13`, `TALL_GRASS=20`, `ICE=21`, `SAND=22`, `WATER=23`).

## 7. Borde

`MapBorderController` pinta el patrón infinito fuera de `map_size` y de los rectángulos conectados, según la cámara.

## 8. Preview de editor

Con `Engine.is_editor_hint()`, los vecinos de preview se instancian sin runtime (sin música, clima, eventos activos).

## 9. Y-sort

Player y NPC cuelgan de `EventObject`. El `z_index` de puente es ortogonal al orden Y.
