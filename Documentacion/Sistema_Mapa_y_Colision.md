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
4. Coloca al player en la celda (espacio del mapa), inicializa altura y emite `cluster_loaded`.

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

Condición: `condition_flag` vacío = siempre; si no, compara `ScriptExecutionContext.global_flags` con `expected_value`. Las condiciones de `MapEvent` consultan claves `StringName`, mientras los comandos de script usan IDs enteros de `GameFlags`; no asumir que son la misma bandera (ver auditoría).

Cableado:

- Tras cada paso del player: `MapEventResolver.try_step(player, map_factory)`.
- Al pulsar A: `try_interact` antes de buscar NPC. BG puede mostrar su script/cartel o registrar que se recogió un objeto oculto; ese flujo de objeto oculto actualmente solo registra flag y no suma una unidad al inventario.

## 5. Consulta de un paso

`CollisionFacade.resolve_move(controller, direction)` → `MoveStepResult` (`blocked`, `target_world`, `hop`, `behavior_world`).

Orden: entidad y después mapa/tile. `EntityCollisionSystem` comprueba actores en el destino. `MapCollisionSystem` localiza el mapa registrado que contiene la posición y lee su capa `Behaviour/Collision`. El tile usa custom data booleano `bloqueo`, booleano `cambiar_nivel_altura`, entero `nivel_altura` y booleano `no_block`. Después se comprueba la altura y se pregunta al handler del comportamiento.

La consulta se expresa en coordenadas mundiales: cada lector convierte la posición con `TileMapLayer.to_local()` y luego `local_to_map()`. La posición se considera dentro del mapa según `MapAttributes.map_size` y el origen global del nodo `Map`. Una celda sin tile/capa registrada da datos vacíos; custom data no configurado se lee como falso/cero. La capa debe llamarse exactamente `Behaviour/Collision` para registrar colisión.

`CollisionFacade.resolve_move()` calcula un `MoveStepResult`, no mueve al actor. Primero intenta resolver la transición especial de escalera; luego comprueba si el tile de un paso inicia salto de ledge; en otro caso propone el destino de una celda. `is_blocked()` combina ocupación de entidad y legalidad de tile. El controlador consume el resultado, anima y al aterrizar actualiza nivel/altura antes de notificar el comportamiento.

## 6. Comportamientos de tile

`TileBehaviorReader` lee el custom data entero `comportamiento` de las capas visuales, recorriéndolas desde la última hija a la primera; gana el primer valor distinto de `NONE`. El valor se debe asignar en los tiles del TileSet; los gráficos no se clasifican automáticamente. Si falta la capa de custom data o su valor no es número, devuelve `NONE`. Esta capa es distinta de `Behaviour/Collision`.

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
