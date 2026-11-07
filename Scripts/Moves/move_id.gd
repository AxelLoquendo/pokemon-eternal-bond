class_name MoveId
extends Object
## Movimientos. Tokens al estilo expansion (TACKLE, EMBER…).

enum Id {
	NONE = 0,
	TACKLE,
	GROWL,
	SCRATCH,
	TAIL_WHIP,
	EMBER,
	VINE_WHIP,
	WATER_GUN,
	THUNDER_SHOCK,
	QUICK_ATTACK,
	RAZOR_LEAF,
	FLAMETHROWER,
	THUNDERBOLT,
	SOLAR_BEAM,
	AIR_SLASH,
	DRAGON_CLAW,
	POISON_STING,
	DOUBLE_KICK,
	RUINATION, ## Wo-Chien signature-ish placeholder
}

const _TOKEN_TO_ID: Dictionary = {
	"TACKLE": Id.TACKLE,
	"GROWL": Id.GROWL,
	"SCRATCH": Id.SCRATCH,
	"TAIL_WHIP": Id.TAIL_WHIP,
	"TAILWHIP": Id.TAIL_WHIP,
	"EMBER": Id.EMBER,
	"VINE_WHIP": Id.VINE_WHIP,
	"VINEWHIP": Id.VINE_WHIP,
	"WATER_GUN": Id.WATER_GUN,
	"WATERGUN": Id.WATER_GUN,
	"THUNDER_SHOCK": Id.THUNDER_SHOCK,
	"THUNDERSHOCK": Id.THUNDER_SHOCK,
	"QUICK_ATTACK": Id.QUICK_ATTACK,
	"QUICKATTACK": Id.QUICK_ATTACK,
	"RAZOR_LEAF": Id.RAZOR_LEAF,
	"RAZORLEAF": Id.RAZOR_LEAF,
	"FLAMETHROWER": Id.FLAMETHROWER,
	"THUNDERBOLT": Id.THUNDERBOLT,
	"SOLAR_BEAM": Id.SOLAR_BEAM,
	"SOLARBEAM": Id.SOLAR_BEAM,
	"AIR_SLASH": Id.AIR_SLASH,
	"AIRSLASH": Id.AIR_SLASH,
	"DRAGON_CLAW": Id.DRAGON_CLAW,
	"DRAGONCLAW": Id.DRAGON_CLAW,
	"POISON_STING": Id.POISON_STING,
	"POISONSTING": Id.POISON_STING,
	"DOUBLE_KICK": Id.DOUBLE_KICK,
	"DOUBLEKICK": Id.DOUBLE_KICK,
	"RUINATION": Id.RUINATION,
}


static func from_token(token: String) -> Id:
	var key: String = token.strip_edges().to_upper().replace("-", "_").replace(" ", "_")
	if key.is_empty():
		return Id.NONE
	return _TOKEN_TO_ID.get(key, Id.NONE) as Id


static func to_token(id: Id) -> String:
	if id == Id.NONE:
		return ""
	return Id.keys()[id]
