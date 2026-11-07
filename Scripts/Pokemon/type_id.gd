class_name TypeId
extends Object

enum Id {
	NONE = 0,
	NORMAL,
	FIGHTING,
	FLYING,
	POISON,
	GROUND,
	ROCK,
	BUG,
	GHOST,
	STEEL,
	MYSTERY, ## TYPE_MYSTERY, el "???"
	FIRE,
	WATER,
	GRASS,
	ELECTRIC,
	PSYCHIC,
	ICE,
	DRAGON,
	DARK,
	FAIRY,
	STELLAR, ## TYPE_STELLAR, tera estelar
}

const _TOKEN_TO_ID: Dictionary = {
	"NORMAL": Id.NORMAL, "FIGHTING": Id.FIGHTING, "FLYING": Id.FLYING,
	"POISON": Id.POISON, "GROUND": Id.GROUND, "ROCK": Id.ROCK,
	"BUG": Id.BUG, "GHOST": Id.GHOST, "STEEL": Id.STEEL,
	"MYSTERY": Id.MYSTERY, "QMARKS": Id.MYSTERY, "TYPELESS": Id.MYSTERY,
	"FIRE": Id.FIRE, "WATER": Id.WATER, "GRASS": Id.GRASS,
	"ELECTRIC": Id.ELECTRIC, "PSYCHIC": Id.PSYCHIC, "ICE": Id.ICE,
	"DRAGON": Id.DRAGON, "DARK": Id.DARK, "FAIRY": Id.FAIRY,
	"STELLAR": Id.STELLAR,
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
