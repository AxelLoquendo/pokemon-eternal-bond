extends Node
## Menú debug in-game (estilo pokeemerald), vía MessageService multichoice.
## Abrir con buttonSelect en el overworld.

var _busy: bool = false


func is_busy() -> bool:
	return _busy


func open_menu() -> void:
	if _busy:
		return
	if MessageService and MessageService.is_active():
		return
	_busy = true
	await _root()
	_busy = false


func _root() -> void:
	MessageService.show_texts(
		["— DEBUG —"],
		"",
		["Party", "Curar equipo", "Dinero +99999", "Cerrar"]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			await _party_menu()
		1:
			_heal()
			MessageService.show_texts(["Equipo curado."])
			await MessageService.message_finished
		2:
			_add_money(99999)
			MessageService.show_texts(["Dinero +99999."])
			await MessageService.message_finished
		_:
			pass


func _party_menu() -> void:
	MessageService.show_texts(
		["Party debug"],
		"",
		[
			"Equipo starters (Nv.5)",
			"Equipo prueba (6)",
			"Añadir 1 mon (fin del party)",
			"Vaciar party",
			"Atrás",
		]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			_set_team(_team_starters())
			MessageService.show_texts(["Party: 3 starters Nv.5."])
			await MessageService.message_finished
		1:
			_set_team(_team_test_six())
			MessageService.show_texts(["Party: equipo de prueba (6)."])
			await MessageService.message_finished
		2:
			await _add_one_menu()
		3:
			_clear_party()
			MessageService.show_texts(["Party vaciado."])
			await MessageService.message_finished
		_:
			await _root()


func _add_one_menu() -> void:
	MessageService.show_texts(
		["¿Qué mon añadir?"],
		"",
		["Bulbasaur", "Charmander", "Squirtle", "Pikachu", "Lucario", "Atrás"]
	)
	await MessageService.message_finished
	var choice: int = MessageService.get_last_choice()
	var map: Array = [
		SpeciesId.Id.BULBASAUR,
		SpeciesId.Id.CHARMANDER,
		SpeciesId.Id.SQUIRTLE,
		SpeciesId.Id.PIKACHU,
		SpeciesId.Id.LUCARIO,
	]
	if choice < 0 or choice >= map.size():
		await _party_menu()
		return
	var ok: bool = _add_one(map[choice] as SpeciesId.Id, 20)
	if ok:
		MessageService.show_texts(["Añadido al party."])
	else:
		MessageService.show_texts(["No se pudo añadir (party lleno o error)."])
	await MessageService.message_finished


func _player_data() -> PlayerData:
	return BagService.player_data_from_tree(get_tree())


func _ot() -> String:
	if NewGameState != null and not NewGameState.player_name.is_empty():
		return NewGameState.player_name
	return "DEBUG"


func _make_mon(species: SpeciesId.Id, level: int) -> PokemonInstance:
	var m: PokemonInstance = PokemonInstance.create(species, level, true, true)
	if m == null:
		return null
	m.ot_name = _ot()
	m.met_location = "Debug"
	m.met_level = level
	m.ball = ItemId.Id.POKE_BALL
	m.resolve_ability_from_species()
	m.recalculate_stats()
	m.hp = m.max_hp
	return m


func _set_team(entries: Array) -> void:
	var pd: PlayerData = _player_data()
	if pd == null:
		push_warning("DebugMenu: sin PlayerData en player.character")
		return
	pd.party.clear()
	for e: Variant in entries:
		if not (e is Array) or e.size() < 2:
			continue
		var mon: PokemonInstance = _make_mon(e[0] as SpeciesId.Id, int(e[1]))
		if mon != null:
			pd.add_pokemon(mon)


func _add_one(species: SpeciesId.Id, level: int) -> bool:
	var pd: PlayerData = _player_data()
	if pd == null:
		return false
	var mon: PokemonInstance = _make_mon(species, level)
	if mon == null:
		return false
	return pd.add_pokemon(mon)


func _clear_party() -> void:
	var pd: PlayerData = _player_data()
	if pd == null:
		return
	pd.party.clear()


func _heal() -> void:
	var pd: PlayerData = _player_data()
	if pd != null:
		pd.heal_party()


func _add_money(amount: int) -> void:
	var pd: PlayerData = _player_data()
	if pd != null:
		pd.money = int(pd.money) + amount


func _team_starters() -> Array:
	return [
		[SpeciesId.Id.BULBASAUR, 5],
		[SpeciesId.Id.CHARMANDER, 5],
		[SpeciesId.Id.SQUIRTLE, 5],
	]


func _team_test_six() -> Array:
	return [
		[SpeciesId.Id.VENUSAUR, 36],
		[SpeciesId.Id.CHARIZARD, 36],
		[SpeciesId.Id.BLASTOISE, 36],
		[SpeciesId.Id.PIKACHU, 25],
		[SpeciesId.Id.LUCARIO, 40],
		[SpeciesId.Id.GARCHOMP, 50],
	]
