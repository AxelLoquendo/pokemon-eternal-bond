# Datos de partida, catálogos y recursos Pokémon

Este documento separa los datos disponibles en código de las funciones jugables. Que exista `SpeciesData`, `PokemonInstance` o `BagService` no significa que haya combate o una interfaz de party/mochila.

## 1. Catálogos JSON

Los autoloads `SpeciesCatalog`, `ItemCatalog`, `AbilityCatalog` y `MoveCatalog` cargan sus archivos bajo `Datos/` y ofrecen consultas por ID/token. El flujo general es:

```text
JSON → lectura/indexación → get_*(id) → recurso tipado → caché
```

Los catálogos conservan un índice para evitar convertir todos los registros en recursos al inicio. Al pedir una entrada, convierten los campos del JSON en `SpeciesData`, `ItemData`, `AbilityData` o `MoveData` y guardan el objeto tipado en caché. `SpeciesCatalog` prepara el índice en un hilo y sincroniza solicitudes que requieren que termine.

Usa la API de catálogo en vez de cargar o parsear JSON directamente en escenas. Los enums generados (`SpeciesId`, `ItemId`, `AbilityId`, `MoveId`) son la forma estable de referenciar contenido en código; los tokens sirven para archivos y herramientas.

Ejemplo conceptual en GDScript:

```gdscript
var species: SpeciesData = SpeciesCatalog.get_data(SpeciesId.Id.BULBASAUR)
if species != null:
	print(species.name, species.base_stats)
```

Los nombres concretos de métodos/tipos deben seguir los scripts de cada catálogo si cambian; no convertir este ejemplo en una llamada distinta de la API del proyecto.

## 2. Recursos de especie y Pokémon

`SpeciesData` describe especie: tipos, estadísticas base, formas, evoluciones, movimientos por nivel/tutor/huevo, objetos que puede portar y banderas. `EvolutionData` y `FormChangeData` expresan condiciones/destinos como datos.

`PokemonInstance` guarda el estado de una criatura concreta: especie, nivel, habilidad/forma seleccionadas, género, tipo tera y HP. El constructor aplica valores iniciales y calcula HP máximo a partir de datos disponibles. No se encontró un runtime completo para experiencia, combate, captura, evolución durante juego ni gestión interactiva del equipo. `PlayerData.party` almacena instancias hasta seis entradas; esto es estructura de datos, no una pantalla de party.

`PokemonSprites` busca imágenes de forma diferida. La prioridad de búsqueda para sprite de batalla es variante hembra + shiny, hembra, shiny y base, según existan; los iconos usan `icon.png`. El resultado se cachea. La convención de rutas vive en el propio cargador: conserva la jerarquía existente de `Graficos/` al añadir arte.

## 3. Objetos e inventario

`ItemData` contiene atributos descriptivos/técnicos del objeto. El inventario de `PlayerData` se representa como cantidades por ID entero. `BagService` añade, quita y consulta cantidades, con tope de pila 999 para objetos normales y 1 para objetos clave/importantes.

Ejemplos de comportamiento disponible por script:

```text
giveitem POTION 3
checkitem POTION 2 tiene_dos
text "No tienes suficientes pociones."
goto fin
label tiene_dos
text "Tienes al menos dos pociones."
label fin
```

La primera línea añade tres unidades si el objeto y la cantidad son válidos. La segunda salta a `tiene_dos` cuando la cantidad disponible es mayor o igual a dos. El script usa IDs/tokens conocidos por el catálogo. Esto no implica que exista todavía una pantalla de mochila o uso de objetos fuera de los comandos implementados.

## 4. Guardados

`SaveService` persiste `SaveData` en `user://save_0.tres`. La instantánea reúne nombre/género del jugador, mapa activo, celda, nombre del mapa, tiempo jugado, `PlayerData`, dinero y flags. En la versión 2 la posición se guarda en coordenadas de celda local del mapa mediante `MapFactory.world_to_current_cell()`.

Al continuar: el menú pide `SaveService.load()`, `SaveData.to_start_data()` genera `GameStartData`, `SessionBoot` transporta los datos a `GameSession` y `MapFactory` carga mapa/posición. `SaveService` rechaza versiones futuras desconocidas. La revisión detectó que la versión 1 guardaba posición mundial pero no se convierte a local al cargar; ver [AUDITORIA.md](AUDITORIA.md) antes de migrar partidas antiguas.

## 5. Ajustes

`GameSettings` almacena la configuración en `user://settings.cfg`, aplica volumen en buses `Music` y `SFX`, y contiene velocidad de texto. El menú «Opciones» todavía no conecta una UI para editar estos valores. La configuración y la UI son etapas distintas.

## 6. Importación y generación

La carpeta `tools/` contiene importadores y utilidades para fuentes PBS/JSON, sprites y generación de recursos. `tools/json_to_species_tres.gd` y `tools/json_to_form_tres.gd` son scripts de conversión de datos; otros scripts Python importan o reorganizan contenido. Antes de correr un importador sobre datos existentes, inspecciona su entrada/salida y el formato que consume: algunos son utilidades editoriales y no se ejecutan como parte del juego.

## 7. Limitación de caché detectada

Los catálogos consumen entradas crudas al materializar el recurso y guardan el resultado en caché. `clear_cache()` puede borrar ese objeto tipado sin reconstruir la entrada cruda ya consumida. No llames a esa función como mecanismo de descarga y recarga hasta corregir/verificar su contrato; detalle en [AUDITORIA.md](AUDITORIA.md).
