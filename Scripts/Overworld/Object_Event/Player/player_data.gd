class_name PlayerData
extends CharacterGame

const PARTY_MAX: int = 6

## int(ItemId.Id) → cantidad
@export var bag: Dictionary = {}
## Equipo del entrenador (máx. 6)
@export var party: Array[PokemonInstance] = []


# --- Bag ---

func add_item(id: ItemId.Id, amount: int = 1) -> int:
	if id == ItemId.Id.NONE or amount == 0:
		return count_item(id)
	var k: int = int(id)
	var limit: int = 999
	if ItemCatalog:
		limit = ItemCatalog.stack_limit(id)
	var next: int = clampi(int(bag.get(k, 0)) + amount, 0, limit)
	if next <= 0:
		bag.erase(k)
	else:
		bag[k] = next
	return next


func remove_item(id: ItemId.Id, amount: int = 1) -> bool:
	if count_item(id) < amount:
		return false
	add_item(id, -amount)
	return true


func count_item(id: ItemId.Id) -> int:
	return int(bag.get(int(id), 0))


func has_item(id: ItemId.Id, amount: int = 1) -> bool:
	return count_item(id) >= amount

func items_in_pocket(pocket: ItemPocket.Id) -> Array[ItemId.Id]:
	var out: Array[ItemId.Id] = []
	if ItemCatalog == null:
		return out
	for k: Variant in bag.keys():
		var id: ItemId.Id = int(k) as ItemId.Id
		if count_item(id) <= 0:
			continue
		var data: ItemData = ItemCatalog.get_item(id)
		if data == null:
			continue
		if data.pocket == pocket:
			out.append(id)
	return out

# --- Party ---

func party_count() -> int:
	return party.size()


func party_is_full() -> bool:
	return party.size() >= PARTY_MAX


func add_pokemon(poke: PokemonInstance) -> bool:
	if poke == null or party_is_full():
		return false
	party.append(poke)
	return true


func remove_pokemon_at(index: int) -> PokemonInstance:
	if index < 0 or index >= party.size():
		return null
	var poke: PokemonInstance = party[index]
	party.remove_at(index)
	return poke


func get_pokemon(index: int) -> PokemonInstance:
	if index < 0 or index >= party.size():
		return null
	return party[index]


func first_conscious() -> PokemonInstance:
	for p: PokemonInstance in party:
		if p != null and not p.is_fainted():
			return p
	return null


func heal_party() -> void:
	for p: PokemonInstance in party:
		if p != null:
			p.heal_full()



## Enseña la MT/MO al miembro del equipo. Consume 1 ítem si no es importante/key.
## replace_slot: si moveset lleno, índice a reemplazar; -1 = solo si hay hueco.
func use_tm_on(party_index: int, item_id: ItemId.Id, replace_slot: int = -1) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "unknown"}
	var mon: PokemonInstance = get_pokemon(party_index)
	if mon == null:
		result.reason = "no_pokemon"
		return result
	if not has_item(item_id):
		result.reason = "no_item"
		return result
	result = mon.learn_from_item(item_id, replace_slot)
	if not result.get("ok", false):
		return result
	var data: ItemData = ItemCatalog.get_item(item_id) if ItemCatalog else null
	# MTs reutilizables si important (como expansion I_REUSABLE_TMS)
	var consume: bool = true
	if data != null and (data.important or data.pocket == ItemPocket.Id.KEY_ITEMS):
		consume = false
	if consume:
		remove_item(item_id, 1)
	return result
