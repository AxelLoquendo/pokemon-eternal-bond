extends Node2D

const GRAPHICS_DIR: String = "res://Graficos/UI/Party_Menu/box_"

enum boxGender {
	BOX_F_NORMAL,
	BOX_F_SELECT,
	BOX_F_SWITCH,
	BOX_F_SWITCH_TWO,
	BOX_M_NORMAL,
	BOX_M_SELECT,
	BOX_M_SWITCH,
	BOX_M_SWITCH_TWO
}

const GRAPHICS_GENDER_BOX: Dictionary = {
	boxGender.BOX_F_NORMAL: "female_normal",
	boxGender.BOX_F_SELECT: "female_select",
	boxGender.BOX_F_SWITCH: "female_switch",
	boxGender.BOX_F_SWITCH_TWO: "female_switch_2",
	boxGender.BOX_M_NORMAL: "male_normal",
	boxGender.BOX_M_SELECT: "male_select",
	boxGender.BOX_M_SWITCH: "male_switch",
	boxGender.BOX_M_SWITCH_TWO: "male_switch_2"
}

@onready var hp_box: Sprite2D = $HP_Box
