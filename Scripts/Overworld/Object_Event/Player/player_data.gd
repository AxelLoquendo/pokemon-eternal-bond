class_name PlayerData
extends CharacterGame

## int(ItemId.Id) → cantidad
@export var bag: Dictionary = {}


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
