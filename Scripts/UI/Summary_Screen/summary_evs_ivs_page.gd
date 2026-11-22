extends Node2D
## Página IVs / EVs + naturaleza (abreviaturas At. Esp, Def. Esp, Vel.…).

@onready var _hp_iv: Label = $Evs_Ivs_Box/Hp_IV
@onready var _hp_ev: Label = $Evs_Ivs_Box/Hp_EV
@onready var _atk_iv: Label = $Evs_Ivs_Box/Attack_IV
@onready var _atk_ev: Label = $Evs_Ivs_Box/Attack_EV
@onready var _def_iv: Label = $Evs_Ivs_Box/Defense_IV
@onready var _def_ev: Label = $Evs_Ivs_Box/Defense_EV
@onready var _spa_iv: Label = $Evs_Ivs_Box/Sp_At_IV
@onready var _spa_ev: Label = $Evs_Ivs_Box/Sp_At_EV
@onready var _spd_iv: Label = $Evs_Ivs_Box/Sp_Def_IV
@onready var _spd_ev: Label = $Evs_Ivs_Box/Sp_Def_EV
@onready var _spe_iv: Label = $Evs_Ivs_Box/Speed_IV
@onready var _spe_ev: Label = $Evs_Ivs_Box/Speed_EV
@onready var _tot_iv: Label = $Evs_Ivs_Box/Total_IV
@onready var _tot_ev: Label = $Evs_Ivs_Box/Total_EV
@onready var _nature_name: Label = $Nature_Box/Nature_Name
@onready var _nature_up: Label = $Nature_Box/Skill_Name
@onready var _nature_down: Label = $Nature_Box/Skill_Name2


func bind(mon: PokemonInstance) -> void:
	if mon == null:
		return
	_set_pair(_hp_iv, _hp_ev, mon, PokemonEnums.Stat.HP)
	_set_pair(_atk_iv, _atk_ev, mon, PokemonEnums.Stat.ATK)
	_set_pair(_def_iv, _def_ev, mon, PokemonEnums.Stat.DEF)
	_set_pair(_spa_iv, _spa_ev, mon, PokemonEnums.Stat.SPA)
	_set_pair(_spd_iv, _spd_ev, mon, PokemonEnums.Stat.SPD)
	_set_pair(_spe_iv, _spe_ev, mon, PokemonEnums.Stat.SPE)

	var tiv: int = 0
	var tev: int = 0
	var stats: Array[PokemonEnums.Stat] = [
		PokemonEnums.Stat.HP,
		PokemonEnums.Stat.ATK,
		PokemonEnums.Stat.DEF,
		PokemonEnums.Stat.SPA,
		PokemonEnums.Stat.SPD,
		PokemonEnums.Stat.SPE,
	]
	for s: PokemonEnums.Stat in stats:
		tiv += mon._iv_for(s)
		tev += mon._ev_for(s)
	if _tot_iv:
		_tot_iv.text = str(tiv)
	if _tot_ev:
		_tot_ev.text = str(tev)

	if _nature_name:
		_nature_name.text = _nature_display_name(mon.nature)
	var boosts: Dictionary = _nature_boost_labels(mon.nature)
	if _nature_up:
		_nature_up.text = str(boosts.get("up", ""))
	if _nature_down:
		_nature_down.text = str(boosts.get("down", ""))


func _set_pair(iv_lbl: Label, ev_lbl: Label, mon: PokemonInstance, stat: PokemonEnums.Stat) -> void:
	if iv_lbl:
		iv_lbl.text = str(mon._iv_for(stat))
	if ev_lbl:
		ev_lbl.text = str(mon._ev_for(stat))


func _stat_abbr(stat: PokemonEnums.Stat) -> String:
	match stat:
		PokemonEnums.Stat.HP:
			return "PS"
		PokemonEnums.Stat.ATK:
			return "At"
		PokemonEnums.Stat.DEF:
			return "Def"
		PokemonEnums.Stat.SPA:
			return "At. Esp"
		PokemonEnums.Stat.SPD:
			return "Def. Esp"
		PokemonEnums.Stat.SPE:
			return "Vel"
		_:
			return "?"


func _nature_display_name(n: PokemonEnums.Nature) -> String:
	match n:
		PokemonEnums.Nature.HARDY:
			return "Fuerte"
		PokemonEnums.Nature.LONELY:
			return "Huraña"
		PokemonEnums.Nature.BRAVE:
			return "Audaz"
		PokemonEnums.Nature.ADAMANT:
			return "Firme"
		PokemonEnums.Nature.NAUGHTY:
			return "Pícara"
		PokemonEnums.Nature.BOLD:
			return "Osada"
		PokemonEnums.Nature.DOCILE:
			return "Dócil"
		PokemonEnums.Nature.RELAXED:
			return "Plácida"
		PokemonEnums.Nature.IMPISH:
			return "Agitada"
		PokemonEnums.Nature.LAX:
			return "Floja"
		PokemonEnums.Nature.TIMID:
			return "Miedosa"
		PokemonEnums.Nature.HASTY:
			return "Activa"
		PokemonEnums.Nature.SERIOUS:
			return "Seria"
		PokemonEnums.Nature.JOLLY:
			return "Alegre"
		PokemonEnums.Nature.NAIVE:
			return "Ingenua"
		PokemonEnums.Nature.MODEST:
			return "Modesta"
		PokemonEnums.Nature.MILD:
			return "Afable"
		PokemonEnums.Nature.QUIET:
			return "Mansa"
		PokemonEnums.Nature.BASHFUL:
			return "Tímida"
		PokemonEnums.Nature.RASH:
			return "Alocada"
		PokemonEnums.Nature.CALM:
			return "Serena"
		PokemonEnums.Nature.GENTLE:
			return "Amable"
		PokemonEnums.Nature.SASSY:
			return "Grosera"
		PokemonEnums.Nature.CAREFUL:
			return "Cauta"
		PokemonEnums.Nature.QUIRKY:
			return "Rara"
		_:
			return str(n)


func _nature_boost_labels(n: PokemonEnums.Nature) -> Dictionary:
	var up: PokemonEnums.Stat = PokemonInstance._nature_up(n)
	var down: PokemonEnums.Stat = PokemonInstance._nature_down(n)
	if up == down:
		return {"up": "", "down": ""}
	return {
		"up": "%s: ++" % _stat_abbr(up),
		"down": "%s: --" % _stat_abbr(down),
	}
