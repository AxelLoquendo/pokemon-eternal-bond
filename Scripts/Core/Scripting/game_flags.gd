extends Object
class_name GameFlags
## Única fuente de IDs de flag. En .txt solo usas el nombre del enum.

enum Id {
	NONE = 0,

	# --- Sistema / intro ---
	INTRO_DONE,
	RECEIVED_STARTER,          # futuro; puedes dejarlo declarado ya
	HIDE_RIVAL_PRADO,

	# --- Prado Natal ---
	PRADO_NPC_HERMANO_TALKED,
	PRADO_SIGN_READ,

	# --- Pueblo Alba ---
	ALBA_CENTER_HEALED_ONCE,

	# Añade aquí cada flag nueva antes de usarla en un .txt
}


static func from_token(token: String) -> Id:
	var t: String = token.strip_edges()
	if t.is_empty():
		return Id.NONE
	# Número directo: setflag 3
	if t.is_valid_int():
		var n: int = int(t)
		if n >= 0 and n < Id.size():
			return n as Id
		push_warning("GameFlags: id numérico fuera de rango: %s" % t)
		return Id.NONE
	# Nombre de enum: setflag PRADO_NPC_HERMANO_TALKED
	var keys: Array = Id.keys()
	var upper: String = t.to_upper()
	for i: int in keys.size():
		if str(keys[i]) == upper:
			return i as Id
	push_error("GameFlags: flag no declarada '%s'. Añádela en GameFlags.Id" % t)
	return Id.NONE


static func to_key(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return str(Id.keys()[id])
