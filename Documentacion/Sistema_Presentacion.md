# Sistemas de presentación

Estos sistemas presentan una decisión tomada por otro componente. La sesión/mapa/guion determina qué clima, pista o transición solicitar; el servicio correspondiente se encarga de aplicarlo.

## 1. Música y efectos

`MusicManager` es autoload de reproducción. Mantiene reproductores separados para música de fondo (BGM) y efecto musical (ME), además de un conjunto de reproductores para efectos cortos (SE), permitiendo que un sonido no reemplace la música. Cuando inicia un ME, el manager conserva/pausa BGM y puede reanudarla desde la posición guardada al terminar el ME.

El mapa decide `map_music` a través de `MapMusicController` al activarse/cambiar el mapa. Un script usa `sound SE_TOKEN` para resolver `SFXGame.SoundEffectID` y llamar a `MusicManager.reproducir_se`. `GameSettings.apply_audio()` aplica volumen a buses `Music` y `SFX`, no elige la pista ni altera la lógica del mapa. Los buses están declarados en `default_bus_layout.tres`.

No construir rutas de audio en cada escena: usar el catálogo de `SFXGame` y revisar que coincidan mayúsculas y minúsculas de la carpeta `Sfx/` en sistemas sensibles a nombres.

## 2. Fade de pantalla

`FadeScreen` es autoload sobre `CanvasLayer` 100 con `ColorRect` que cubre viewport. Procesa con `PROCESS_MODE_ALWAYS`, por lo que puede terminar aunque el árbol esté pausado. La curva de alpha es lineal y el tiempo por defecto 0.4 s.

API: `fade_out(duration)`, `fade_in(duration)`, `fade_out_in(callback, duration)`, `set_covered()` y `set_clear()`. `fade_out_in` espera la oscuridad, llama el callback de forma síncrona y vuelve a revelar; no espera una corrutina que el callback devuelva. Los warps que necesitan pasos asíncronos coordinan sus awaits en el propio comando/resolver. Los comandos `fadeout [segundos]` y `fadein [segundos]` omiten duración para usar el default.

## 3. Clima

`WeatherManager` mantiene ID e intensidad y emite cambios. `WeatherRenderer` escucha ese estado y dibuja la implementación visual del clima correspondiente. La sesión aplica clima/intensidad de `MapAttributes` al activar el mapa; el comando `weather nombre` puede solicitar un cambio en runtime. La intensidad está acotada entre 0 y 9; NONE representa intensidad cero. La transición de estado se comunica inmediatamente, aunque algunos efectos visuales tengan interpolación.

`WeatherCatalog` determina recursos y modo visual. El catálogo contempla lluvia, lluvia fuerte, tormenta, nieve, ventisca, granizo, tormenta de arena, niebla y sol; los efectos usan combinaciones de partículas, tiles, tinte y relámpagos. `MapCloud` es un efecto de nubes separado del clima principal: genera nubes decorativas fuera de la vista, las mueve por el mundo y las oculta gradualmente en interiores. No es el resolvedor de colisión ni una categoría automática del clima.

Cuando se añade un clima, comprobar tres enlaces: ID/datos en catálogo, solicitud del manager y representación del renderer. Un ID sin renderer puede cambiar el estado sin producir el aspecto esperado.

## 4. Día y noche

`DayNightManager` consulta por defecto el reloj del sistema una vez por segundo y emite el período/tinte actualizado. `DayNightOverlay` aplica el tinte mediante `CanvasModulate` con interpolación. Al cambiar mapa, `GameSession` configura si el entorno es exterior; interiores no usan el mismo tinte exterior.

Períodos definidos por `period_for_hour`: mañana 05:00–09:59, día 10:00–17:59, tarde 18:00–19:59 y noche desde 20:00 hasta 04:59. Auditoría encontró que `is_evening()` considera tarde desde las 17:00, por lo que un consumidor de ese helper discrepa durante 17:00–17:59 respecto al período/tinte. No asumir que el tiempo está guardado como parte de `SaveData`; el guardado persiste tiempo jugado, no el reloj ambiental.

## 5. Cartel de ubicación

`GameSession` conecta `MapFactory.cluster_loaded` y `current_changed` con `LocationSignpost.try_show_for_map`. Este nodo usa `MapAttributes.map_name`, respeta `show_location_name`, evita repetir el último nombre idéntico y cancela/oculta el anuncio si un mensaje está activo. La transición de entrada/salida es animada.

Los campos `location_style` y `location_type` identifican estilo (HGSS, Platinum, DP, ORAS, XY, BW) y clase de lugar (pueblo, ciudad, ruta, bosque, cueva, lago, parque, mar, default). La implementación observada presenta un panel sencillo para la mayoría de estilos y escena especial para BW (`Escenas/UI/Map_Popup/map_popup.tscn`). La presencia de gráficos de otros estilos en `Graficos/` no significa que estén conectados al renderer.
