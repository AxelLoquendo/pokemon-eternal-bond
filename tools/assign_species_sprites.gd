@tool
extends EditorScript
## Añade "sprite_folder" a cada entrada de forms.json según el manifiesto de sprites.
## Run una vez desde el editor.

const FORMS_PATH: String = "res://Datos/Species/forms.json"
const MANIFEST_PATH: String = "res://Datos/Species/pokemon_sprites.json"
const SPRITES_DIR: String = "res://Graficos/Pokemon/"

## Mismos alias que el assign de species (token → carpeta base).
const BASE_ALIASES: Dictionary = {
	"nidoranfe": "nidoran_f",
	"nidoranma": "nidoran_m",
	"hooh": "ho_oh",
	"mrmime": "mr_mime",
	"mrrime": "mr_rime",
	"mimejr": "mime_jr",
	"jangmoo": "jangmo_o",
	"hakamoo": "hakamo_o",
	"kommoo": "kommo_o",
	"porygonz": "porygon_z",
	"typenull": "type_null",
	"tapukoko": "tapu_koko",
	"tapulele": "tapu_lele",
	"tapubulu": "tapu_bulu",
	"tapufini": "tapu_fini",
	"greattusk": "great_tusk",
	"screamtail": "scream_tail",
	"brutebonnet": "brute_bonnet",
	"fluttermane": "flutter_mane",
	"slitherwing": "slither_wing",
	"sandyshocks": "sandy_shocks",
	"irontreads": "iron_treads",
	"ironbundle": "iron_bundle",
	"ironhands": "iron_hands",
	"ironjugulis": "iron_jugulis",
	"ironmoth": "iron_moth",
	"ironthorns": "iron_thorns",
	"roaringmoon": "roaring_moon",
	"ironvaliant": "iron_valiant",
	"walkingwake": "walking_wake",
	"ironleaves": "iron_leaves",
	"gougingfire": "gouging_fire",
	"ragingbolt": "raging_bolt",
	"ironboulder": "iron_boulder",
	"ironcrown": "iron_crown",
	"wochien": "wo_chien",
	"chienpao": "chien_pao",
	"tinglu": "ting_lu",
	"chiyu": "chi_yu",
}

## form_name (minúsculas, sin acentos) → sufijo de carpeta.
## Orden: reglas más específicas primero.
const NAME_RULES: Array[Dictionary] = [
	{"contains": "mega charizard x", "folder": "mega_x"},
	{"contains": "mega charizard y", "folder": "mega_y"},
	{"contains": "mega mewtwo x", "folder": "mega_x"},
	{"contains": "mega mewtwo y", "folder": "mega_y"},
	{"contains": "mega", "folder": "mega"},
	{"contains": "gigamax", "folder": "gmax"},
	{"contains": "gmax", "folder": "gmax"},
	{"contains": "alola", "folder": "alola"},
	{"contains": "galar", "folder": "galar"},
	{"contains": "hisui", "folder": "hisui"},
	{"contains": "paldea", "folder": "paldea"},
	{"contains": "filo", "folder": "blade"},
	{"contains": "blade", "folder": "blade"},
	{"contains": "escudo", "folder": "shield"},
	{"contains": "ataque", "folder": "attack"},
	{"contains": "defensa", "folder": "defense"},
	{"contains": "velocidad", "folder": "speed"},
	{"contains": "origen", "folder": "origin"},
	{"contains": "therian", "folder": "therian"},
	{"contains": "sky", "folder": "sky"},
	{"contains": "ash", "folder": "ash"},
	{"contains": "eternamax", "folder": "eternamax"},
	{"contains": "crowned", "folder": "crowned"},
	{"contains": "ice rider", "folder": "ice_rider"},
	{"contains": "shadow rider", "folder": "shadow_rider"},
	{"contains": "bloodmoon", "folder": "bloodmoon"},
	{"contains": "sanguina", "folder": "bloodmoon"},
	# Arceus / Silvally por tipo (español)
	{"contains": "tipo lucha", "folder": "fighting"},
	{"contains": "tipo volador", "folder": "flying"},
	{"contains": "tipo veneno", "folder": "poison"},
	{"contains": "tipo tierra", "folder": "ground"},
	{"contains": "tipo roca", "folder": "rock"},
	{"contains": "tipo bicho", "folder": "bug"},
	{"contains": "tipo fantasma", "folder": "ghost"},
	{"contains": "tipo acero", "folder": "steel"},
	{"contains": "tipo desconocido", "folder": "unknown"},
	{"contains": "tipo fuego", "folder": "fire"},
	{"contains": "tipo agua", "folder": "water"},
	{"contains": "tipo planta", "folder": "grass"},
	{"contains": "tipo electrico", "folder": "electric"},
	{"contains": "tipo eléctrico", "folder": "electric"},
	{"contains": "tipo psiquico", "folder": "psychic"},
	{"contains": "tipo psíquico", "folder": "psychic"},
	{"contains": "tipo hielo", "folder": "ice"},
	{"contains": "tipo dragon", "folder": "dragon"},
	{"contains": "tipo dragón", "folder": "dragon"},
	{"contains": "tipo siniestro", "folder": "dark"},
	{"contains": "tipo hada", "folder": "fairy"},
]


func _run() -> void:
	var manifest: Dictionary = _load_json_dict(MANIFEST_PATH)
	if manifest.is_empty():
		printerr("No se pudo leer el manifiesto")
		return

	var forms: Array = _load_json_array(FORMS_PATH)
	if forms.is_empty():
		printerr("No se pudo leer forms.json")
		return

	## base → lista de sufijos disponibles en el manifiesto
	var form_subs: Dictionary = _index_form_subs(manifest)

	var assigned: int = 0
	var missing: PackedStringArray = PackedStringArray()

	for i: int in forms.size():
		var entry: Variant = forms[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = entry

		var species_token: String = str(d.get("species", "")).to_lower()
		var base: String = _base_folder(species_token)
		var form_name: String = str(d.get("form_name", ""))
		var form_idx: int = int(d.get("form", 0))

		var subs: Array = form_subs.get(base, []) as Array
		var sub: String = _match_sub(form_name, form_idx, subs)

		if sub.is_empty():
			missing.append("%s form %d (%s) base=%s" % [
				species_token, form_idx, form_name, base
			])
			d.erase("sprite_folder")
		else:
			d["sprite_folder"] = sub
			assigned += 1

		forms[i] = d

	var out_text: String = JSON.stringify(forms, "\t")
	var f: FileAccess = FileAccess.open(FORMS_PATH, FileAccess.WRITE)
	if f == null:
		printerr("No se pudo escribir forms.json")
		return
	f.store_string(out_text + "\n")
	f.close()

	print("Formas con sprite_folder: %d / %d" % [assigned, forms.size()])
	if not missing.is_empty():
		print("--- SIN match (%d) ---" % missing.size())
		for m: String in missing:
			print("  ", m)


func _base_folder(token: String) -> String:
	if BASE_ALIASES.has(token):
		return str(BASE_ALIASES[token])
	return token


func _index_form_subs(manifest: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in manifest.keys():
		var k: String = str(key)
		var slash: int = k.find("/")
		if slash <= 0:
			continue
		var base: String = k.substr(0, slash)
		var sub: String = k.substr(slash + 1)
		if not out.has(base):
			out[base] = []
		(out[base] as Array).append(sub)
	return out


func _match_sub(form_name: String, form_idx: int, subs: Array) -> String:
	if subs.is_empty():
		return ""

	var name_l: String = form_name.to_lower()
	name_l = name_l.replace("á", "a").replace("é", "e").replace("í", "i")
	name_l = name_l.replace("ó", "o").replace("ú", "u")

	# 1) Reglas por texto del form_name
	for rule: Dictionary in NAME_RULES:
		var needle: String = str(rule["contains"])
		var folder: String = str(rule["folder"])
		if name_l.contains(needle) and folder in subs:
			return folder

	# 2) El sufijo aparece literal en el nombre (ej. "blade", "alola")
	for s: Variant in subs:
		var sub: String = str(s)
		if name_l.contains(sub.replace("_", " ")) or name_l.contains(sub):
			return sub

	# 3) Un solo subcarpeta disponible → usarla
	if subs.size() == 1:
		return str(subs[0])

	# 4) form index 1..n alineado con lista ordenada de subs (último recurso)
	var sorted_subs: Array = subs.duplicate()
	sorted_subs.sort()
	var i: int = form_idx - 1
	if i >= 0 and i < sorted_subs.size():
		return str(sorted_subs[i])

	return ""


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	return []
