extends Node
## Debug in-game (inspirado en pokeemerald-expansion src/debug.c).
## Select en overworld. Multichoice vía MessageService.

var _busy: bool = false
var _give_shiny: bool = false
var _give_level: int = 20


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
		["Party", "Dar Pokémon", "Curar equipo", "Dinero +99999", "Cerrar"]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			await _party_menu()
		1:
			await _give_pokemon_flow()
		2:
			_heal()
			MessageService.show_texts(["Equipo curado. Party: %d/6." % _party_count()])
			await MessageService.message_finished
		3:
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
			"Vaciar party",
			"Atrás",
		]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			_set_team(_team_starters())
			MessageService.show_texts(["Party starters: %d mons." % _party_count()])
			await MessageService.message_finished
		1:
			_set_team(_team_test_six())
			MessageService.show_texts(["Party prueba: %d mons." % _party_count()])
			await MessageService.message_finished
		2:
			_clear_party()
			MessageService.show_texts(["Party vaciado."])
			await MessageService.message_finished
		_:
			await _root()


func _give_pokemon_flow() -> void:
	MessageService.show_texts(
		["Dar Pokémon"],
		"",
		["Elegir especie", "Nivel: %d" % _give_level, "Shiny: %s" % ("Sí" if _give_shiny else "No"), "Confirmar", "Atrás"]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			await _pick_species_and_give()
		1:
			await _pick_level()
			await _give_pokemon_flow()
		2:
			_give_shiny = not _give_shiny
			await _give_pokemon_flow()
		3:
			MessageService.show_texts(["Elige especie primero (opción 1)."])
			await MessageService.message_finished
			await _give_pokemon_flow()
		_:
			await _root()


func _pick_level() -> void:
	MessageService.show_texts(
		["Nivel del Pokémon"],
		"",
		["5", "20", "50", "100", "Atrás"]
	)
	await MessageService.message_finished
	match MessageService.get_last_choice():
		0:
			_give_level = 5
		1:
			_give_level = 20
		2:
			_give_level = 50
		3:
			_give_level = 100
		_:
			pass


func _pick_species_and_give() -> void:
	## Lista corta + “más” con especies frecuentes (como debug emerald: selección simple).
	var options: Array[String] = [
		"Bulbasaur", "Charmander", "Squirtle", "Pikachu",
		"Eevee", "Lucario", "Garchomp", "Más…", "Atrás"
	]
	var ids: Array = [
		SpeciesId.Id.BULBASAUR,
		SpeciesId.Id.CHARMANDER,
		SpeciesId.Id.SQUIRTLE,
		SpeciesId.Id.PIKACHU,
		SpeciesId.Id.EEVEE,
		SpeciesId.Id.LUCARIO,
		SpeciesId.Id.GARCHOMP,
	]
	MessageService.show_texts(["Especie"], "", options)
	await MessageService.message_finished
	var c: int = MessageService.get_last_choice()
	if c < 0 or c >= options.size() - 1:
		await _give_pokemon_flow()
		return
	if c == options.size() - 2:
		await _pick_species_more()
		return
	_give_one(ids[c] as SpeciesId.Id, _give_level, _give_shiny)


func _pick_species_more() -> void:
	var options: Array[String] = [
		"Venusaur", "Charizard", "Blastoise", "Mewtwo",
		"Rayquaza", "Terapagos", "Atrás"
	]
	var ids: Array = [
		SpeciesId.Id.VENUSAUR,
		SpeciesId.Id.CHARIZARD,
		SpeciesId.Id.BLASTOISE,
		SpeciesId.Id.MEWTWO,
		SpeciesId.Id.RAYQUAZA,
		SpeciesId.Id.TERAPAGOS_NORMAL,
	]
	MessageService.show_texts(["Más especies"], "", options)
	await MessageService.message_finished
	var c: int = MessageService.get_last_choice()
	if c < 0 or c >= ids.size():
		await _give_pokemon_flow()
		return
	_give_one(ids[c] as SpeciesId.Id, _give_level, _give_shiny)


func _give_one(species: SpeciesId.Id, level: int, shiny: bool) -> void:
	var pd: PlayerData = _player_data()
	if pd == null:
		MessageService.show_texts(["Error: sin PlayerData."])
		await MessageService.message_finished
		return
	if pd.party_is_full():
		MessageService.show_texts(["Party lleno (6/6)."])
		await MessageService.message_finished
		return
	var mon: PokemonInstance = _make_mon(species, level, shiny)
	if mon == null:
		MessageService.show_texts(["Error al crear el mon."])
		await MessageService.message_finished
		return
	if pd.add_pokemon(mon):
		var name: String = mon.display_name()
		MessageService.show_texts(["¡%s añadido! Party: %d/6." % [name, pd.party_count()]])
	else:
		MessageService.show_texts(["No se pudo añadir."])
	await MessageService.message_finished


func _player_data() -> PlayerData:
	return BagService.ensure_player_data(get_tree())


func _ot() -> String:
	if NewGameState != null and not NewGameState.player_name.is_empty():
		return NewGameState.player_name
	return "DEBUG"


func _make_mon(species: SpeciesId.Id, level: int, shiny: bool = false) -> PokemonInstance:
	var m: PokemonInstance = PokemonInstance.create(species, level, true, true)
	if m == null:
		return null
	m.is_shiny = shiny
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
		push_warning("DebugMenu: sin PlayerData")
		return
	pd.party.clear()
	for e: Variant in entries:
		if not (e is Array) or e.size() < 2:
			continue
		var mon: PokemonInstance = _make_mon(e[0] as SpeciesId.Id, int(e[1]), false)
		if mon != null:
			pd.add_pokemon(mon)


func _clear_party() -> void:
	var pd: PlayerData = _player_data()
	if pd:
		pd.party.clear()


func _heal() -> void:
	var pd: PlayerData = _player_data()
	if pd:
		pd.heal_party()


func _add_money(amount: int) -> void:
	var pd: PlayerData = _player_data()
	if pd:
		pd.money = int(pd.money) + amount


func _party_count() -> int:
	var pd: PlayerData = _player_data()
	return pd.party_count() if pd else 0


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
