extends Node
## Autoload: NewGameState

const DEFAULT_MALE_NAME: String = "Kael"
const DEFAULT_FEMALE_NAME: String = "Kaida"

var player_name: String = DEFAULT_MALE_NAME
var is_male: bool = true


func reset() -> void:
	is_male = true
	player_name = DEFAULT_MALE_NAME


func apply_gender(male: bool) -> void:
	is_male = male
	player_name = DEFAULT_MALE_NAME if male else DEFAULT_FEMALE_NAME


func set_player_name(new_name: String) -> void:
	var n: String = new_name.strip_edges()
	if n.is_empty():
		n = DEFAULT_MALE_NAME if is_male else DEFAULT_FEMALE_NAME
	# Límite típico PE
	if n.length() > 7:
		n = n.substr(0, 7)
	player_name = n
