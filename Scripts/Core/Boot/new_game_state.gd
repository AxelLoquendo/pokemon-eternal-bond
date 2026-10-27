extends Node
## Autoload: solo datos de creación de personaje.

const DEFAULT_MALE_NAME: String = "Kael"
const DEFAULT_FEMALE_NAME: String = "Kaida"
const MALE_OW: String = "res://Graficos/Object_Event/player/male/kael/normal.png"
const FEMALE_OW: String = "res://Graficos/Object_Event/player/female/kaida/normal.png"

var player_name: String = DEFAULT_MALE_NAME
var is_male: bool = true


func reset() -> void:
	is_male = true
	player_name = DEFAULT_MALE_NAME
	ScriptExecutionContext.clear_flags()
	SessionBoot.pending_flags.clear()


func apply_gender(male: bool) -> void:
	is_male = male
	player_name = DEFAULT_MALE_NAME if male else DEFAULT_FEMALE_NAME


func set_player_name(new_name: String) -> void:
	var n: String = new_name.strip_edges()
	if n.is_empty():
		n = DEFAULT_MALE_NAME if is_male else DEFAULT_FEMALE_NAME
	if n.length() > 7:
		n = n.substr(0, 7)
	player_name = n


func build_start_data() -> GameStartData:
	## Ensambla el paquete que GameSession entiende (igual que un load).
	var data := GameStartData.new()
	var pd := PlayerData.new()
	pd.name = player_name
	pd.id = &"player"
	pd.walk = 4
	pd.run = 8
	pd.money = 0
	data.player_data = pd
	return data


func ow_texture_path() -> String:
	return MALE_OW if is_male else FEMALE_OW
