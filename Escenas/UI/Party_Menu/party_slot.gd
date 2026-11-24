extends Node2D
## Un slot del party. Gráficos del HP_Box según género del JUGADOR.

const GRAPHICS_DIR: String = "res://Graficos/UI/Party_Menu/box_"
const STATUS_DIR: String = "res://Graficos/Status/"
const ICON_FRAME_TIME: float = 0.35

enum BoxState {
	NORMAL,
	SELECT,
	SWITCH,
	SWITCH_TWO,
}

const _SFX_M: Dictionary = {
	BoxState.NORMAL: "male_normal",
	BoxState.SELECT: "male_select",
	BoxState.SWITCH: "male_switch",
	BoxState.SWITCH_TWO: "male_switch_2",
}
const _SFX_F: Dictionary = {
	BoxState.NORMAL: "female_normal",
	BoxState.SELECT: "female_select",
	BoxState.SWITCH: "female_switch",
	BoxState.SWITCH_TWO: "female_switch_2",
}

@onready var hp_box: Sprite2D = $HP_Box
@onready var _hp_bar: Sprite2D = $HP_Box/HP_Bar
@onready var _hp_num: Label = $HP_Box/HP_Number
@onready var _mon_icon: Sprite2D = $HP_Box/Mon_Icon
@onready var _mon_name: Label = $HP_Box/Mon_Name
@onready var _lvl: Label = $HP_Box/Lvl_Number
@onready var _gender: Label = $HP_Box/Gender
@onready var _status: Sprite2D = $HP_Box/Status
@onready var _held: Sprite2D = $HP_Box/Held

var player_is_male: bool = true
var _state: BoxState = BoxState.NORMAL
var _mon: PokemonInstance = null
var _hp_full_scale_x: float = 1.0
var _hp_base_pos: Vector2 = Vector2.ZERO
var _bars_ready: bool = false
var _icon_t: float = 0.0


func _ready() -> void:
	if NewGameState != null:
		player_is_male = NewGameState.is_male
	_cache_hp_bar()
	_apply_box_texture()


func _process(delta: float) -> void:
	if not visible or _mon == null or _mon_icon == null:
		return
	if _mon_icon.texture == null or _mon_icon.vframes < 2:
		return
	_icon_t += delta
	if _icon_t < ICON_FRAME_TIME:
		return
	_icon_t = 0.0
	_mon_icon.frame = (_mon_icon.frame + 1) % _mon_icon.vframes


func set_player_gender(is_male: bool) -> void:
	player_is_male = is_male
	_apply_box_texture()


func set_box_state(state: BoxState) -> void:
	_state = state
	_apply_box_texture()


func clear_slot() -> void:
	_mon = null
	visible = false


func bind(mon: PokemonInstance) -> void:
	_mon = mon
	if mon == null:
		clear_slot()
		return
	visible = true
	_cache_hp_bar()
	if _mon_name:
		_mon_name.text = mon.display_name()
	if _lvl:
		_lvl.text = str(mon.level)
	if _gender:
		_gender.text = _gender_symbol(mon.gender)
		_gender.modulate = _gender_color(mon.gender)
	if _hp_num:
		_hp_num.text = "%d/%d" % [mon.hp, mon.max_hp]
	_set_hp_bar(mon)
	if _mon_icon:
		_mon_icon.texture = mon.icon_texture()
		_mon_icon.vframes = 2
		_mon_icon.frame = 0
	if _status:
		var st: Texture2D = _status_tex(mon.status)
		_status.texture = st
		_status.visible = st != null
	if _held:
		var has_item: bool = mon.held_item != ItemId.Id.NONE
		_held.visible = has_item
	_apply_box_texture()


func get_mon() -> PokemonInstance:
	return _mon


func _cache_hp_bar() -> void:
	if _bars_ready or _hp_bar == null:
		return
	_hp_full_scale_x = _hp_bar.scale.x
	_hp_base_pos = _hp_bar.position
	_hp_bar.centered = false
	if _hp_bar.texture:
		var fw: float = float(_hp_bar.texture.get_width()) * _hp_full_scale_x
		var fh: float = float(_hp_bar.texture.get_height()) / float(maxi(1, _hp_bar.vframes)) * _hp_bar.scale.y
		_hp_bar.position = Vector2(_hp_base_pos.x - fw * 0.5, _hp_base_pos.y - fh * 0.5)
		_hp_base_pos = _hp_bar.position
	_bars_ready = true


func _set_hp_bar(mon: PokemonInstance) -> void:
	if _hp_bar == null:
		return
	var ratio: float = 1.0
	if mon.max_hp > 0:
		ratio = clampf(float(mon.hp) / float(mon.max_hp), 0.0, 1.0)
	if ratio > 0.5:
		_hp_bar.frame = 0
	elif ratio > 0.2:
		_hp_bar.frame = 1
	else:
		_hp_bar.frame = 2
	_hp_bar.scale.x = _hp_full_scale_x * ratio
	_hp_bar.position = _hp_base_pos
	_hp_bar.visible = ratio > 0.001


func _apply_box_texture() -> void:
	if hp_box == null:
		return
	var table: Dictionary = _SFX_M if player_is_male else _SFX_F
	var path: String = GRAPHICS_DIR + str(table.get(_state, table[BoxState.NORMAL])) + ".png"
	if ResourceLoader.exists(path):
		hp_box.texture = load(path) as Texture2D


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


func _status_tex(status: String) -> Texture2D:
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
