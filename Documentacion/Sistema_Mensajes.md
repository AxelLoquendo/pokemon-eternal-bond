# Sistema de mensajes y ventanas

El servicio de mensajes es una API global para los sistemas que necesitan pedir diálogo. No decide qué NPC hablar ni qué tile está delante; quien inicia el mensaje ya resolvió esa regla.

## 1. Recorrido de una solicitud

```text
comando / interacción → MessageService.show_* → MessageUI → ventana(s)
                                      señales: message_started / choice_selected / message_finished
```

- `MessageService` conserva una referencia al `MessageUI` registrado, comunica si hay mensaje activo y expone `last_choice`. API: `show_text(text, speaker)`, `show_pages(pages, speaker, choices)` y `show_texts(texts, speaker, choices)`.
- `GameSession` crea un `MessageUI` si no existe uno en el grupo `message_ui`. Al entrar al árbol, `MessageUI` construye `MessageWindow`, `NameWindow` y `ChoiceWindow`, y se registra en `MessageService`.
- `MessageUI` configura el orden: muestra placa del hablante si hay nombre, presenta página, revela el texto, opcionalmente activa choices en la última página y emite fin al cerrar.
- `MessageWindow` aplica skin/tipografía, calcula sombra y revela caracteres según el ajuste de velocidad. Al completar el typewriter muestra la flecha animada. Aceptar durante la escritura completa el texto de golpe; aceptar después avanza página o cierra.
- `ChoiceWindow` toma arriba/abajo, mueve selección y confirma con A/aceptar. La selección emite índice; `MessageService` lo guarda y emite `choice_selected`.

Los comandos asíncronos se conectan a `message_finished`; mientras la ventana está abierta `Player` no procesa movimiento ni interacción manual. El UI procesa aunque el árbol esté pausado (`PROCESS_MODE_ALWAYS`).

## 2. Texto, páginas y choices

`show_text("Hola")` equivale a una página. Para varias páginas usar `show_pages(PackedStringArray([...]))` o `show_texts(Array[String])`. Choices se pasan junto con páginas: la lista aparece junto a la última página y evita que el cierre normal avance antes de elegir.

Ejemplo de API en GDScript:

```gdscript
MessageService.show_pages(
    PackedStringArray(["¿Quieres continuar?"]),
    "Guía",
    PackedStringArray(["Sí", "No"])
)
```

El índice confirmado empieza en cero. Los archivos `.txt` almacenan selección en `last_choice` dentro del contexto del runner; la propiedad global de `MessageService` también conserva el último índice emitido, pero no debe confundirse con variable local de script. Véase [Sistema_Scripts.md](Sistema_Scripts.md).

## 3. Responsabilidad de cada escena

| Pieza | Qué hace |
|---|---|
| `MessageConfig` | Rutas de fuente/skins, rectángulo de mensaje, colores, velocidad base y constantes de layout. |
| `MessageService` | API, estado activo y traducción de señales del UI a señales de servicio. |
| `MessageUI` | Orquesta página actual, hablante, choices, entrada y cierre. |
| `MessageWindow` | Caja principal, BBCode, typewriter, clip y flecha de espera. |
| `NameWindow` | Placa del hablante. Se oculta con nombre vacío o tipo SIGN. |
| `ChoiceWindow` | Caja de choices, selección, cursor y confirmación. |
| `PeWindowSkin` | Márgenes nine-patch calculados para la textura de ventana. |
| `MessageTextFormatter` | Convierte texto para sombra y calcula longitud visible para el typewriter. |

Diálogo principal y choices usan sus skins configuradas en `Graficos/Window_Skin/`; el cursor usa `Graficos/UI/sel_arrow.png`. La flecha de pausa se recorta de su atlas por frames. El texto principal queda clippeado al área interior del nine-patch; la sombra está desplazada en Y.

## 4. Integración de scripts

`ScriptCmdText` llama al servicio y marca el contexto como esperando; su callback completa la espera cuando el UI emite fin. `MSGBOX_YESNO` crea choices Sí/No. El orden correcto es mostrar, esperar cierre/selección, y solo entonces ejecutar `ifchoice`. Las líneas consecutivas `text "..."` pueden agruparse como páginas por `ScriptCmdTextFile`; un `text` tipado con MSGBOX cierra la agrupación anterior.

El servicio maneja un UI activo a la vez. Si ningún `MessageUI` se registró, `MessageService` emite advertencia y `message_finished` para no dejar un runner esperando indefinidamente. Una lista vacía de páginas también finaliza sin mostrar caja.

## 5. Ajuste de velocidad

`MessageWindow.display_text()` consulta `GameSettings.text_delay()` en cada página; si no existe el autoload usa la velocidad media de `MessageConfig`. El conteo de caracteres por segundo es inverso al delay: delay cero usa un fallback de 40 caracteres por segundo. Ajustes disponibles y persistencia están descritos en [Sistema_Datos.md](Sistema_Datos.md); la pantalla de opciones aún no permite editarlos.
