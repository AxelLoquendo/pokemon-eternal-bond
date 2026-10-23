class_name TitleConfig
extends Object

## Rutas y tiempos del arranque (Eternal Bond, 480×320).

const CREDITS_SCENE: String = "res://Escenas/UI/Title_Screen/creditos.tscn"
const TITLE_SCENE: String = "res://Escenas/UI/Title_Screen/title_screen.tscn"
const MAIN_MENU_SCENE: String = "res://Escenas/UI/Main_Menu/main_menu.tscn"

## Si más adelante quieres cadena de varios splash:
const SEQUENCE: PackedStringArray = [
	"res://Graficos/Title_Screen/splash1.png",
]

const SECONDS_PER_SPLASH: float = 2.5
const FADE_DURATION: float = 0.4
const START_FLASH_HALF: float = 0.75
const SCREEN_SIZE: Vector2 = Vector2(480.0, 320.0)
