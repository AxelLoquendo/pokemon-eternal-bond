class_name NPCData
extends CharacterGame

@export var id: StringName = &""
@export var behavior: Behavior = Behavior.NONE
@export_file("*.txt") var script_file: String = ""

enum Behavior {
	NONE,
	LOOK_AROUND,
	WANDER,
	PATROL,
	FOLLOW,
}
