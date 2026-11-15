# Documentación de Pokémon Eternal Bond

Manual de referencia del estado observado del proyecto. Las guías explican código, recorrido y uso; la auditoría separa defectos encontrados de funciones incompletas o reservadas para futuro. Las rutas de archivos dentro de los documentos son relativas a la raíz del repositorio.

## Índice

- [Arquitectura y recorrido](ARQUITECTURA.md): regla dorada, capas, arranque, sesión, movimiento y límites.
- [Auditoría técnica](AUDITORIA.md): alcance, hallazgos priorizados y limitaciones de verificación.
- [Personaje, movimiento y NPC](Sistema_Character.md): control por casillas, estados, input, rutas e interacción.
- [Mapa, cluster, colisión y eventos](Sistema_Mapa_y_Colision.md): coordenadas, conexiones, colisión, comportamientos y eventos.
- [Sistema de scripts](Sistema_Scripts.md): gramática real, comandos convertidos, flujo asíncrono, ejemplos y tokens reservados.
- [Sistema de mensajes](Sistema_Mensajes.md): API de mensajes, ventanas, choices, hablante y sincronización con el juego.
- [Presentación](Sistema_Presentacion.md): audio, fade, clima, día/noche y cartel de ubicación.
- [Datos y catálogos](Sistema_Datos.md): especies, Pokémon, objetos, inventario, guardados, ajustes y herramientas de datos.
- [Herramientas de mapas](Herramientas_Mapas.md): plugins de creación/edición, custom data y lista de revisión.

## Cómo interpretar el estado

- **Implementado:** hay ruta de código para usar la función. No significa que esta revisión haya jugado/validado su aspecto visual.
- **Parcial:** existe estructura o parte del recorrido, pero faltan etapas explícitas.
- **Preparado/futuro:** se conserva un enum, token, modelo o extensión para contenido posterior. No usar como función terminada ni eliminarlo como limpieza sin revisar sus referencias.

La regla dorada es que las reglas calculan resultados, los controladores aplican movimiento/presentación y la sesión coordina mediante APIs y señales. Consultar [Arquitectura](ARQUITECTURA.md) antes de incorporar un sistema transversal.
