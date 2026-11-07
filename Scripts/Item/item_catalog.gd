extends Node
## Catálogo de ítems. Registro mínimo en código; luego import desde expansion.

var _by_id: Dictionary = {} # ItemId.Id -> ItemData


func _ready() -> void:
	_register_starter_set()


func get_item(id: ItemId.Id) -> ItemData:
	return _by_id.get(id) as ItemData


func has_item(id: ItemId.Id) -> bool:
	return _by_id.has(id)


func get_display_name(id: ItemId.Id) -> String:
	var data: ItemData = get_item(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return ItemId.to_token(id)


func stack_limit(id: ItemId.Id) -> int:
	var data: ItemData = get_item(id)
	if data != null:
		return maxi(1, data.stack_limit)
	return 999


func _register_starter_set() -> void:
	_add(_make(ItemId.Id.POKE_BALL, "Poké Ball", ItemPocket.Id.BALLS, 200,
		"Un dispositivo para capturar Pokémon salvajes."))
	_add(_make(ItemId.Id.GREAT_BALL, "Super Ball", ItemPocket.Id.BALLS, 600,
		"Una Ball con más éxito que la Poké Ball."))
	_add(_make(ItemId.Id.ULTRA_BALL, "Ultra Ball", ItemPocket.Id.BALLS, 800,
		"Una Ball con aún más éxito que la Super Ball."))

	_add(_make(ItemId.Id.POTION, "Poción", ItemPocket.Id.MEDICINE, 200,
		"Restaura 20 PS de un Pokémon."))
	_add(_make(ItemId.Id.SUPER_POTION, "Superpoción", ItemPocket.Id.MEDICINE, 700,
		"Restaura 60 PS de un Pokémon."))
	_add(_make(ItemId.Id.HYPER_POTION, "Hiperpoción", ItemPocket.Id.MEDICINE, 1500,
		"Restaura 120 PS de un Pokémon."))
	_add(_make(ItemId.Id.FULL_RESTORE, "Restau. Todo", ItemPocket.Id.MEDICINE, 3000,
		"Restaura todos los PS y cura los problemas de estado."))

	_add(_make(ItemId.Id.ANTIDOTE, "Antídoto", ItemPocket.Id.MEDICINE, 200,
		"Cura el envenenamiento."))
	_add(_make(ItemId.Id.AWAKENING, "Despertar", ItemPocket.Id.MEDICINE, 100,
		"Despierta a un Pokémon dormido."))
	_add(_make(ItemId.Id.PARALYZE_HEAL, "Antiparaliz", ItemPocket.Id.MEDICINE, 200,
		"Cura la parálisis."))
	_add(_make(ItemId.Id.BURN_HEAL, "Antiquemar", ItemPocket.Id.MEDICINE, 200,
		"Cura las quemaduras."))
	_add(_make(ItemId.Id.ICE_HEAL, "Antihielo", ItemPocket.Id.MEDICINE, 200,
		"Descongela a un Pokémon."))
	_add(_make(ItemId.Id.FULL_HEAL, "Cura total", ItemPocket.Id.MEDICINE, 400,
		"Cura cualquier problema de estado."))
	_add(_make(ItemId.Id.REVIVE, "Revivir", ItemPocket.Id.MEDICINE, 2000,
		"Revive a un Pokémon debilitado con la mitad de sus PS."))
	_add(_make(ItemId.Id.MAX_REVIVE, "Max Revivir", ItemPocket.Id.MEDICINE, 4000,
		"Revive a un Pokémon debilitado con todos sus PS."))

	_add(_make(ItemId.Id.RARE_CANDY, "Carameloraro", ItemPocket.Id.ITEMS, 0,
		"Sube un nivel a un Pokémon."))
	_add(_make(ItemId.Id.ESCAPE_ROPE, "Cuerda Huida", ItemPocket.Id.ITEMS, 1000,
		"Permite escapar de cuevas y lugares similares."))
	_add(_make(ItemId.Id.REPEL, "Repelente", ItemPocket.Id.ITEMS, 400,
		"Repele Pokémon salvajes débiles un tiempo."))
	_add(_make(ItemId.Id.SUPER_REPEL, "Superrepelente", ItemPocket.Id.ITEMS, 700,
		"Repele Pokémon salvajes débiles más tiempo."))
	_add(_make(ItemId.Id.MAX_REPEL, "Máx. Repelente", ItemPocket.Id.ITEMS, 900,
		"Repele Pokémon salvajes débiles mucho más tiempo."))


func _make(
		id: ItemId.Id,
		name: String,
		pocket: ItemPocket.Id,
		price: int,
		description: String,
		stack_limit: int = 999,
		important: bool = false
	) -> ItemData:
	var data := ItemData.new()
	data.id = id
	data.display_name = name
	data.pocket = pocket
	data.price = price
	data.description = description
	data.stack_limit = stack_limit
	data.important = important
	return data


func _add(data: ItemData) -> void:
	if data == null or not data.is_valid():
		push_warning("ItemCatalog: entrada inválida")
		return
	_by_id[data.id] = data
