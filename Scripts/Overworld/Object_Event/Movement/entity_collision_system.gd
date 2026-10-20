class_name EntityCollisionSystem
extends RefCounted

const TILE_SIZE: float = 16.0


static func to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(roundi(world_pos.x / TILE_SIZE), roundi(world_pos.y / TILE_SIZE))


static func is_position_occupied(
	position: Vector2,
	excluded: CharacterController = null
) -> bool:
	var target: Vector2i = to_tile(position)
	var groups: Array[StringName] = [&"Player", &"npc"]
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for group: StringName in groups:
		for entity: Node in tree.get_nodes_in_group(group):
			var cc: CharacterController = entity.get_node_or_null(
				"Controller/CharacterController"
			) as CharacterController
			if cc == null or cc == excluded:
				continue
			if to_tile(cc.current_position) == target:
				return true
			if cc.moving and to_tile(cc.target_position) == target:
				return true
	return false
