class_name ItemData
extends Resource

@export var id: ItemId.Id = ItemId.Id.NONE
@export var name: String = ""
@export var name_plural: String = ""
@export_multiline var description: String = ""
@export var pocket: ItemPocket.Id = ItemPocket.Id.ITEMS
@export var price: int = 0
@export var sell_price: int = 0
@export var stack_limit: int = 999
@export var field_usable: bool = false
@export var battle_usable: bool = false
@export var consumable: bool = true
@export var effect: ItemEffectId.Id = ItemEffectId.Id.NONE
@export var effect_param: int = 0
@export var flags: PackedStringArray = PackedStringArray()
@export var icon: Texture2D


static func from_dict(d: Dictionary) -> ItemData:
	var data := ItemData.new()
	data.id = ItemId.from_token(str(d.get("id", "")))
	data.name = str(d.get("name", ""))
	data.name_plural = str(d.get("name_plural", ""))
	data.description = str(d.get("description", ""))
	data.pocket = ItemPocket.from_token(str(d.get("pocket", "ITEMS")))
	data.price = int(d.get("price", 0))
	data.sell_price = int(d.get("sell_price", data.price / 2))
	data.consumable = bool(d.get("consumable", true))
	data.field_usable = str(d.get("field_use", "")).strip_edges() != ""
	data.battle_usable = str(d.get("battle_use", "")).strip_edges() != ""
	var fl: Variant = d.get("flags", [])
	if fl is Array:
		for x: Variant in fl:
			data.flags.append(str(x))
	data.effect = _guess_effect(data)
	data.effect_param = int(d.get("effect_param", 0))
	return data


static func _guess_effect(data: ItemData) -> ItemEffectId.Id:
	for f: String in data.flags:
		if f.begins_with("Repel") or f == "Repel":
			return ItemEffectId.Id.REPEL
	var key: String = ItemId.to_key(data.id)
	if key.ends_with("BALL") or data.pocket == ItemPocket.Id.BALLS:
		return ItemEffectId.Id.POKEBALL
	if data.pocket == ItemPocket.Id.KEY:
		return ItemEffectId.Id.KEY_ITEM
	if "POTION" in key or key == "FULLRESTORE":
		return ItemEffectId.Id.HEAL_HP
	if key in ["ANTIDOTE", "AWAKENING", "PARALYZEHEAL", "BURNHEAL", "ICEHEAL", "FULLHEAL"]:
		return ItemEffectId.Id.CURE_STATUS
	return ItemEffectId.Id.NONE
