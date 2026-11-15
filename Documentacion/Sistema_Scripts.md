# Sistema de scripts de eventos

Los scripts `.txt` son una pequeña secuencia de instrucciones del juego. No ejecutan GDScript, Ruby ni sintaxis completa de pokeemerald. La única gramática disponible es la que implementan `ScriptTextParser` y `ScriptCmdTextFile`.

## 1. Del archivo al efecto

```text
archivo .txt
  → ScriptTextParser.load_script_file / parse_script
  → [{command, args, line}, ...]
  → ScriptCmdTextFile._convert
  → Array[ScriptCommand]
  → ScriptRunner.start_script
  → comando / espera asíncrona / siguiente comando
```

1. **Parser (`Scripts/Core/Scripting/script_text_parser.gd`).** Divide por líneas, recorta espacios y omite líneas vacías o cuyo primer carácter significativo sea `#` o `//`. Separa el nombre del comando, lo pasa a minúsculas y tokeniza argumentos por espacios fuera de comillas. Las comillas se eliminan. No hay escape de comillas ni continuaciones de línea; comillas sin pareja producen error de parseo. Un comentario al final de una instrucción no tiene una regla especial: no se debe usar como comentario inline.
2. **Conversor (`script_cmd_text_file.gd`).** Convierte cada token reconocido a un objeto de comando con referencias a contexto. Varias líneas consecutivas de `text "..."` se agrupan en páginas de texto. Un comando `msgbox` explícito mantiene su propia configuración. Comandos que el parser conoce, pero el conversor no crea, se advierten y se omiten.
3. **Runner (`script_runner.gd`).** Ejecuta secuencialmente. Saltos cambian el índice; etiquetas se resuelven antes de ejecutar. Comandos inline se expanden en el flujo. Un comando completado incrementa el índice; uno asíncrono deja `context.is_waiting` activo y detiene el avance.
4. **Reanudación.** Al terminar una espera, `complete_async()` notifica al runner, que limpia la espera, avanza exactamente una posición y continúa. Un comando asíncrono no debe avanzar por su cuenta y además llamar a `complete_async`, porque saltaría una instrucción.

El contexto (`ScriptExecutionContext`) incluye jugador, NPC/evento asociado, mapa/host, variables locales, `last_choice`, runner y almacenamiento estático de flags globales. `setvar`/`addvar` son locales a esa ejecución; los flags usan `GameFlags` y sobreviven entre runners dentro de la sesión. La persistencia de flags se incluye en `SaveData`.

## 2. Dónde comienzan los scripts

- **NPC:** `NPCData.script_file` → el controlador bloquea interacción/pausa ruta → crea runner → al finalizar reanuda comportamiento y libera runner.
- **Evento COORD:** `MapEventResolver.try_step()` lo evalúa al completar el paso y ejecuta su archivo si la condición coincide.
- **Evento BG:** al pulsar A, `try_interact()` inspecciona el evento en la casilla frontal antes de buscar NPC. Un evento de objeto oculto solo marca su flag actualmente; no concede el objeto automáticamente.
- **Script de mapa:** `MapScriptService` despacha entradas de carga/transición. Aunque el enum declare `ON_FRAME`, no se observó un despachador periódico para ese valor.

Durante `warp`, el runner se reparenta a `MapFactory` antes de descargar el mapa de origen para que no se destruya junto con el NPC/evento. No todo dato local al mapa sobrevive al cambio; pasa por los parámetros/contexto que el comando conserva.

## 3. Sintaxis y reglas del parser

- Un comando por línea; el nombre no distingue mayúsculas/minúsculas.
- Los argumentos se separan por espacios, excepto dentro de una pareja de comillas.
- El texto con espacios debe ir entre comillas: `text "Hola, entrenador."`.
- Los comentarios solo se admiten como líneas completas que empiezan con `#` o `//` después del recorte.
- Los nombres de etiqueta no llevan dos puntos: `label puerta`.
- El parser valida que el nombre esté en `COMANDOS_VALIDOS`; eso no garantiza que `_convert` tenga implementación.
- Argumentos ausentes o inválidos pueden producir advertencia, comando omitido o valor por defecto según el comando; no asumas validación uniforme.

## 4. Comandos convertidos actualmente

| Comando | Argumentos y efecto |
|---|---|
| `text "texto" [MSGBOX_*] [nombre]` | Muestra texto. Las líneas consecutivas de texto plano pueden ser páginas de una misma ventana. El tercer argumento posicional se interpreta como nombre visible del hablante, no como un ID numérico de hablante. |
| `multichoice "pregunta" "opción A" "opción B"` | Muestra choices y guarda el texto/índice seleccionado como `last_choice`, según el comando. |
| `label nombre` / `goto nombre` | Declara destino y salta a él. Etiquetas se resuelven al iniciar/reconstruir el flujo. Si `goto` no encuentra destino, informa el error y la secuencia sigue desde el flujo resultante. |
| `ifchoice valor etiqueta` | Salta si `last_choice` coincide con el valor solicitado; por ejemplo `0` es primera opción en choices indexadas. |
| `ifflag flag etiqueta` | Salta si flag está activo. Los nombres se convierten mediante `GameFlags`; un nombre desconocido se convierte en `NONE` y se comporta como falso. |
| `setflag flag` / `clearflag flag` | Activa o limpia flag global conocido. Flags no declarados en el enum no son almacenamiento arbitrario. |
| `setvar nombre número` / `addvar nombre delta` | Define o suma variable numérica en el contexto local de este runner. |
| `compare nombre operador valor etiqueta` | Compara variable y salta si se cumple. Operadores: `==`, `!=`, `>`, `<`, `>=`, `<=`. |
| `faceplayer` | Hace que el NPC del contexto mire al jugador, cuando existe NPC. |
| `lock` / `release` | Bloquea/desbloquea el movimiento manual del jugador a través del contexto. No elimina rutas activas que deban terminar. |
| `waitbutton` | Espera una entrada de aceptar/botón A y reanuda el runner. |
| `wait segundos` | Espera una duración en segundos y continúa. |
| `fadeout [segundos]` / `fadein [segundos]` | Llama a `FadeScreen`; usa 0.4 s si se omite duración. Espera a la señal de fin. |
| `weather nombre` | Convierte el nombre a clima y solicita cambio a `WeatherManager`. |
| `sound SE_NOMBRE` / `sound GUI_NOMBRE` | Resuelve `SFXGame.SoundEffectID` y reproduce SE; `SE_` puede omitirse. El token debe existir en ese catálogo. |
| `applymovement [objetivo] pasos` | Inicia una ruta sin esperar automáticamente. Objetivo por defecto/event/npc, `player` o ID de evento según el contexto. |
| `moveplayer pasos` | Inicia una ruta del jugador. |
| `waitmovement [objetivo]` | Espera `route_finished` de la ruta indicada. Si no hay controlador/ruta válida, no hay una ruta que completar. |
| `warp MAP_ID x y [dirección]` | Fade, carga cluster en celda local y fade de entrada. Dirección opcional: `up`, `down`, `left`, `right`. ID puede incluir o no `MAPSEC_`. |
| `giveitem ITEM [cantidad] [silent]` | Añade al inventario mediante `BagService`. El tercer argumento literal `silent` evita mostrar texto; de lo contrario muestra texto y espera al diálogo. |
| `checkitem ITEM [cantidad] [etiqueta]` | Salta a etiqueta si la cantidad disponible es al menos la solicitada. |
| `specials SAVE_GAME [silent]` | Guarda mediante `SaveService`; `HEAL_PARTY` cura las instancias existentes en party. No equivale a un sistema completo de combate/party. |
| `end` / `return` | Termina la ejecución actual del runner. |

El parser también reconoce tokens que no equivalen a comandos utilizables; la sección 7 enumera esos límites.

## 5. Rutas de movimiento

Formato: una lista separada por comas, sin espacios entre tokens de la lista.

```text
applymovement event walk_up,walk_up,face_down
applymovement player walk_right,wait_0.5,walk_right
waitmovement player
```

Tokens de texto convertidos por el parser de rutas: `walk_up`/`up`, `walk_down`/`down`, `walk_left`/`left`, `walk_right`/`right`, `face_up`, `face_down`, `face_left`, `face_right`, `face_player` y `wait_N` (segundos). La lista puede incluir `wait_0.5`. Aunque el enum interno de `MoveCommand` incluya otras órdenes, el parser textual solo convierte las enumeradas aquí; `random`, `toward_player`, `backward`, etc. no se deben asumir disponibles en `.txt`.

`applymovement` inicia la ruta y retorna; `waitmovement` es la barrera que espera su señal de fin. Un movimiento bloqueado por colisión se reintenta periódicamente por `MoveRouteController`, así que puede esperar indefinidamente si el contenido creó una ruta imposible.

## 6. Ventanas de texto

El tipo de ventana se coloca como segundo argumento de `text`:

```text
text "¿Quieres entrar?" MSGBOX_YESNO
```

`MSGBOX_YESNO` presenta las opciones `Sí` y `No`; `ifchoice 0 etiqueta_si` identifica la primera, `ifchoice 1 etiqueta_no` la segunda. `MSGBOX_SIGN` oculta la placa del hablante. `MSGBOX_NPC` y `MSGBOX_DEFAULT` usan el diálogo normal. `MSGBOX_AUTOCLOSE` y `MSGBOX_GETINPUT` se aceptan como nombres, pero no tienen semántica diferenciada implementada: se comportan como diálogo normal. El nombre opcional mostrado corresponde a texto plano. No existe un comando `msgbox` separado en el parser actual.

## 7. Ejemplo completo

```text
lock
faceplayer
text "¿Me ayudas a revisar la mochila?" MSGBOX_YESNO
ifchoice 1 no
giveitem POTION 2
text "Guarda estas dos pociones."
release
end

label no
text "De acuerdo, quizá después."
release
end
```

Recorrido: bloquea entrada manual; orienta al NPC; el mensaje devuelve una selección; `ifchoice 1 no` salta si se eligió No; si se eligió Sí, se añaden dos pociones y aparece el siguiente texto; ambas ramas liberan al jugador y terminan. El bloque de selección es asíncrono, así que el runner no evalúa `ifchoice` hasta que se cierra la ventana.

Ejemplo de ruta con espera explícita:

```text
lock
applymovement event walk_up,walk_right,face_player
waitmovement event
text "Ya llegué."
release
end
```

Sin `waitmovement`, el mensaje podría empezar antes de que el NPC termine su ruta.

## 8. Comandos reservados o no convertidos

`trainerbattle` aparece en la lista del parser, pero el conversor avisa que no está portado y no genera el comando. Se conserva para no perder contenido futuro; no usarlo como batalla funcional. `savegame` no aparece como token válido: usar `specials SAVE_GAME`. Otros tokens que el parser reconozca pero no estén en la tabla de conversión se omiten con advertencia, no ejecutan un placeholder. Antes de adoptar uno, comprobar parser **y** conversor.

## 9. Flags de evento

El runner serializa los flags globales por IDs de `GameFlags`, no como claves libres de texto. `MapScriptEntry` también traduce tokens al enum. `MapEvent.condition_flag` y flags de objetos ocultos actualmente usan clave textual directa; no son intercambiables de forma garantizada. Véase [AUDITORIA.md](AUDITORIA.md).
