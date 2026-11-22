extends Node2D

const category_slot: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_"

const category_slot_move: Dictionary = {
	MoveCategory.Id.SPECIAL: "special_box",
	MoveCategory.Id.STATUS: "status_box",
	MoveCategory.Id.PHYSICAL: "physical_box"
}

const type_slot: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_box_"

const type_slot_move: Dictionary = {
	TypeId.Id.NONE: "",
	TypeId.Id.NORMAL: "normal",
	TypeId.Id.FIGHTING: "fighting",
	TypeId.Id.FLYING: "flying",
	TypeId.Id.POISON: "poison",
	TypeId.Id.GROUND: "ground",
	TypeId.Id.ROCK: "rock",
	TypeId.Id.BUG: "bug",
	TypeId.Id.GHOST: "ghost",
	TypeId.Id.STEEL: "steel",
	TypeId.Id.MYSTERY: "mystery",
	TypeId.Id.FIRE: "fire",
	TypeId.Id.WATER: "water",
	TypeId.Id.GRASS: "grass",
	TypeId.Id.ELECTRIC: "electric",
	TypeId.Id.PSYCHIC: "psychic",
	TypeId.Id.ICE: "ice",
	TypeId.Id.DRAGON: "dragon",
	TypeId.Id.DARK: "dark",
	TypeId.Id.FAIRY: "fairy"
}

@onready var moves_slot: Array[Node2D] = [
	$Move_Box/Slot_1,
	$Move_Box/Slot_2,
	$Move_Box/Slot_3,
	$Move_Box/Slot_4
]
@onready var move_1_category: Sprite2D = $Move_Box/Slot_1/Category
@onready var move_2_category: Sprite2D = $Move_Box/Slot_2/Category
@onready var move_3_category: Sprite2D = $Move_Box/Slot_3/Category
@onready var move_4_category: Sprite2D = $Move_Box/Slot_4/Category

@onready var move_1_type: Sprite2D = $Move_Box/Slot_1/Move_Type
@onready var move_2_type: Sprite2D = $Move_Box/Slot_2/Move_Type
@onready var move_3_type: Sprite2D = $Move_Box/Slot_3/Move_Type
@onready var move_4_type: Sprite2D = $Move_Box/Slot_4/Move_Type
