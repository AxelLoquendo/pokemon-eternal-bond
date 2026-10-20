extends Node

enum owID {
	OBJ_EVENT_NONE,
	OBJ_EVENT_KAEL_WALK,
	OBJ_EVENT_KAEL_RUN,
	OBJ_EVENT_KAIDA_WALK,
	OBJ_EVENT_KAIDA_RUN,
}

const owSprite: Dictionary = {
	owID.OBJ_EVENT_NONE: "",
	owID.OBJ_EVENT_KAEL_WALK: "res://Graficos/Object_Event/player/male/kael/normal.png",
	owID.OBJ_EVENT_KAIDA_WALK: "res://Graficos/Object_Event/player/female/kaida/normal.png",
}

enum shadowID {
	NONE,
	S,
	M,
	L,
	XL
}

const shadowSprite: Dictionary = {
	shadowID.NONE: "",
	shadowID.S: "res://Graficos/Object_Event/shadow/shadow_small.png",
	shadowID.M: "res://Graficos/Object_Event/shadow/shadow_medium.png",
	shadowID.L: "res://Graficos/Object_Event/shadow/shadow_large.png",
	shadowID.XL: "res://Graficos/Object_Event/shadow/shadow_extra_large.png"
}
