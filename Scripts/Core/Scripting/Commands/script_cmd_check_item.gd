@tool
extends ScriptCommand
class_name ScriptCmdCheckItem
## checkitem POTION 1 label_si_tiene

@export var item_id: ItemId.Id = ItemId.Id.NONE
@export var amount: int = 1
@export var target_label: String = ""


func execute(context: ScriptExecutionContext) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var pd: PlayerData = BagService.player_data_from_tree(tree)
	if pd != null and pd.has_item(item_id, amount) and context.runner != null:
		if not target_label.is_empty():
			context.runner.jump_to_label(target_label)
	return true
