extends CanvasLayer
## Summary — página Info ligada a un PokemonInstance del party.
##
## Uso:
##   SummaryScreen.open_from_party(player_data, index)
##   o ejecutar esta escena: crea un mon debug en un PlayerData local y lo muestra.
##
## Controles (debug): 1..6 cambia slot del party si hay varios.

const BALL_ICON_DIR: String = "res://Graficos/UI/Summary_Screen/"
const STATUS_DIR: String = "res://Graficos/Status/"

@onready var _name_lbl: Label = $Entity/Box/Mon_Name
@onready var _lvl_lbl: Label = $Entity/Box/Lvl_Number
@onready var _gender_lbl: Label = $Entity/Box/Gender
@onready var _mon_sprite: Sprite2D = $Entity/Mon
@onready var _ball: Sprite2D = $Entity/Ball
@onready var _status: Sprite2D = $Entity/Status
@onready var _info_page: Node = $InfoPage
@onready var _skills_page: Node = $Skills_Page
@onready var _evs_page: Node = $Evs_Ivs_Page

## 0 = Info, 1 = Skills, 2 = IVs/EVs
var page_index: int = 0


var player_data: PlayerData = null
var party_index: int = 0
var mon: PokemonInstance = null


static func open_from_party(tree: SceneTree, pd: PlayerData, index: int = 0) -> void:
	var path: String = "res://Escenas/UI/Summary_Screen/summary_screen.tscn"
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("Summary: no se pudo cargar %s" % path)
		return
	var scn: CanvasLayer = packed.instantiate() as CanvasLayer
	scn.set("player_data", pd)
	scn.set("party_index", index)
	tree.root.add_child(scn)


func _ready() -> void:
	# Esperar un frame a catálogos autoload
	await get_tree().process_frame
	if SpeciesCatalog and SpeciesCatalog.has_method("warm_index"):
		SpeciesCatalog.warm_index()
	if player_data == null:
		player_data = PlayerData.new()
	if player_data.party.is_empty():
		_seed_debug_party()
	_bind_party_index(party_index)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.keycode
	if key >= KEY_1 and key <= KEY_6:
		_bind_party_index(int(key) - int(KEY_1))
		get_viewport().set_input_as_handled()
	elif key == KEY_LEFT or key == KEY_A:
		_set_page(page_index - 1)
		get_viewport().set_input_as_handled()
	elif key == KEY_RIGHT or key == KEY_D:
		_set_page(page_index + 1)
		get_viewport().set_input_as_handled()
	elif key == KEY_ESCAPE or key == KEY_X:
		# Solo si se abrió encima de otra escena
		if get_tree().current_scene != self and get_parent() != null:
			queue_free()
			get_viewport().set_input_as_handled()


func _seed_debug_party() -> void:
	## Un mon de prueba para abrir la escena sola.
	var m: PokemonInstance = PokemonInstance.create(SpeciesId.Id.VENUSAUR, 36, true, true)
	if m == null:
		m = PokemonInstance.create(SpeciesId.Id.BULBASAUR, 16, true, true)
	if m == null:
		push_error("Summary: no se pudo crear mon debug")
		return
	m.ot_name = "Axel"
	m.met_location = "Prado Natal"
	m.met_level = 5
	m.ball = ItemId.Id.POKE_BALL
	# Ítem held opcional si existe en catálogo
	if ItemCatalog and ItemCatalog.has_item(ItemId.Id.LEFTOVERS):
		m.held_item = ItemId.Id.LEFTOVERS
	m.resolve_ability_from_species()
	m.recalculate_stats()
	m.hp = m.max_hp
	player_data.add_pokemon(m)
	print("Summary debug: party[0] = ", m.display_name(), " Nv", m.level)


func _bind_party_index(index: int) -> void:
	if player_data == null or player_data.party.is_empty():
		push_warning("Summary: party vacío")
		return
	party_index = clampi(index, 0, player_data.party.size() - 1)
	mon = player_data.get_pokemon(party_index)
	_apply_mon(mon)


func _apply_mon(m: PokemonInstance) -> void:
	if m == null:
		return
	if _name_lbl:
		_name_lbl.text = m.display_name()
	if _lvl_lbl:
		_lvl_lbl.text = str(m.level)
	if _gender_lbl:
		_gender_lbl.text = _gender_symbol(m.gender)
		# LabelSettings.font_color pisa modulate: hay que tocar el settings.
		var col: Color = _gender_color(m.gender)
		_gender_lbl.modulate = Color.WHITE
		if _gender_lbl.label_settings != null:
			var ls: LabelSettings = _gender_lbl.label_settings.duplicate()
			ls.font_color = col
			# sombra suave del mismo tono
			ls.shadow_color = Color(col.r, col.g, col.b, 0.45)
			_gender_lbl.label_settings = ls
		else:
			_gender_lbl.modulate = col

	if _mon_sprite:
		var tex: Texture2D = m.front_texture(m.is_shiny)
		if tex != null:
			_mon_sprite.texture = tex

	if _ball:
		_ball.texture = _ball_texture(m.ball)

	if _status:
		var st: Texture2D = _status_texture(m.status)
		_status.texture = st
		_status.visible = st != null

	if _info_page and _info_page.has_method("bind"):
		_info_page.bind(m)
	if _skills_page and _skills_page.has_method("bind"):
		_skills_page.bind(m)
	if _evs_page and _evs_page.has_method("bind"):
		_evs_page.bind(m)
	_set_page(page_index)


func _gender_symbol(g: PokemonEnums.Gender) -> String:
	match g:
		PokemonEnums.Gender.MALE:
			return "♂"
		PokemonEnums.Gender.FEMALE:
			return "♀"
		_:
			return ""


func _gender_color(g: PokemonEnums.Gender) -> Color:
	match g:
		PokemonEnums.Gender.MALE:
			return Color(0.35, 0.55, 1.0)
		PokemonEnums.Gender.FEMALE:
			return Color(1.0, 0.4, 0.55)
		_:
			return Color.WHITE


func _ball_texture(id: ItemId.Id) -> Texture2D:
	if id == ItemId.Id.NONE:
		id = ItemId.Id.POKE_BALL
	var token: String = ItemId.to_token(id).replace("_", "")
	var path: String = BALL_ICON_DIR + "icon_ball_%s.png" % token
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	# fallback
	path = BALL_ICON_DIR + "icon_ball_POKEBALL.png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _status_texture(status: String) -> Texture2D:
	if status.is_empty() or status == "FNT":
		return null
	var key: String = status.to_lower()
	# aliases
	match key:
		"psn":
			key = "poison"
		"tox":
			key = "badly_poisoned"
		"brn":
			key = "burn"
		"par":
			key = "paralysis"
		"slp":
			key = "sleep"
		"frz":
			key = "freeze"
	var path: String = STATUS_DIR + key + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _set_page(idx: int) -> void:
	page_index = posmod(idx, 3)
	if _info_page:
		_info_page.visible = page_index == 0
	if _skills_page:
		_skills_page.visible = page_index == 1
	if _evs_page:
		_evs_page.visible = page_index == 2
