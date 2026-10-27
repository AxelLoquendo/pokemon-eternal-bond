class_name MapSection
extends RefCounted

enum MapID {
	NONE,
	MAPSEC_PRADO_NATAL,
	MAPSEC_PUEBLO_ALBA,
}

enum RegionID {
	NONE,
	VALTHERION,
	KANTO,
	JHOTO,
	HOENN,
	SINNOH,
	TESELIA,
	KALOS,
	ALOLA,
	GALAR,
	PALDEA
}

const MAP_SCENES: Dictionary = {
	MapID.NONE: "",
	MapID.MAPSEC_PRADO_NATAL: "res://Escenas/Overworld/Map/Prado_Natal/prado_natal.tscn",
	MapID.MAPSEC_PUEBLO_ALBA: "res://Escenas/Overworld/Map/Pueblo_Alba/pueblo_alba.tscn",
}

static func path_for(id: MapID) -> String:
	return MAP_SCENES.get(id, "") as String
