# Herramientas de creación y edición de mapas

El proyecto incluye dos plugins de editor: `addons/map_creator` para registrar un mapa nuevo y `addons/map_editor` para facilitar cambios en mapas existentes. Se activan desde Plugins en Godot. Son herramientas de desarrollo, no nodos necesarios en el juego exportado.

## 1. Crear un mapa

El plugin Map Creator agrega la acción **Crear nuevo mapa**. El flujo crea una escena a partir de `map_base.tscn`, pide una ruta de guardado y registra el identificador de mapa en `MapSection` y su escena en el diccionario de escenas. Después recompila las clases globales y abre la escena nueva.

Secuencia recomendada:

1. Crear el mapa desde el plugin y asignar un ID único con el prefijo de sección usado por el proyecto (`MAPSEC_...`).
2. Guardar la escena en la carpeta apropiada de `Escenas/`.
3. Revisar `MapSection` y confirmar que el ID apunta a la ruta exacta de la escena. El plugin modifica código de registro; inspecciona el diff para confirmar que no duplicó ni reemplazó una entrada.
4. Configurar `MapAttributes`: nombre, tamaño en celdas, música, clima, conexiones, tipo/estilo del rótulo e indicadores de interior/exterior.
5. Construir bordes y conexiones, ubicar eventos, NPC y jugador inicial cuando corresponda, y configurar custom data de tiles.
6. Guardar y revisar la escena antes de usarla como destino de warp.

Las coordenadas de eventos y posiciones de inicio son celdas locales al mapa. Para conexiones, el `MapFactory` traduce entre el origen local de cada mapa y el espacio mundial del cluster.

## 2. Editor de mapas

El plugin Map Editor añade utilidades sobre la escena abierta. Puede arrastrar `Player`/NPC seleccionados, ajustar sus posiciones a una grilla de 16 px y limitar el resultado a los límites del mapa. El pintado de tiles comprueba límites y recorta celdas de las capas de visualización y de comportamiento/colisión, excluyendo la capa de borde.

Flujo de uso seguro:

1. Abre la escena de mapa correcta y confirma que está guardada o que conoces los cambios pendientes.
2. Selecciona el actor que vas a mover y usa el arrastre/snap del plugin; la coordenada final se ajusta a la celda.
3. Al pintar, trabaja dentro del tamaño definido en `MapAttributes`. El plugin evita algunas escrituras fuera de límites, pero revisa la escena porque puede marcar cambios que debas guardar.
4. Guarda la escena y comprueba las capas relevantes en el inspector.

El plugin no valida semánticamente un evento, un warp, un flag, el sentido de una escalera o que su destino exista. Esa verificación corresponde a quien edita el mapa.

## 3. Datos de tile y comportamientos

Los gráficos no determinan automáticamente el comportamiento. En el TileSet se asignan custom data layers para colisión/altura y para comportamiento. El lector de reglas busca la clave entera `comportamiento`; consulta [Sistema_Mapa_y_Colision.md](Sistema_Mapa_y_Colision.md) para IDs y regla de lectura. No cambies el tipo de la capa ni el valor numérico sin actualizar `TileBehaviorId` y el lector.

Para una escalera lateral derecha actual, por ejemplo, el TileSet usa `STAIRS_RIGHT_UPPER` (11) en la celda superior y `STAIRS_RIGHT_LOWER` (10) en la inferior. Ambos IDs pertenecen a una regla de movimiento diagonal; la dirección del desplazamiento se obtiene de la pareja/posición del tile, no solo del nombre gráfico.

## 4. Eventos de mapa

Los `MapEvent` son nodos hijos del mapa y se posicionan en la cuadrícula. `WARP` se procesa al pisar; `COORD` lanza un script al pisar; `BG` se consulta frente al jugador al pulsar A. Usa IDs de mapa y warp existentes, y comprueba el fallback de llegada. Las condiciones de eventos usan actualmente un espacio de flags textual separado del esquema entero de los comandos de script; no asumas que ambos comparten bandera aunque el nombre visible coincida. Detalle en [AUDITORIA.md](AUDITORIA.md).

## 5. Revisión manual antes de integrar un mapa

- ID y escena registrados una sola vez en `MapSection`.
- `map_size` coincide con las celdas pintadas y los límites.
- Conexiones cardinales concuerdan con los tamaños y desplazamientos de ambos mapas.
- Tiles sólidos, altura, puentes, comportamiento y capas visuales alineados.
- Escaleras: upper/lower en las celdas esperadas y salidas libres en ambos extremos.
- Eventos locales: kind, destino, ID de warp, coordenada fallback, condición y script.
- NPC y objetos están dentro del mapa y tienen recursos/archivos válidos.
- Guardar la escena y revisar el diff de cualquier registro de código generado.
