extends Node2D
## Página Skills: stats, HP y EXP.
## Barras: la escala/tamaño del sprite en la escena = 100%. Se reduce con el %.

@onready var _hp_bar: Sprite2D = $Skills_Box/Hp_Bar
@onready var _hp_num: Label = $Skills_Box/HP_Number
@onready var _exp_bar: Sprite2D = $Skills_Box/Exp_Bar
@onready var _atk: Label = $Skills_Box/Attack_Number
@onready var _def: Label = $Skills_Box/Defense_Number
@onready var _spa: Label = $Skills_Box/Sp_At_Number
@onready var _spd: Label = $Skills_Box/Sp_Def_Number
@onready var _spe: Label = $Skills_Box/Speed_Number
@onready var _exp_points: Label = $Skills_Box/Exp_Point
@onready var _exp_next: Label = $Skills_Box/Exp_Next

## scale.x de la escena = barra llena
var _hp_full_scale_x: float = 1.0
var _exp_full_scale_x: float = 1.0
var _hp_base_pos: Vector2 = Vector2.ZERO
var _exp_base_pos: Vector2 = Vector2.ZERO
var _bars_ready: bool = false


func _ready() -> void:
	_cache_bar_bases()


func _cache_bar_bases() -> void:
	if _bars_ready:
		return
	if _hp_bar:
		_hp_full_scale_x = _hp_bar.scale.x
		_hp_base_pos = _hp_bar.position
		# Anclar desde la izquierda para que al escalar no se centre
		_hp_bar.centered = false
		# Si antes estaba centrado, la posición del editor era el centro:
		# con centered=false, el origen es la esquina; compensamos una vez.
		if _hp_bar.texture:
			var fw: float = float(_hp_bar.texture.get_width()) * _hp_full_scale_x
			_hp_bar.position = Vector2(_hp_base_pos.x - fw * 0.5, _hp_base_pos.y - float(_hp_bar.texture.get_height()) / float(maxi(1, _hp_bar.vframes)) * _hp_bar.scale.y * 0.5)
			_hp_base_pos = _hp_bar.position
	if _exp_bar:
		_exp_full_scale_x = _exp_bar.scale.x
		_exp_base_pos = _exp_bar.position
		_exp_bar.centered = false
		if _exp_bar.texture:
			var fw2: float = float(_exp_bar.texture.get_width()) * _exp_full_scale_x
			_exp_bar.position = Vector2(
				_exp_base_pos.x - fw2 * 0.5,
				_exp_base_pos.y - float(_exp_bar.texture.get_height()) * _exp_bar.scale.y * 0.5
			)
			_exp_base_pos = _exp_bar.position
	_bars_ready = true


func bind(mon: PokemonInstance) -> void:
	if mon == null:
		return
	_cache_bar_bases()
	mon.recalculate_stats()

	if _hp_num:
		_hp_num.text = "%d/%d" % [mon.hp, mon.max_hp]

	var hp_ratio: float = 1.0
	if mon.max_hp > 0:
		hp_ratio = clampf(float(mon.hp) / float(mon.max_hp), 0.0, 1.0)
	_set_hp_bar(hp_ratio)

	if _atk:
		_atk.text = str(mon.get_stat(PokemonEnums.Stat.ATK))
	if _def:
		_def.text = str(mon.get_stat(PokemonEnums.Stat.DEF))
	if _spa:
		_spa.text = str(mon.get_stat(PokemonEnums.Stat.SPA))
	if _spd:
		_spd.text = str(mon.get_stat(PokemonEnums.Stat.SPD))
	if _spe:
		_spe.text = str(mon.get_stat(PokemonEnums.Stat.SPE))

	var total: int = mon.exp_points
	var need: int = _exp_to_next(mon)
	if _exp_points:
		_exp_points.text = str(total)
	if _exp_next:
		_exp_next.text = str(need)
	_set_exp_bar(_exp_progress(mon))


func _set_hp_bar(ratio: float) -> void:
	if _hp_bar == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	if ratio > 0.5:
		_hp_bar.frame = 0
	elif ratio > 0.2:
		_hp_bar.frame = 1
	else:
		_hp_bar.frame = 2
	_hp_bar.scale.x = _hp_full_scale_x * ratio
	_hp_bar.position = _hp_base_pos
	_hp_bar.visible = ratio > 0.001


func _set_exp_bar(ratio: float) -> void:
	if _exp_bar == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	_exp_bar.scale.x = _exp_full_scale_x * ratio
	_exp_bar.position = _exp_base_pos
	_exp_bar.visible = ratio > 0.001


func _growth(mon: PokemonInstance) -> PokemonEnums.Growth:
	var data: SpeciesData = mon.species()
	if data != null:
		return data.growth_rate
	return PokemonEnums.Growth.MEDIUM_FAST


func _exp_at_level(growth: PokemonEnums.Growth, level: int) -> int:
	level = clampi(level, 1, 100)
	var n: float = float(level)
	match growth:
		PokemonEnums.Growth.MEDIUM_FAST:
			return int(n * n * n)
		PokemonEnums.Growth.FAST:
			return int(4.0 * n * n * n / 5.0)
		PokemonEnums.Growth.SLOW:
			return int(5.0 * n * n * n / 4.0)
		PokemonEnums.Growth.MEDIUM_SLOW:
			return int((6.0 / 5.0) * n * n * n - 15.0 * n * n + 100.0 * n - 140.0)
		PokemonEnums.Growth.ERRATIC:
			if level < 50:
				return int(n * n * n * (100.0 - n) / 50.0)
			if level < 68:
				return int(n * n * n * (150.0 - n) / 100.0)
			if level < 98:
				return int(n * n * n * ((1911.0 - 10.0 * n) / 3.0) / 500.0)
			return int(n * n * n * (160.0 - n) / 100.0)
		PokemonEnums.Growth.FLUCTUATING:
			if level < 15:
				return int(n * n * n * ((n + 1.0) / 3.0 + 24.0) / 50.0)
			if level < 36:
				return int(n * n * n * (n + 14.0) / 50.0)
			return int(n * n * n * ((n / 2.0) + 32.0) / 50.0)
		_:
			return int(n * n * n)


func _exp_to_next(mon: PokemonInstance) -> int:
	if mon.level >= 100:
		return 0
	var g: PokemonEnums.Growth = _growth(mon)
	var next_total: int = _exp_at_level(g, mon.level + 1)
	return maxi(0, next_total - mon.exp_points)


func _exp_progress(mon: PokemonInstance) -> float:
	if mon.level >= 100:
		return 1.0
	var g: PokemonEnums.Growth = _growth(mon)
	var cur_floor: int = _exp_at_level(g, mon.level)
	var next_total: int = _exp_at_level(g, mon.level + 1)
	var span: int = maxi(1, next_total - cur_floor)
	return clampf(float(mon.exp_points - cur_floor) / float(span), 0.0, 1.0)
