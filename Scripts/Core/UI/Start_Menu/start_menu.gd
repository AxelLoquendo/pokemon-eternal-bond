extends CanvasLayer

signal closed

enum options {
	POKEDEX,
	POKEMON,
	BAG,
	PROFILE,
	SAVE,
	OPTIONS,
}

@onready var contenedor: GridContainer = $Control/GridContainer
##---------------
## VARIABLES
##---------------
var _buttons: Array[TextureRect] = []
var _index: int = 0

##---------------
## CONSTANTES
##---------------
const color_on: Color = Color(1, 1, 1, 1)
const color_off: Color = Color(0.65, 0.65, 0.65, 1)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [
		contenedor.get_node("Pokedex") as TextureRect,
		contenedor.get_node("Pokemon") as TextureRect,
		contenedor.get_node("Mochila") as TextureRect,
		contenedor.get_node("Perfil") as TextureRect,
		contenedor.get_node("Guardar") as TextureRect,
		contenedor.get_node("Opciones") as TextureRect,
	]

func is_open() -> bool:
	return visible
