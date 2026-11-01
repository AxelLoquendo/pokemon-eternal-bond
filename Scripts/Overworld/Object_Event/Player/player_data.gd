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