extends Node
## Autoload SessionBoot — puente menú ↔ overworld (sin lógica de juego).

var start_data: GameStartData = null
var loaded_play_seconds: float = 0.0
## Flags a aplicar al entrar en GameSession (después de load).
var pending_flags: Dictionary = {}


func clear_pending() -> void:
	start_data = null
	loaded_play_seconds = 0.0
	pending_flags.clear()
