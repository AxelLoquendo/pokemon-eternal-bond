class_name BagService
extends RefCounted


static func player_data_from_tree(tree: SceneTree) -> PlayerData:
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group(&"Player")
	if player == null:
		var session: Node = tree.get_first_node_in_group(&"game_session")
		if session != null:
			player = session.get_node_or_null("Player")
	if player == null:
		return null
	var pd: Variant = player.get("character")
	if pd is PlayerData:
		return pd as PlayerData
	return null


## Si el Player no tiene character, crea uno mínimo y lo asigna.
static func ensure_player_data(tree: SceneTree) -> PlayerData:
	var pd: PlayerData = player_data_from_tree(tree)
	if pd != null:
		return pd
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group(&"Player")
	if player == null:
		var session: Node = tree.get_first_node_in_group(&"game_session")
		if session != null:
			player = session.get_node_or_null("Player")
	if player == null:
		push_warning("BagService: no hay nodo Player")
		return null
	pd = PlayerData.new()
	pd.name = NewGameState.player_name if NewGameState else "Player"
	pd.id = &"player"
	pd.walk = 4
	pd.run = 8
	pd.money = 0
	player.set("character", pd)
	return pd


static func add(tree: SceneTree, id: ItemId.Id, amount: int = 1) -> int:
	var pd: PlayerData = player_data_from_tree(tree)
	if pd == null:
		push_warning("BagService: sin PlayerData")
		return 0
	return pd.add_item(id, amount)


static func count(tree: SceneTree, id: ItemId.Id) -> int:
	var pd: PlayerData = player_data_from_tree(tree)
	return pd.count_item(id) if pd else 0
