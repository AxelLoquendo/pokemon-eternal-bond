@tool
extends ScriptCommand
class_name ScriptCmdGiveItem
## giveitem POTION 1

@export var item_id: ItemId.Id = ItemId.Id.NONE
@export var amount: int = 1
@export var silent: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	if item_id == ItemId.Id.NONE or amount <= 0:
		return true
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	BagService.add(tree, item_id, amount)
	if silent:
		return true
	var name: String = ItemCatalog.get_display_name(item_id) if ItemCatalog else ItemId.to_token(item_id)
	var msg: String
	if amount == 1:
		msg = "¡Obtuviste %s!" % name
	else:
		msg = "¡Obtuviste %s ×%d!" % [name, amount]
	if not MessageService.message_finished.is_connected(context.complete_async):
		MessageService.message_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	MessageService.show_texts([msg])
	context.is_waiting = true
	return false
