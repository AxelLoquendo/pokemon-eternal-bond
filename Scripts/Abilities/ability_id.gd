class_name AbilityId
extends Object
## Habilidades. Tokens al estilo expansion (OVERGROW, BLAZE…).

enum Id {
	NONE = 0,
	# Starters / set de prueba
	OVERGROW,
	BLAZE,
	TORRENT,
	STATIC,
	LIGHTNING_ROD,
	CHLOROPHYLL,
	THICK_FAT,
	SOLAR_POWER,
	LEVITATE,
	PRESSURE,
	INTIMIDATE,
	HUGE_POWER,
	WONDER_GUARD,
	# Gen 9 ejemplo (Wo-Chien)
	TABLETS_OF_RUIN,
}

const _TOKEN_TO_ID: Dictionary = {
	"OVERGROW": Id.OVERGROW,
	"BLAZE": Id.BLAZE,
	"TORRENT": Id.TORRENT,
	"STATIC": Id.STATIC,
	"LIGHTNING_ROD": Id.LIGHTNING_ROD,
	"LIGHTNINGROD": Id.LIGHTNING_ROD,
	"CHLOROPHYLL": Id.CHLOROPHYLL,
	"THICK_FAT": Id.THICK_FAT,
	"THICKFAT": Id.THICK_FAT,
	"SOLAR_POWER": Id.SOLAR_POWER,
	"SOLARPOWER": Id.SOLAR_POWER,
	"LEVITATE": Id.LEVITATE,
	"PRESSURE": Id.PRESSURE,
	"INTIMIDATE": Id.INTIMIDATE,
	"HUGE_POWER": Id.HUGE_POWER,
	"HUGEPOWER": Id.HUGE_POWER,
	"WONDER_GUARD": Id.WONDER_GUARD,
	"WONDERGUARD": Id.WONDER_GUARD,
	"TABLETS_OF_RUIN": Id.TABLETS_OF_RUIN,
	"TABLETSOFRUIN": Id.TABLETS_OF_RUIN,
}


static func from_token(token: String) -> Id:
	var key: String = token.strip_edges().to_upper().replace("-", "_").replace(" ", "_")
	if key.is_empty():
		return Id.NONE
	return _TOKEN_TO_ID.get(key, Id.NONE) as Id


static func to_token(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return Id.keys()[id]
