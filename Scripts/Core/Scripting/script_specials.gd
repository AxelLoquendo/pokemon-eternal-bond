extends Object
class_name ScriptSpecials
## Subcomandos de "specials". No son sintaxis del lenguaje; son funciones del juego.

enum Id {
	NONE = 0,
	SAVE_GAME,
	HEAL_PARTY,       # stub hasta que exista party
	# Más adelante: STRENGTH_ON, SURF_START, etc.
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
	push_error("ScriptSpecials: desconocido '%s'" % token)
	return Id.NONE
