# Auditoría técnica del proyecto

**Fecha:** 7 de noviembre de 2026
**Tipo:** revisión estática de configuración, scripts, escenas, datos y documentación.
**Ejecución:** no se abrió el juego ni se ejecutó Godot/exportación durante esta revisión; los hallazgos describen rutas observables en el código y requieren verificación interactiva cuando dependan del comportamiento visual.

## Alcance y método

Se revisó `project.godot`, los scripts bajo `Scripts/`, documentación previa, estructura de datos y addons de mapas. Se siguieron recorridos de arranque, movimiento, mapa/eventos, scripts, mensajes, guardado, catálogos y presentación. Esta auditoría no cambia el comportamiento del juego: las correcciones de código, si se desean, deben tratarse por separado. No se retiraron contratos o comandos preparados para uso futuro.

## Hallazgos priorizados

### Alta — carga de guardados versión 1 no convierte la coordenada histórica

`SaveService` escribe versión 2 y captura `position` como celda local mediante `MapFactory.world_to_current_cell()`. El propio comentario del código indica que los archivos versión 1 guardaban una posición mundial. `SaveService.load()` rechaza versiones mayores a la actual, pero `SaveData.to_start_data()` asigna `save.position` directamente a `GameStartData.start_position` sin convertir coordenadas de versión 1. Por ello, un guardado antiguo hecho en un mapa con origen mundial distinto de cero puede reanudar en una celda incorrecta. Los guardados nuevos en v2 usan el formato local. Recomendación: migrar al leer v1 usando el origen del mapa guardado, o rechazarlo con mensaje claro si ya no se puede reconstruir; preservar el archivo de origen durante la migración.

### Media — flags de eventos de mapa no comparten necesariamente el mismo espacio de nombres

Los flags de scripts se resuelven mediante `GameFlags.from_token()` y se almacenan en `ScriptExecutionContext.global_flags` con claves enteras. `MapScriptEntry` sigue ese mismo esquema. En cambio, `MapEvent.condition_ok()` consulta su `condition_flag` como `StringName`, y los objetos ocultos escriben una clave textual. Un flag llamado igual puede por tanto no ser el mismo flag para el script y el evento. Documentar/normalizar el contrato o adaptar una de las rutas antes de depender de condiciones compartidas entre eventos y scripts.

### Media — limpiar caché del catálogo puede perder entradas ya materializadas

Los catálogos de especies, objetos, habilidades y movimientos indexan datos crudos y los consumen al construir el recurso tipado; el recurso queda en caché. `clear_cache()` vacía la caché tipada, pero las entradas crudas ya consumidas no están disponibles para volver a materializar. Una petición posterior de esa entrada puede devolver `null` hasta reconstruir/recargar el índice (la API no es uniforme entre catálogos). Evitar usar esa operación como descarga/reinicio general sin reparar la estrategia de retención.

### Media — opciones visibles, pantalla de ajustes pendiente

El menú principal ofrece «Opciones», pero el callback actual solo avisa que no está implementado. `GameSettings` sí carga y persiste configuración de texto y buses de audio en `user://settings.cfg`; la UI no permite editar todos esos ajustes actualmente. No presentar el menú como funcional hasta conectar una pantalla.

### Baja — el disparador `ON_FRAME` está declarado, sin despachador observado

`MapScriptEntry.Trigger` incluye `ON_FRAME`; las llamadas observadas a `MapScriptService` despachan carga y transición. No se encontró un bucle que ejecute scripts `ON_FRAME`. Mantener el valor como contrato preparado, pero no usarlo esperando ejecución periódica.

### Baja — dos definiciones de tarde en el ciclo día/noche

La clasificación de períodos define `EVENING` desde las 18:00; el helper `is_evening()` considera tarde desde las 17:00. Código que use el helper puede discrepar del tono aplicado por `period_for_hour()` durante esa hora.

### Baja — cargador `MapManager` alternativo

El camino principal del juego usa `MapFactory`. `MapManager` mantiene una ruta de mapa único, y la colocación de su jugador usa `Vector2(cell) * 16` sin aplicar un origen mundial de cluster. No asumir equivalencia en mapas conectados o escenas cuyo mapa tenga origen distinto de cero.

## Funciones preparadas o parciales

- `trainerbattle` es token aceptado por el parser, pero el conversor no produce un comando ejecutable todavía.
- `giveitem` y `checkitem` sí se convierten y ejecutan: dan objeto/ramifican según cantidad.
- `specials SAVE_GAME` es la ruta de guardado disponible desde script; `savegame` no es un token admitido.
- Estados como `SLIP`, `FISHING`, `BIKE`, `BATTLE`, `SURF` y `DIVE` están declarados, pero no equivalen por sí solos a sistemas jugables completos.
- Hay recursos y modelos de datos de Pokémon, party e inventario; eso no demuestra que existan combate ni las pantallas de equipo/mochila.
- El clima, la presentación de mensajes, el ciclo día/noche y audio tienen rutas funcionales en el runtime, pero no se validaron visualmente en esta revisión.

## Documentación corregida en esta revisión

La documentación previa afirmaba incorrectamente que `giveitem` y `checkitem` no estaban portados y que la carga de v1 conservaba correctamente su posición histórica. Los documentos actualizados describen el recorrido real, las firmas de uso, los límites y los hallazgos anteriores. Véase el índice en [README.md](README.md).

## Límites y siguiente verificación

La revisión es estática. Para cerrar los hallazgos de ejecución, iniciar Godot 4.7 y comprobar de forma controlada: continuar un guardado v1 en mapa conectado, bandera compartida evento/script, reconstrucción de catálogos tras limpiar caché, selección de Opciones, cruce de mapas y pasos de escalera con cambio de dirección. Esto es una lista sugerida de verificación, no una afirmación de que esos escenarios se hayan ejecutado.
