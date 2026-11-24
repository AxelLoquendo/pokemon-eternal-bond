extends CanvasLayer
## Controlador del Summary.
## - Input: acciones del proyecto (Left/Right/Up/Down/buttonA/B/L/R…)
## - Orquesta páginas (vista) y audio
## - No calcula stats ni parsea datos de especie (eso es PokemonInstance / catálogos)

const BALL_ICON_DIR: String = "res://Graficos/UI/Summary_Screen/"
const STATUS_DIR: String = "res://Graficos/Status/"
const PAGE_COUNT: int = 4

@onready var _name_lbl: Label = $Entity/Box/Mon_Name
@onready var _lvl_lbl: Label = $Entity/Box/Lvl_Number
@onready var _gender_lbl: Label = $Entity/Box/Gender
@onready var _mon_sprite: Sprite2D = $Entity/Mon
@onready var _ball: Sprite2D = $Entity/Ball
@onready var _status: Sprite2D = $Entity/Status
@onready var _info_page: Node = $InfoPage
@onready var _skills_page: Node = $Skills_Page
@onready var _evs_page: Node = $Evs_Ivs_Page
@onready var _move_page: Node = $Move_Page
@onready var bg_lluvia: AnimationPlayer = $BG/BG_Lluvia

var player_data: PlayerData = null
var party_index: int = 0
var page_index: int = 0
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
	bg_lluvia.play("Lluvia_BG")
	await get_tree().process_frame
	if SpeciesCatalog and SpeciesCatalog.has_method("warm_index"):
		SpeciesCatalog.warm_index()
	if player_data == null:
		player_data = PlayerData.new()
	if player_data.party.is_empty():
		_seed_debug_party()
	_bind_party_index(party_index)
	_play_ui(SFXGame.SoundEffectID.SE_GUI_MENU_OPEN)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# Páginas: L/R o Left/Right
	if event.is_action_pressed("buttonL") or event.is_action_pressed("Left"):
		_change_page(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonR") or event.is_action_pressed("Right"):
		_change_page(1)
		get_viewport().set_input_as_handled()
		return
	var on_moves: bool = page_index == 3 and _move_page != null
	var moves_active: bool = on_moves and _move_page.has_method("is_active") and _move_page.is_active()
	if event.is_action_pressed("Up"):
		if moves_active:
			_move_page.select_delta(-1)
			_play_ui(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		else:
			_bind_party_index(party_index - 1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Down"):
		if moves_active:
			_move_page.select_delta(1)
			_play_ui(SFXGame.SoundEffectID.SE_GUI_SEL_CURSOR)
		else:
			_bind_party_index(party_index + 1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonB"):
		if on_moves and _move_page.has_method("cancel") and _move_page.cancel():
			_play_ui(SFXGame.SoundEffectID.SE_GUI_SEL_CANCEL)
			get_viewport().set_input_as_handled()
			return
		_close_summary()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonA"):
		if on_moves and _move_page.has_method("confirm"):
			_move_page.confirm()
			_play_ui(SFXGame.SoundEffectID.SE_GUI_SEL_DECISION)
			get_viewport().set_input_as_handled()
			return
		_play_cry()
		get_viewport().set_input_as_handled()
		return


func _change_page(delta: int) -> void:
	if _move_page and _move_page.has_method("exit_mode"):
		_move_page.exit_mode()
	_set_page(page_index + delta)
	_play_ui(SFXGame.SoundEffectID.SE_GUI_SUMMARY_CHANGE_PAGE)


func _set_page(idx: int) -> void:
	page_index = posmod(idx, PAGE_COUNT)
	if _info_page:
		_info_page.visible = page_index == 0
	if _skills_page:
		_skills_page.visible = page_index == 1
	if _evs_page:
		_evs_page.visible = page_index == 2
	if _move_page:
		_move_page.visible = page_index == 3


func _bind_party_index(index: int) -> void:
	if player_data == null or player_data.party.is_empty():
		push_warning("Summary: party vacío")
		return
	var next: int = posmod(index, player_data.party.size())
	var changed: bool = next != party_index or mon == null
	party_index = next
	mon = player_data.get_pokemon(party_index)
	_apply_header(mon)
	_apply_pages(mon)
	_set_page(page_index)
	if changed:
		_play_ui(SFXGame.SoundEffectID.SE_GUI_PARTY_SWITCH)
		_play_cry()


func _apply_header(m: PokemonInstance) -> void:
	## Solo presentación del bloque izquierdo (nombre / sprite / ball).
	if m == null:
		return
	if _name_lbl:
		_name_lbl.text = m.display_name()
	if _lvl_lbl:
		_lvl_lbl.text = str(m.level)
	if _gender_lbl:
		_gender_lbl.text = _gender_symbol(m.gender)
		var col: Color = _gender_color(m.gender)
		_gender_lbl.modulate = Color.WHITE
		if _gender_lbl.label_settings != null:
			var ls: LabelSettings = _gender_lbl.label_settings.duplicate()
			ls.font_color = col
			ls.shadow_color = Color(col.r, col.g, col.b, 0.45)
			_gender_lbl.label_settings = ls
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


func _apply_pages(m: PokemonInstance) -> void:
	## Las páginas solo muestran; el mon ya trae datos/cálculos.
	if m == null:
		return
	if _info_page and _info_page.has_method("bind"):
		_info_page.bind(m)
	if _skills_page and _skills_page.has_method("bind"):
		_skills_page.bind(m)
	if _evs_page and _evs_page.has_method("bind"):
		_evs_page.bind(m)
	if _move_page and _move_page.has_method("bind"):
		_move_page.bind(m)


func _play_cry() -> void:
	if mon == null:
		return
	PokemonCry.play(mon.species_id)


func _play_ui(id: SFXGame.SoundEffectID) -> void:
	if MusicManager == null:
		return
	if MusicManager.has_method("reproducir_se"):
		MusicManager.reproducir_se(id)


func _close_summary() -> void:
	bg_lluvia.stop()
	_play_ui(SFXGame.SoundEffectID.SE_GUI_MENU_CLOSE)
	if get_tree().current_scene != self and get_parent() != null:
		queue_free()


func _seed_debug_party() -> void:
	var m: Array[PokemonInstance] = [
		PokemonInstance.create(SpeciesId.Id.VENUSAUR, 36, true, true),
		PokemonInstance.create(SpeciesId.Id.WYRDEER, 40, true, true),
		PokemonInstance.create(SpeciesId.Id.QUAQUAVAL, 36, true, true),
		PokemonInstance.create(SpeciesId.Id.EELEKTROSS_MEGA, 65, true, true),
		PokemonInstance.create(SpeciesId.Id.PALAFIN_HERO, 55, true, true),
		PokemonInstance.create(SpeciesId.Id.DURALUDON_GMAX, 42, true, true),
		]
	for i: int in range(m.size()):
		if m[i] == null:
			m[i] = PokemonInstance.create(SpeciesId.Id.BULBASAUR, 16, true, true)
		if m[i] == null:
			return
		m[i].ot_name = "Axel"
		m[i].met_location = "Prado Natal"
		m[i].met_level = 5
		m[i].ball = ItemId.Id.POKE_BALL
		if ItemCatalog and ItemCatalog.has_item(ItemId.Id.LEFTOVERS):
			m[i].held_item = ItemId.Id.LEFTOVERS
		m[i].resolve_ability_from_species()
		m[i].recalculate_stats()
		m[i].hp = m[i].max_hp
		player_data.add_pokemon(m[i])

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
	path = BALL_ICON_DIR + "icon_ball_POKEBALL.png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _status_texture(status: String) -> Texture2D:
	if status.is_empty() or status == "FNT":
		return null
	var key: String = status.to_lower()
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
