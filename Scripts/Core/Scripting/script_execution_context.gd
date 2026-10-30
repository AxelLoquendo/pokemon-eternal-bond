extends RefCounted
class_name ScriptExecutionContext

var npc: Node2D = null
var player: Node2D = null
var map: Node = null
var is_waiting: bool = false
var variables: Dictionary = {}
var runner: ScriptRunner = null

## key = int (GameFlags.Id), value = bool
static var global_flags: Dictionary = {}

func _init(npc_node: Node2D = null, player_node: Node2D = null, map_node: Node = null) -> void:
	npc = npc_node
	player = player_node
	map = map_node

func set_variable(var_name: String, value: Variant) -> void:
	variables[var_name] = value

func get_variable(var_name: String, default_value: Variant = null) -> Variant:
	return variables.get(var_name, default_value)

func set_flag(id: GameFlags.Id, value: bool) -> void:
	if id == GameFlags.Id.NONE:
		push_warning("set_flag: NONE ignorado")
		return
	global_flags[int(id)] = value

func get_flag(id: GameFlags.Id, default_value: bool = false) -> bool:
	if id == GameFlags.Id.NONE:
		return default_value
	return bool(global_flags.get(int(id), default_value))

static func clear_flags() -> void:
	global_flags.clear()

static func export_flags() -> Dictionary:
	return global_flags.duplicate()

static func import_flags(data: Dictionary) -> void:
	global_flags.clear()
	for k: Variant in data.keys():
		global_flags[int(k)] = bool(data[k])

func complete_async() -> void:
	if runner != null and runner.has_method("on_async_complete"):
		runner.on_async_complete()
	else:
		is_waiting = false

func find_character_by_id(character_id: StringName) -> Node:
	var tree: SceneTree = _tree()
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(&"npc"):
		if _node_id(node) == character_id:
			return node
	for node: Node in tree.get_nodes_in_group(&"Player"):
		if _node_id(node) == character_id:
			return node
	return null

func _tree() -> SceneTree:
	if npc != null:
		return npc.get_tree()
	if player != null:
		return player.get_tree()
	if map != null:
		return map.get_tree()
	return null

func _node_id(node: Node) -> StringName:
	if node == null:
		return &""
	if node.has_method("get_script_id"):
		return node.call("get_script_id") as StringName
	if "npc_id" in node:
		return node.get("npc_id") as StringName
	return StringName(node.name)
