extends Node2D
## Página Info del summary. bind(PokemonInstance) rellena todos los campos.

const TYPE_DIR: String = "res://Graficos/Types/"
const TERA_DIR: String = "res://Graficos/Types/Tera/"

@onready var _dex: Label = $Info_Box/Dex_Number
@onready var _species_name: Label = $Info_Box/Specie_Name
@onready var _tera: Sprite2D = $Info_Box/Tera_Type if has_node("Info_Box/Tera_Type") else null
@onready var _type1: Sprite2D = $Info_Box/Type_1
@onready var _type2: Sprite2D = $Info_Box/Type_2
@onready var _ot: Label = $Info_Box/OT_Name
@onready var _id_num: Label = $Info_Box/Id_Number
@onready var _item_name: Label = $Info_Box/Item_Name
@onready var _origin_lv: Label = $Info_Box/Origin_Lv
@onready var _origin_place: Label = $Info_Box/Origin_Lugar
@onready var _ability_name: Label = $Info_Box/Ability_Name
@onready var _ability_desc: Label = $Info_Box/Specie_Name2
@onready var _item_icon: Sprite2D = $Item_Icon if has_node("Item_Icon") else null


func bind(mon: PokemonInstance) -> void:
	if mon == null:
		return
	var data: SpeciesData = mon.species()

	if _dex:
		var n: int = data.national_dex if data else 0
		_dex.text = "%04d" % n
	if _species_name:
		_species_name.text = data.display_name if data else mon.display_name()

	# Tipos
	if data:
		_set_type_sprite(_type1, data.type_1)
		_set_type_sprite(_type2, data.type_2)
	else:
		_set_type_sprite(_type1, TypeId.Id.NONE)
		_set_type_sprite(_type2, TypeId.Id.NONE)

	# Tera icon (nodo: Info_Box/Tera_Type)
	if _tera:
		var tt: TypeId.Id = mon.tera_type
		if tt == TypeId.Id.NONE and data != null:
			if data.force_tera_type != TypeId.Id.NONE:
				tt = data.force_tera_type
			else:
				tt = data.type_1
		_tera.texture = _type_tex(tt, true)
		_tera.visible = _tera.texture != null

	if _ot:
		_ot.text = mon.ot_name if not mon.ot_name.is_empty() else "???"
	if _id_num:
		# Sin trainer ID real aún: placeholder estable por nombre OT
		var code: int = mon.ot_name.hash() if not mon.ot_name.is_empty() else 0
		_id_num.text = "%06d" % absi(code % 1000000)

	# Held item
	var item: ItemData = mon.held_item_data()
	if _item_name:
		var item_txt: String = "—"
		if item != null:
			item_txt = item.display_name
		elif mon.held_item != ItemId.Id.NONE:
			item_txt = ItemId.to_token(mon.held_item)
		if _item_name.has_method("set_compressed_text"):
			_item_name.call("set_compressed_text", item_txt)
		else:
			_item_name.text = item_txt
	if _item_icon:
		if ItemCatalog and mon.held_item != ItemId.Id.NONE:
			_item_icon.texture = ItemCatalog.get_icon(mon.held_item)
		else:
			_item_icon.texture = null
		_item_icon.visible = _item_icon.texture != null

	if _origin_lv:
		_origin_lv.text = "Lv. %d" % maxi(1, mon.met_level)
	if _origin_place:
		_origin_place.text = mon.met_location if not mon.met_location.is_empty() else "—"

	# Ability
	if _ability_name:
		_ability_name.text = mon.ability_name()
	if _ability_desc:
		var ab: AbilityData = mon.ability_data()
		_ability_desc.text = ab.description if ab and not ab.description.is_empty() else ""


func _set_type_sprite(spr: Sprite2D, type_id: TypeId.Id) -> void:
	if spr == null:
		return
	if type_id == TypeId.Id.NONE:
		spr.texture = null
		spr.visible = false
		return
	spr.texture = _type_tex(type_id, false)
	spr.visible = spr.texture != null


func _type_tex(type_id: TypeId.Id, tera: bool) -> Texture2D:
	if type_id == TypeId.Id.NONE:
		return null
	var token: String = TypeId.to_token(type_id).to_lower()
	if token.is_empty() or token == "none":
		return null
	var path: String = (TERA_DIR if tera else TYPE_DIR) + token + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	# typo mistery in assets
	if token == "mystery":
		path = TYPE_DIR + "mistery.png"
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
