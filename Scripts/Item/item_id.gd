class_name ItemId
extends Object
## IDs de ítem. Tokens al estilo expansion (POTION, POKE_BALL).
## Set mínimo para scripts de overworld; se ampliará después.

enum Id {
	NONE = 0,
	POKE_BALL,
	GREAT_BALL,
	ULTRA_BALL,
	POTION,
	SUPER_POTION,
	HYPER_POTION,
	FULL_RESTORE,
	ANTIDOTE,
	AWAKENING,
	PARALYZE_HEAL,
	BURN_HEAL,
	ICE_HEAL,
	FULL_HEAL,
	REVIVE,
	MAX_REVIVE,
	RARE_CANDY,
	ESCAPE_ROPE,
	REPEL,
	SUPER_REPEL,
	MAX_REPEL,
}

const _TOKEN_TO_ID: Dictionary = {
	"POKE_BALL": Id.POKE_BALL,
	"POKEBALL": Id.POKE_BALL,
	"GREAT_BALL": Id.GREAT_BALL,
	"ULTRA_BALL": Id.ULTRA_BALL,
	"POTION": Id.POTION,
	"SUPER_POTION": Id.SUPER_POTION,
	"HYPER_POTION": Id.HYPER_POTION,
	"FULL_RESTORE": Id.FULL_RESTORE,
	"ANTIDOTE": Id.ANTIDOTE,
	"AWAKENING": Id.AWAKENING,
	"PARALYZE_HEAL": Id.PARALYZE_HEAL,
	"PARLYZ_HEAL": Id.PARALYZE_HEAL,
	"BURN_HEAL": Id.BURN_HEAL,
	"ICE_HEAL": Id.ICE_HEAL,
	"FULL_HEAL": Id.FULL_HEAL,
	"REVIVE": Id.REVIVE,
	"MAX_REVIVE": Id.MAX_REVIVE,
	"RARE_CANDY": Id.RARE_CANDY,
	"ESCAPE_ROPE": Id.ESCAPE_ROPE,
	"REPEL": Id.REPEL,
	"SUPER_REPEL": Id.SUPER_REPEL,
	"MAX_REPEL": Id.MAX_REPEL,
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


## Alias usado por script_cmd_give_item
static func to_key(id: Id) -> String:
	return to_token(id)
