extends RefCounted
class_name MessageTextFormatter
## Expande macros y BBCode. Genera variante de sombra (colores oscurecidos).

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

const SHADOW_FACTOR: float = 1.5


static func expand(raw: String, context: ScriptExecutionContext = null) -> String:
	var t: String = raw

	var player_name: String = _player_name()
	t = t.replace("\\PN", player_name)
	t = t.replace("{PLAYER}", player_name)
	t = t.replace("{player}", player_name)

	if context != null:
		t = _expand_vars(t, context)

	t = _expand_color_shortcuts(t)
	t = t.replace("\\n", "\n")
	return t


static func to_shadow_bbcode(bb: String, factor: float = SHADOW_FACTOR) -> String:
	var re: RegEx = RegEx.new()
	re.compile("\\[color=([^\\]]+)\\]")
	var out: String = ""
	var pos: int = 0
	while true:
		var m: RegExMatch = re.search(bb, pos)
		if m == null:
			out += bb.substr(pos)
			break
		out += bb.substr(pos, m.get_start() - pos)
		var token: String = m.get_string(1).strip_edges()
		var dark: String = _resolve_dark_hex(token, factor)
		out += "[color=%s]" % dark
		pos = m.get_end()
	return out


## Caracteres visibles (sin tags BBCode) para el typewriter.
static func visible_length(bb: String) -> int:
	var plain: String = strip_bbcode(bb)
	return plain.length()


static func strip_bbcode(bb: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(bb, "", true)


static func _resolve_dark_hex(token: String, factor: float) -> String:
	var t: String = token.strip_edges()
	if t.begins_with("#"):
		return darken_hex(t, factor)
	var lower: String = t.to_lower()
	if COLOR_ALIASES.has(lower):
		return darken_hex(COLOR_ALIASES[lower], factor)
	# Token desconocido: oscurecer como blanco de UI
	return darken_hex("#F8F8F8", factor)


static func darken_hex(hex: String, factor: float = SHADOW_FACTOR) -> String:
	var h: String = hex.strip_edges()
	if h.begins_with("#"):
		h = h.substr(1)
	if h.length() != 6 and h.length() != 8:
		return hex if hex.begins_with("#") else ("#" + hex)
	var c: Color = Color.html("#" + h.substr(0, 6))
	var d: Color = darken_color(c, factor)
	return "#%02X%02X%02X" % [
		clampi(int(round(d.r * 255.0)), 0, 255),
		clampi(int(round(d.g * 255.0)), 0, 255),
		clampi(int(round(d.b * 255.0)), 0, 255),
	]


static func darken_color(c: Color, factor: float = SHADOW_FACTOR) -> Color:
	return Color(c.r * factor, c.g * factor, c.b * factor, c.a)


static func _player_name() -> String:
	if NewGameState != null and not NewGameState.player_name.strip_edges().is_empty():
		return NewGameState.player_name
	return "Jugador"


static func _expand_vars(t: String, context: ScriptExecutionContext) -> String:
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
			var hex: String = str(COLOR_ALIASES.get(token, token))
			if not hex.begins_with("#"):
				hex = "#" + hex
			insert = "[color=%s]" % hex
		out = out.substr(0, m.get_start()) + insert + out.substr(m.get_end())
	return out
