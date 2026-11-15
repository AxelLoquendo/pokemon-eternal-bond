class_name LevelUpMove
extends Resource
## Entrada de learnset por nivel. Mejor en Inspector que Dictionary suelto.

@export var level: int = 1
@export var move: MoveId.Id = MoveId.Id.NONE
