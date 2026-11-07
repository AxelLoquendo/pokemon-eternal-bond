extends Node
## Catálogo de movimientos. Set mínimo alineado al set de species de prueba.

var _by_id: Dictionary = {} # MoveId.Id -> MoveData


func _ready() -> void:
	_register_starter_set()


func get_move(id: MoveId.Id) -> MoveData:
	return _by_id.get(id) as MoveData


func has_move(id: MoveId.Id) -> bool:
	return _by_id.has(id)


func get_display_name(id: MoveId.Id) -> String:
	var data: MoveData = get_move(id)
	if data != null and not data.display_name.is_empty():
		return data.display_name
	return MoveId.to_token(id)


func _register_starter_set() -> void:
	_add(_make(MoveId.Id.TACKLE, "Placaje", TypeId.Id.NORMAL, MoveCategory.Id.PHYSICAL,
		40, 100, 35, 0, true, "Embiste al rival."))
	_add(_make(MoveId.Id.GROWL, "Gruñido", TypeId.Id.NORMAL, MoveCategory.Id.STATUS,
		0, 100, 40, 0, false, "Baja el Ataque del rival."))
	_add(_make(MoveId.Id.SCRATCH, "Arañazo", TypeId.Id.NORMAL, MoveCategory.Id.PHYSICAL,
		40, 100, 35, 0, true, "Araña al rival con garras."))
	_add(_make(MoveId.Id.TAIL_WHIP, "Látigo", TypeId.Id.NORMAL, MoveCategory.Id.STATUS,
		0, 100, 30, 0, false, "Baja la Defensa del rival."))
	_add(_make(MoveId.Id.EMBER, "Ascuas", TypeId.Id.FIRE, MoveCategory.Id.SPECIAL,
		40, 100, 25, 0, false, "Pequeñas llamas. Puede quemar."))
	_add(_make(MoveId.Id.VINE_WHIP, "Látigo Cepa", TypeId.Id.GRASS, MoveCategory.Id.PHYSICAL,
		45, 100, 25, 0, true, "Azota con lianas."))
	_add(_make(MoveId.Id.WATER_GUN, "Pistola Agua", TypeId.Id.WATER, MoveCategory.Id.SPECIAL,
		40, 100, 25, 0, false, "Dispara un chorro de agua."))
	_add(_make(MoveId.Id.THUNDER_SHOCK, "Impactrueno", TypeId.Id.ELECTRIC, MoveCategory.Id.SPECIAL,
		40, 100, 30, 0, false, "Descarga eléctrica. Puede paralizar."))
	_add(_make(MoveId.Id.QUICK_ATTACK, "Ataque Rápido", TypeId.Id.NORMAL, MoveCategory.Id.PHYSICAL,
		40, 100, 30, 1, true, "Golpe prioritario."))
	_add(_make(MoveId.Id.RAZOR_LEAF, "Hoja Afilada", TypeId.Id.GRASS, MoveCategory.Id.PHYSICAL,
		55, 95, 25, 0, false, "Hojas cortantes. Alto índice de crítico."))
	_add(_make(MoveId.Id.FLAMETHROWER, "Lanzallamas", TypeId.Id.FIRE, MoveCategory.Id.SPECIAL,
		90, 100, 15, 0, false, "Fuego intenso. Puede quemar."))
	_add(_make(MoveId.Id.THUNDERBOLT, "Rayo", TypeId.Id.ELECTRIC, MoveCategory.Id.SPECIAL,
		90, 100, 15, 0, false, "Potente descarga. Puede paralizar."))
	_add(_make(MoveId.Id.SOLAR_BEAM, "Rayo Solar", TypeId.Id.GRASS, MoveCategory.Id.SPECIAL,
		120, 100, 10, 0, false, "Carga un turno y dispara un rayo de luz."))
	_add(_make(MoveId.Id.AIR_SLASH, "Tajo Aéreo", TypeId.Id.FLYING, MoveCategory.Id.SPECIAL,
		75, 95, 15, 0, false, "Cuchilla de aire. Puede hacer retroceder."))
	_add(_make(MoveId.Id.DRAGON_CLAW, "Garra Dragón", TypeId.Id.DRAGON, MoveCategory.Id.PHYSICAL,
		80, 100, 15, 0, true, "Arañazo poderoso de tipo Dragón."))
	_add(_make(MoveId.Id.POISON_STING, "Picotazo Veneno", TypeId.Id.POISON, MoveCategory.Id.PHYSICAL,
		15, 100, 35, 0, true, "Puede envenenar."))
	_add(_make(MoveId.Id.DOUBLE_KICK, "Doble Patada", TypeId.Id.FIGHTING, MoveCategory.Id.PHYSICAL,
		30, 100, 30, 0, true, "Golpea dos veces."))
	_add(_make(MoveId.Id.RUINATION, "Calamidad", TypeId.Id.DARK, MoveCategory.Id.SPECIAL,
		1, 90, 10, 0, false, "Reduce los PS del rival a la mitad."))


func _make(
		id: MoveId.Id,
		name: String,
		type: TypeId.Id,
		category: MoveCategory.Id,
		power: int,
		accuracy: int,
		pp: int,
		priority: int,
		contact: bool,
		description: String
	) -> MoveData:
	var data := MoveData.new()
	data.id = id
	data.display_name = name
	data.type = type
	data.category = category
	data.power = power
	data.accuracy = accuracy
	data.pp = pp
	data.priority = priority
	data.makes_contact = contact
	data.description = description
	return data


func _add(data: MoveData) -> void:
	if data == null or not data.is_valid():
		push_warning("MoveCatalog: entrada inválida")
		return
	_by_id[data.id] = data
