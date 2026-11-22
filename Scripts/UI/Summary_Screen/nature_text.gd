class_name NatureText
extends Object
## Nombres y abreviaturas de stats/naturalezas para el summary.

static func stat_abbr(stat: PokemonEnums.Stat) -> String:
	match stat:
		PokemonEnums.Stat.HP:
			return "PS"
		PokemonEnums.Stat.ATK:
			return "At."
		PokemonEnums.Stat.DEF:
			return "Def."
		PokemonEnums.Stat.SPA:
			return "At. Esp"
		PokemonEnums.Stat.SPD:
			return "Def. Esp"
		PokemonEnums.Stat.SPE:
			return "Vel."
		_:
			return "?"


static func nature_name(n: PokemonEnums.Nature) -> String:
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


## Textos "At. Esp: ++" / "Def.: --". Neutral → ambas "".
static func nature_boost_labels(n: PokemonEnums.Nature) -> Dictionary:
	var up: PokemonEnums.Stat = PokemonInstance._nature_up(n)
	var down: PokemonEnums.Stat = PokemonInstance._nature_down(n)
	if up == down:
		return {"up": "", "down": ""}
	return {
		"up": "%s: ++" % stat_abbr(up),
		"down": "%s: --" % stat_abbr(down),
	}
