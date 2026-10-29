extends RefCounted
class_name MessageTextFormatter
## Expande macros y deja BBCode listo para RichTextLabel.

## Colores cortos → hex (ajusta a tu paleta)
const COLOR_ALIASES: Dictionary = {
	"red": "#E85048",
	"blue": "#4A90D9",
	"green": "#40A070",
	"yellow": "#E8C040",
	"gray": "#808088",
	"grey": "#808088",
	"white": "#F8F8F8",
	"black": "#404048",
}


static func expand(raw: String, context: ScriptExecutionContext = null) -> String:
	var t: String = raw

	# --- Macros de nombre ---
	var player_name: String = _player_name()
	t = t.replace("\\PN", player_name)
	t = t.replace("{PLAYER}", player_name)
	t = t.replace("{player}", player_name)

	# Rival / otros si más adelante los tienes en NewGameState
	# t = t.replace("\\RN", NewGameState.rival_name)

	# --- Variables de script: {var:foo} ---
	if context != null:
		t = _expand_vars(t, context)

	# --- Atajos de color PE-like: \c[red]texto\c[default] ---
	t = _expand_color_shortcuts(t)

	# \n literal en strings del txt
	t = t.replace("\\n", "\n")

	return t


static func _player_name() -> String:
	if NewGameState != null and not NewGameState.player_name.strip_edges().is_empty():
		return NewGameState.player_name
	return "Jugador"


static func _expand_vars(t: String, context: ScriptExecutionContext) -> String:
	# {var:last_choice} → valor de context.get_variable
	var out: String = t
	var start: int = 0
	while true:
		var i: int = out.find("{var:", start)
		if i < 0:
			break
		var j: int = out.find("}", i)
		if j < 0:
			break
		var key: String = out.substr(i + 5, j - i - 5).strip_edges()
		var val: String = str(context.get_variable(key, ""))
		out = out.substr(0, i) + val + out.substr(j + 1)
		start = i + val.length()
	return out


static func _expand_color_shortcuts(t: String) -> String:
	## \c[red]hola\c  o  \c[#E85048]hola\c[default]
	var out: String = t
	var re_open := RegEx.new()
	re_open.compile("\\\\c\\[([^\\]]+)\\]")
	while true:
		var m: RegExMatch = re_open.search(out)
		if m == null:
			break
		var token: String = m.get_string(1).strip_edges().to_lower()
		var insert: String = ""
		if token == "default" or token == "/" or token == "clear":
			insert = "[/color]"
		else:
			var hex: String = COLOR_ALIASES.get(token, token)
			if not hex.begins_with("#"):
				hex = "#" + hex
			insert = "[color=%s]" % hex
		out = out.substr(0, m.get_start()) + insert + out.substr(m.get_end())
	return out
