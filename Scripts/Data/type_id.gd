extends Object
class_name TypeId

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
	FIRE,
	WATER,
	GRASS,
	ELECTRIC,
	PSYCHIC,
	ICE,
	DRAGON,
	DARK,
	FAIRY,
	STELLAR, # Terastal (SV); no entra en el chart clásico
	QMARKS,
}


static func from_token(token: String) -> Id:
	return EnumTokens.parse(token, Id.keys(), Id.NONE, "TypeId") as Id

static func to_key(id: Id) -> String:
	return EnumTokens.key(id, Id.keys(), Id.NONE, "")

static func is_battle_type(id: Id) -> bool:
	return id != Id.NONE and id != Id.STELLAR
