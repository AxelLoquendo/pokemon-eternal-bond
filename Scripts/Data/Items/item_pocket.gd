extends Object
class_name ItemPocket

enum Id {
	ITEMS = 1,
	MEDICINE = 2,
	BALLS = 3,
	TMS = 4,
	BERRIES = 5,
	MAIL = 6,
	BATTLE = 7,
	KEY = 8,
}


static func from_pbs(n: int) -> Id:
	if n >= 1 and n <= 8:
		return n as Id
	return Id.ITEMS


static func from_token(token: String) -> Id:
	var t: String = token.strip_edges().to_upper()
	match t:
		"ITEMS", "1": return Id.ITEMS
		"MEDICINE", "2": return Id.MEDICINE
		"BALLS", "3": return Id.BALLS
		"TMS", "TM", "4": return Id.TMS
		"BERRIES", "5": return Id.BERRIES
		"MAIL", "6": return Id.MAIL
		"BATTLE", "7": return Id.BATTLE
		"KEY", "KEYITEMS", "8": return Id.KEY
		_: return Id.ITEMS
