extends Node
## Catálogo de habilidades. Set mínimo; luego import desde expansion.

var _by_id: Dictionary = {} # AbilityId.Id -> AbilityData


func _ready() -> void:
	_register_starter_set()


func get_ability(id: AbilityId.Id) -> AbilityData:
	return _by_id.get(id) as AbilityData


func has_ability(id: AbilityId.Id) -> bool:
	return _by_id.has(id)


func get_display_name(id: AbilityId.Id) -> String:
	var data: AbilityData = get_ability(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return AbilityId.to_token(id)


func _register_starter_set() -> void:
	_add(_make(AbilityId.Id.OVERGROW, "Espesura",
		"Potencia los movimientos de tipo Planta del Pokémon cuando le quedan pocos PS."))
	_add(_make(AbilityId.Id.BLAZE, "Mar Llamas",
		"Potencia los movimientos de tipo Fuego del Pokémon cuando le quedan pocos PS."))
	_add(_make(AbilityId.Id.TORRENT, "Torrente",
		"Potencia los movimientos de tipo Agua del Pokémon cuando le quedan pocos PS."))
	_add(_make(AbilityId.Id.STATIC, "Elec. Estática",
		"Puede paralizar al rival al contacto."))
	_add(_make(AbilityId.Id.LIGHTNING_ROD, "Pararrayos",
		"Atrae y anula movimientos Eléctricos y sube el Ataque Especial."))
	_add(_make(AbilityId.Id.CHLOROPHYLL, "Clorofila",
		"Duplica la Velocidad con sol intenso."))
	_add(_make(AbilityId.Id.THICK_FAT, "Sebo",
		"Reduce el daño de movimientos de Fuego y Hielo."))
	_add(_make(AbilityId.Id.SOLAR_POWER, "Poder Solar",
		"Con sol intenso sube el Ataque Especial, pero pierde PS cada turno."))
	_add(_make(AbilityId.Id.LEVITATE, "Levitación",
		"Inmune a movimientos de tipo Tierra."))
	_add(_make(AbilityId.Id.PRESSURE, "Presión",
		"Hace que el rival gaste 1 PP extra al usar un movimiento."))
	_add(_make(AbilityId.Id.INTIMIDATE, "Intimidación",
		"Baja el Ataque del rival al entrar en combate."))
	_add(_make(AbilityId.Id.HUGE_POWER, "Potencia",
		"Duplica el Ataque."))
	_add(_make(AbilityId.Id.WONDER_GUARD, "Superguarda",
		"Solo recibe daño de movimientos supereficaces."))
	_add(_make(AbilityId.Id.TABLETS_OF_RUIN, "Tablilla Debacle",
		"Reduce el Ataque de todos los Pokémon excepto el de esta habilidad."))


func _make(id: AbilityId.Id, name: String, description: String) -> AbilityData:
	var data := AbilityData.new()
	data.id = id
	data.display_name = name
	data.description = description
	return data


func _add(data: AbilityData) -> void:
	if data == null or not data.is_valid():
		push_warning("AbilityCatalog: entrada inválida")
		return
	_by_id[data.id] = data
