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
}


static func from_token(token: String) -> Id:
	var t: String = token.strip_edges().to_upper()
	if t.is_empty():
		return Id.NONE
	if t.is_valid_int():
		var n: int = int(t)
		if n >= 0 and n < Id.size():
			return n as Id
		return Id.NONE
	for i: int in Id.size():
		if str(Id.keys()[i]) == t:
			return i as Id
	push_error("TypeId: tipo desconocido '%s'" % token)
	return Id.NONE


static func to_key(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return str(Id.keys()[id])


static func is_battle_type(id: Id) -> bool:
	return id != Id.NONE and id != Id.STELLAR
