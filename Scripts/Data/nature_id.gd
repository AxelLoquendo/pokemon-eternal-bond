extends Object
class_name NatureId
## Las 25 natures. Stats afectadas: atk, def, spa, spd, spe (HP nunca).

enum Id {
	NONE = 0,
	HARDY,
	LONELY,
	BRAVE,
	ADAMANT,
	NAUGHTY,
	BOLD,
	DOCILE,
	RELAXED,
	IMPISH,
	LAX,
	TIMID,
	HASTY,
	SERIOUS,
	JOLLY,
	NAIVE,
	MODEST,
	MILD,
	QUIET,
	BASHFUL,
	RASH,
	CALM,
	GENTLE,
	SASSY,
	CAREFUL,
	QUIRKY,
}

# nature -> { "up": "atk", "down": "def" }  (vacío = neutral)
const _EFFECT: Dictionary = {
	Id.LONELY: { "up": "atk", "down": "def" },
	Id.BRAVE: { "up": "atk", "down": "spe" },
	Id.ADAMANT: { "up": "atk", "down": "spa" },
	Id.NAUGHTY: { "up": "atk", "down": "spd" },
	Id.BOLD: { "up": "def", "down": "atk" },
	Id.RELAXED: { "up": "def", "down": "spe" },
	Id.IMPISH: { "up": "def", "down": "spa" },
	Id.LAX: { "up": "def", "down": "spd" },
	Id.TIMID: { "up": "spe", "down": "atk" },
	Id.HASTY: { "up": "spe", "down": "def" },
	Id.JOLLY: { "up": "spe", "down": "spa" },
	Id.NAIVE: { "up": "spe", "down": "spd" },
	Id.MODEST: { "up": "spa", "down": "atk" },
	Id.MILD: { "up": "spa", "down": "def" },
	Id.QUIET: { "up": "spa", "down": "spe" },
	Id.RASH: { "up": "spa", "down": "spd" },
	Id.CALM: { "up": "spd", "down": "atk" },
	Id.GENTLE: { "up": "spd", "down": "def" },
	Id.SASSY: { "up": "spd", "down": "spe" },
	Id.CAREFUL: { "up": "spd", "down": "spa" },
}


static func from_token(token: String) -> Id:
	return EnumTokens.parse(token, Id.keys(), Id.HARDY, "NatureId", true) as Id


static func to_key(id: Id) -> String:
	return EnumTokens.key(id, Id.keys(), Id.NONE, "HARDY")


static func random() -> Id:
	# HARDY..QUIRKY inclusive (sin NONE)
	return (randi_range(int(Id.HARDY), int(Id.QUIRKY))) as Id


## Multiplicador 0.9 / 1.0 / 1.1 para atk, def, spa, spd o spe.
static func multiplier(nature: Id, stat_key: String) -> float:
	var effect: Variant = _EFFECT.get(nature)
	if not effect is Dictionary:
		return 1.0
	var e: Dictionary = effect
	if str(e.get("up", "")) == stat_key:
		return 1.1
	if str(e.get("down", "")) == stat_key:
		return 0.9
	return 1.0
