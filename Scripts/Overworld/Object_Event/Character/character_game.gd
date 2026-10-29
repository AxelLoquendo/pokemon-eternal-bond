class_name CharacterGame
extends Resource

## "name" es el nombre mostrado del personaje (entrenador / NPC).
@export var name: String = ""
@export var id: StringName = &""
@export var walk: int = 0
@export var run: int = 0
@export var money: int = 0
@export var ow_sprite: ObjectEvent.owID = ObjectEvent.owID.OBJ_EVENT_NONE
@export var shadow_sprite: ObjectEvent.shadowID = ObjectEvent.shadowID.M
@export var shadow_position: Vector2 = Vector2(7.5, 11)
