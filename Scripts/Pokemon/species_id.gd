class_name SpeciesId
extends Object
## Identidad de una especie o forma. Venusaur mega ≠ Venusaur base.

enum Id {
	NONE = 0,
	# --- Prueba (familia Bulbasaur + extras de sprite) ---
	BULBASAUR,
	IVYSAUR,
	VENUSAUR,
	VENUSAUR_MEGA,
	VENUSAUR_GMAX,
	CHARMANDER,
	CHARMELEON,
	CHARIZARD,
	CHARIZARD_MEGA_X,
	CHARIZARD_MEGA_Y,
	CHARIZARD_GMAX,
	PIKACHU,
	PIKACHU_HOENN,
	NIDORAN_F,
	NIDORAN_M,
	WOCHIEN,
}

## Carpeta bajo res://Graficos/Pokemon/ (misma idea que expansion).
const _SPRITE_FOLDER: Dictionary = {
	Id.BULBASAUR: "bulbasaur",
	Id.IVYSAUR: "ivysaur",
	Id.VENUSAUR: "venusaur",
	Id.VENUSAUR_MEGA: "venusaur/mega",
	Id.VENUSAUR_GMAX: "venusaur/gmax",
	Id.CHARMANDER: "charmander",
	Id.CHARMELEON: "charmeleon",
	Id.CHARIZARD: "charizard",
	Id.CHARIZARD_MEGA_X: "charizard/mega_x",
	Id.CHARIZARD_MEGA_Y: "charizard/mega_y",
	Id.CHARIZARD_GMAX: "charizard/gmax",
	Id.PIKACHU: "pikachu",
	Id.PIKACHU_HOENN: "pikachu/hoenn",
	Id.NIDORAN_F: "nidoran_f",
	Id.NIDORAN_M: "nidoran_m",
	Id.WOCHIEN: "wo_chien",
}

const _TOKEN_TO_ID: Dictionary = {
	"BULBASAUR": Id.BULBASAUR,
	"IVYSAUR": Id.IVYSAUR,
	"VENUSAUR": Id.VENUSAUR,
	"VENUSAUR_MEGA": Id.VENUSAUR_MEGA,
	"VENUSAUR_GMAX": Id.VENUSAUR_GMAX,
	"CHARMANDER": Id.CHARMANDER,
	"CHARMELEON": Id.CHARMELEON,
	"CHARIZARD": Id.CHARIZARD,
	"CHARIZARD_MEGA_X": Id.CHARIZARD_MEGA_X,
	"CHARIZARD_MEGA_Y": Id.CHARIZARD_MEGA_Y,
	"CHARIZARD_GMAX": Id.CHARIZARD_GMAX,
	"PIKACHU": Id.PIKACHU,
	"PIKACHU_HOENN": Id.PIKACHU_HOENN,
	"NIDORAN_F": Id.NIDORAN_F,
	"NIDORAN_M": Id.NIDORAN_M,
	"NIDORANF": Id.NIDORAN_F,
	"NIDORANM": Id.NIDORAN_M,
	"WOCHIEN": Id.WOCHIEN,
	"WO_CHIEN": Id.WOCHIEN,
}


static func from_token(token: String) -> Id:
	var key: String = token.strip_edges().to_upper().replace("-", "_")
	if key.is_empty():
		return Id.NONE
	return _TOKEN_TO_ID.get(key, Id.NONE) as Id


static func to_token(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return Id.keys()[id]


static func sprite_folder(id: Id) -> String:
	return str(_SPRITE_FOLDER.get(id, ""))
