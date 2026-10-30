# Presentación: audio, fade, clima y ubicación

## 1. Audio

`MusicManager` (autoload) reproduce BGM y SE. No conoce mapas: quien decide la pista es el mapa o un comando de script.

`MapMusicController` / atributos del mapa asignan `map_music` al entrar. `sound` en script resuelve un `SFXGame.SoundEffectID` y llama a `reproducir_se`.

## 2. Fade

`FadeScreen` (autoload, `CanvasLayer` 100) cubre la pantalla con un `ColorRect`.

- Duración por defecto: **0.4 s** (PE `pbFadeOutIn`).
- Curva: **alpha lineal** (no SINE).
- API: `fade_out`, `fade_in`, `fade_out_in`, `set_covered`, `set_clear`.
- `process_mode = ALWAYS` para funcionar con el árbol pausado.

Scripts: `fadeout` / `fadein` [segundos]. Warps de script y de `MapEvent` usan el mismo autoload.

## 3. Clima

`WeatherManager` guarda el clima activo y la intensidad. `WeatherRenderer` dibuja partículas / tiles / rayos.

El clima de un mapa sale de `MapAttributes.weather` e `weather_intensity` al activar el mapa. El comando `weather` en script puede cambiarlo en runtime.

## 4. Cartel de nombre de mapa

`LocationSignpost` (creado por `GameSession`) muestra el nombre al entrar al mapa:

- Entrada 0.35 s, visible 1.6 s y salida animada.
- Se cancela si `MessageService.is_active()`.
- No se repite si el **nombre** es el mismo que el anuncio anterior.

### Datos en el mapa

En `MapAttributes`:

| Campo | Uso |
|---|---|
| `map_name` | Texto del cartel |
| `show_location_name` | Si es false, no se muestra |
| `location_style` | `HGSS`, `PLATINUM`, `DP`, `ORAS`, `XY`, `BW` |
| `location_type` | `DEFAULT`, `TOWN`, `CITY`, `ROUTE`, `FOREST`, `CAVE`, `LAKE`, `PARK`, `SEA` |

### Gráficos

`LocationSignpost` muestra el nombre del mapa; la implementación actual usa un panel simple para la mayoría de estilos y una escena especial para BW (`Escenas/UI/Map_Popup/map_popup.tscn`). Los gráficos existentes viven en `Graficos/`.

- En la versión actual no se encontró el catálogo descrito de banners HGSS/Pt/DP/ORAS/XY conectado a `LocationSignpost`; el anuncio normal es un panel de texto.
- BW: utiliza `Escenas/UI/Map_Popup/map_popup.tscn`.

El tamaño y la animación del panel deben revisarse si se incorpora el catálogo de banners por estilo.

### Señales

`MapFactory.cluster_loaded` y `current_changed` → `LocationSignpost.try_show_for_map`.
