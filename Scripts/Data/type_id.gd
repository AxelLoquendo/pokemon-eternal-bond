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
	STELLAR,
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
	var keys: Array = Id.keys()
	for i: int in keys.size():
		if str(keys[i]) == t:
			return i as Id
	push_error("TypeId: no declarado '%s'" % token)
	return Id.NONE


static func to_key(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return str(Id.keys()[id])
