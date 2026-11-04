class_name EnumTokens
extends Object
## Convierte texto ↔ valor de enum (keys de Godot).
## Cada TypeId/MoveId/… solo declara su enum y delega aquí.


static func parse(
	token: String,
	keys: Array,
	default_id: int = 0,
	label: String = "",
	soft_fail: bool = false
) -> int:
	var t: String = token.strip_edges()
	if t.is_empty():
		return default_id

	if t.is_valid_int():
		var n: int = int(t)
		if n >= 0 and n < keys.size():
			return n
		_fail(label, "id fuera de rango: %s" % t, soft_fail)
		return default_id

	for i: int in keys.size():
		if str(keys[i]) == t:
			return i

	var upper: String = t.to_upper()
	for i: int in keys.size():
		if str(keys[i]).to_upper() == upper:
			return i

	_fail(label, "no declarado '%s'" % t, soft_fail)
	return default_id


static func key(
	id: int,
	keys: Array,
	none_id: int = 0,
	none_key: String = ""
) -> String:
	if id == none_id:
		return none_key
	if id < 0 or id >= keys.size():
		return none_key
	return str(keys[id])


static func _fail(label: String, message: String, soft: bool) -> void:
	if label.is_empty():
		return
	if soft:
		push_warning("%s: %s" % [label, message])
	else:
		push_error("%s: %s" % [label, message])
