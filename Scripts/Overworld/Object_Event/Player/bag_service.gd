class_name BagService
extends RefCounted


static func player_data_from_tree(tree: SceneTree) -> PlayerData:
	if tree == null:
		return null
	var session: Node = tree.get_first_node_in_group(&"game_session")
	if session == null:
		return null
	var player: Node = session.get_node_or_null("Player")
	if player == null:
		return null
	if "character" in player and player.character is PlayerData:
		return player.character as PlayerData
	return null


static func add(tree: SceneTree, id: ItemId.Id, amount: int = 1) -> int:
	var pd: PlayerData = player_data_from_tree(tree)
	if pd == null:
		push_warning("BagService: sin PlayerData")
		return 0
	return pd.add_item(id, amount)


static func count(tree: SceneTree, id: ItemId.Id) -> int:
	var pd: PlayerData = player_data_from_tree(tree)
	return pd.count_item(id) if pd else 0
