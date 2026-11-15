# Arquitectura y recorrido del proyecto

Esta guía describe el código existente de Pokémon Eternal Bond. Está escrita para Godot 4.7, GDScript y una vista de juego de 480×320 con tiles de 16×16. Las rutas indicadas son relativas a la raíz del proyecto. «Implementado» significa que hay un recorrido de código utilizable; no implica que se haya validado jugando en esta revisión. Los sistemas marcados como preparados o parciales no deben tratarse como terminados.

## 1. Regla de arquitectura

La regla dorada del proyecto es separar decisión, aplicación y coordinación:

1. **Decidir:** una regla recibe datos y calcula el resultado. Ejemplo: `CollisionFacade.resolve_move()` devuelve un `MoveStepResult` con destino, bloqueo y si es salto/transición.
2. **Aplicar:** un controlador lleva a escena el resultado recibido. Ejemplo: `CharacterController` interpola la posición y emite señales de inicio y fin de paso.
3. **Coordinar:** una sesión conecta sistemas y ordena el flujo. Ejemplo: `GameSession` carga el mapa y conecta `movement_finished` con promoción de mapa y resolución de eventos.

La presentación no debe volver a decidir reglas de colisión. La colisión no debe crear ventanas o reproducir animaciones. Las señales y los objetos de resultado son los límites principales entre estos trabajos. Al modificar una funcionalidad, seguir el recorrido de extremo a extremo y conservar estos límites.

## 2. Capas observadas

| Capa | Carpetas y piezas | Responsabilidad |
|---|---|---|
| Inicio y sesión | `Scripts/Core/Boot`, `Scripts/Core/Save`, `Scripts/Overworld/Object_Event/Game` | Título, nueva partida, carga, raíz de sesión y tiempo jugado. |
| Reglas de overworld | `Scripts/Overworld/Map/Collision`, `Behaviour`, `Event`, `Scripts/Overworld/Object_Event/Movement` | Legalidad de pasos, tiles especiales, eventos y rutas. |
| Actores | `Scripts/Overworld/Object_Event/Character`, `Player`, `Npc` | Entrada, estados, movimiento, animación e interacción. |
| Interpretación | `Scripts/Core/Scripting` | Parseo de archivos de evento, contexto, flujo y comandos. |
| Presentación | `Scripts/Core/Message`, `Fade`, `Weather`, `DayNight`, `Scripts/Overworld/Sfx` | Mensajes, transiciones, clima, iluminación y sonido. |
| Datos de juego | `Scripts/Pokemon`, `Scripts/Item`, `Scripts/Moves`, `Scripts/Abilities`, `Datos` | Recursos tipados y catálogos cargados desde JSON. |
| Edición | `addons/map_creator`, `addons/map_editor` | Creación de escenas de mapa y edición asistida del mapa. |

Los autoloads se declaran en `project.godot`. Entre ellos están `MessageService`, `FadeScreen`, `MusicManager`, `WeatherManager`, `GameSettings`, `SaveService`, `SessionBoot`, `MapCloud` y catálogos de especies, objetos, habilidades y movimientos. Un autoload es un servicio de alcance global de la sesión; no reemplaza la responsabilidad de los sistemas que lo llaman.

## 3. Arranque y nueva partida

Recorrido normal:

```text
TitleScreen → MainMenu → (Continue | New Game)
                         Continue → SaveService → SessionBoot → GameSession
                         New Game → NewGameState → GenderSelect → Naming → GameSession
```

- `TitleConfig` centraliza escenas y tiempos del título. La pantalla de título reproduce música, espera aceptar/iniciar y cambia de escena con `FadeScreen`.
- `MainMenu` consulta `SaveService.has_save()`. Sin archivo, Continue aparece deshabilitado y el cursor inicia en New Game. Continue convierte el `SaveData` en `GameStartData`, lo entrega a `SessionBoot` y abre la sesión. New Game limpia el estado temporal y conduce a selección de género y nombre.
- `GenderSelect` guarda el género y la apariencia. `Naming` recorta espacios, limita el nombre a siete caracteres y construye `PlayerData` con velocidades iniciales (caminar 4, correr 8) y dinero cero. El mapa y posición se completan con los valores por defecto de `GameStartData`.
- El menú de opciones aparece en el menú principal, pero su callback es un TODO: `GameSettings` sí existe, aunque esa pantalla no ofrece todavía edición de ajustes.

## 4. Inicialización de `GameSession`

`Scripts/Overworld/Object_Event/Game/game_session.gd` es el orquestador de la partida. En `_ready()` prepara los nodos de presentación requeridos (UI de mensajes, overlay día/noche y cartel de ubicación), recibe los datos de `SessionBoot`, aplica datos del jugador, conecta las señales de `MapFactory` y carga el cluster de inicio. Si faltan los datos de inicio, el jugador o el cargador requerido, la sesión no puede completar la inicialización.

Tras cargar el mapa conecta el fin de movimiento del jugador. Cada paso terminado actualiza cuál mapa del cluster es el actual y entrega el paso a `MapEventResolver.try_step()`. Cuando cambia el mapa activo, la sesión actualiza clima, ciclo de iluminación y anuncio del nombre. Los scripts de mapa reciben los disparadores de carga/transición. El contador de tiempo jugado deja de incrementarse mientras hay un mensaje o el menú de pausa está abierto.

## 5. Recorrido de movimiento

```text
input / MoveRoute
  → CharacterController
  → CollisionFacade.resolve_move()
  → MoveStepResult
  → movimiento + señales
  → GameSession actualiza mapa y eventos
```

`Player` convierte la entrada en dirección salvo que esté bloqueado por diálogo, menú o script. Un NPC puede obtener dirección de su comportamiento o de `MoveRouteController`. El controlador solicita una decisión a `CollisionFacade`; ésta consulta actores, mapa, alturas y comportamiento del tile. Si el paso está libre, el controlador inicia la traslación interpolada y notifica al controlador animado; al terminar emite `movement_finished`. Este orden impide que la animación decida si el paso era legal.

Para un paso normal, el destino es una celda. Un salto de borde puede desplazar dos celdas y aplicar elevación visual. Las escaleras laterales pueden resolver una transición diagonal como una sola operación; el estado `STAIRS` suprime la animación de pasos encadenados durante esa transición y permite continuar el movimiento hacia el extremo. El documento [Sistema_Character.md](Sistema_Character.md) describe estados e interacción, y [Sistema_Mapa_y_Colision.md](Sistema_Mapa_y_Colision.md) la decisión de colisión.

## 6. Mapas y coordenadas

El juego usa `MapFactory` para mantener el mapa actual y vecinos conectados en un cluster. Las celdas son locales al mapa; posiciones de nodos y límites del cluster se expresan en coordenadas del mundo. Un tile mide 16 píxeles. `MapConnectionResolver` calcula el origen de cada vecino usando el tamaño de los mapas y el desplazamiento de conexión. Al cruzar un borde, `MapFactory` promueve el vecino a actual y reparenta al jugador preservando su posición mundial.

`MapManager` es un cargador alternativo/legado para un mapa individual; el flujo de juego, warps y mapas conectados pasan por `MapFactory`. No sustituir una ruta por la otra sin revisar las diferencias de coordenadas y estructura de nodos. Véase [Sistema_Mapa_y_Colision.md](Sistema_Mapa_y_Colision.md).

## 7. Scripts y eventos

Los archivos `.txt` no ejecutan GDScript ni Ruby. `ScriptTextParser` tokeniza líneas, `ScriptCmdTextFile` las convierte en objetos `ScriptCommand` y `ScriptRunner` ejecuta los comandos en orden. Los comandos que esperan una señal detienen el runner y reanudan desde el callback asíncrono. Un NPC origina su runner como hijo; un warp lo reubica bajo `MapFactory` antes de descargar el mapa para que el intérprete sobreviva.

Los eventos `COORD` y `WARP` se revisan al completar el movimiento; `BG` se revisa al interactuar frente al jugador antes de probar un NPC. `MapScriptService` ejecuta scripts asociados a carga y transición. Consulte [Sistema_Scripts.md](Sistema_Scripts.md) para gramática, sintaxis soportada, ejemplos y límites.

## 8. Datos y estado de juego

Los catálogos de especies, objetos, movimientos y habilidades leen los JSON bajo `Datos/` y materializan recursos tipados al pedir una entrada. `PokemonInstance` y `PlayerData` representan datos de una criatura y del jugador; su existencia no significa que haya batalla, pantalla de equipo o mochila jugable. El estado de inventario es una colección de cantidades en `PlayerData` y se opera con `BagService`.

`SaveService` guarda una instantánea en `user://save_0.tres`: jugador, mapa, posición, tiempo jugado, dinero, datos del jugador y flags de script. `GameSettings` escribe ajustes en `user://settings.cfg`. Los detalles, incluyendo el problema de migración histórica observado en la auditoría, están en [Sistema_Datos.md](Sistema_Datos.md) y [AUDITORIA.md](AUDITORIA.md).

## 9. Criterio al cambiar el proyecto

Antes de editar, identifica la entrada, el dueño de la decisión, quién aplica el resultado y la señal que conecta el siguiente paso. Conserva enums y tokens que sean contratos de contenido aunque una función esté pendiente: documenta su estado y no los elimines como limpieza. Al añadir un comando de script, actualiza parser, conversor, comando, espera/reanudación si aplica y esta documentación. Al añadir comportamiento de tile, actualiza ID, lector, regla, resolución del paso y los datos del TileSet.
