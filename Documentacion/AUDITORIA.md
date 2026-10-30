# Auditoría técnica

Revisión estática del proyecto realizada el 29 de octubre de 2026. Alcance: configuración de Godot, escenas, scripts de `Scripts/`, datos de mapas y documentación. No se ejecutó el proyecto ni una exportación; las conclusiones de ejecución requieren validación interactiva.

## Hallazgos

### Corregido — posición guardada no era local al mapa

`SaveService._capture()` ahora delega la conversión a celda local a `MapFactory.world_to_current_cell()`. Los nuevos archivos usan versión 2. La carga mantiene el tratamiento anterior para archivos v1 y rechaza versiones futuras no compatibles.

Referencias: `Scripts/Core/Save/save_service.gd`, `Scripts/Overworld/Map/map_factory.gd`, `Scripts/Overworld/Object_Event/Game/game_session.gd`.

### Corregido — rutas de audio con diferencias de mayúsculas

Los diccionarios de `Scripts/Overworld/Sfx/sfx_game.gd` usan ahora el mismo `Sfx/` que el directorio del proyecto. Aún falta probar la carga en un entorno sensible a mayúsculas.

### Media — comandos reconocidos por el parser pero no ejecutables

`ScriptTextParser.COMANDOS_VALIDOS` acepta `giveitem`, `checkitem` y `trainerbattle`; sin embargo, `_create()` en `ScriptCmdTextFile` no crea comandos para ellos y emite “comando no portado aún”. Un script con estas instrucciones puede parsearse sin error y la instrucción se omite tras la advertencia. Rechazarlas explícitamente durante la validación o implementar sus comandos antes de usarlas.

La lista se conserva intencionalmente para contenido futuro; se añadió un comentario para dejar claro que no se deben retirar por estar aún sin implementar.

### Baja — sistema de opciones incompleto

El menú principal muestra “Opciones”, pero `_on_options()` solo emite un aviso TODO. Comunicarlo como función pendiente o conectar una escena funcional.

### Corregido — versionado de guardado

Los nuevos guardados registran `version = 2`. `SaveService` conserva la carga de v1 (posición mundial heredada) y rechaza versiones futuras que todavía no entiende.

## Cobertura implementada observada

- Flujo de título, creación de personaje, sesión de overworld y menú de pausa.
- Mapas conectados, colisión por tiles, comportamientos (ledge, agua, hielo y escaleras), NPC, rutas y eventos de mapa.
- Intérprete de scripts con texto, choices, control de flujo, flags, variables, movimiento, clima, sonido, fade y warp; el conjunto ejecutable es menor que el reconocido por el parser.
- Guardado/carga de snapshot (`SaveData`) y tiempo de juego.
- Audio, clima, ciclo día/noche, cartel de ubicación y sistema de mensajes.
- No se encontraron sistemas de combate, party, mochila o Pokédex en el runtime inspeccionado.

## Correcciones posteriores

- El callback asíncrono de diálogo ahora deja que `ScriptRunner` limpie el estado de espera y avance el índice del comando. Antes la espera se limpiaba demasiado pronto y el runner repetía el primer texto.
- El jugador ahora se detiene mientras `MessageService` muestra un mensaje, incluido el ajuste a la casilla si un paso estaba en curso.

## Verificaciones pendientes

- Ejecutar el proyecto en Godot 4.7 y recorrer inicio, transición entre mapas, diálogos, eventos, guardado/carga y menú.
- Exportar o cargar recursos en un entorno sensible a mayúsculas para confirmar las rutas de audio.
- Añadir validación de coordenadas y casos de guardado en mapas conectados.
