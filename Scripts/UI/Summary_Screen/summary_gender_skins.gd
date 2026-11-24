class_name SummaryGenderSkins
extends Object
## Rutas de UI del summary según NewGameState.is_male.

const DETAIL_BOX_M: String = "res://Graficos/UI/Summary_Screen/detail_box.png"
const DETAIL_BOX_F: String = "res://Graficos/UI/Summary_Screen/detail_box_f.png"
const INFO_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Info_Page_M.png"
const INFO_PAGE_F: String = "res://Graficos/UI/Summary_Screen/Info_Page_F.png"
const SKILLS_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Skills_Page_M.png"
# Si no hay Skills_Page_F, reutiliza M o agrega el asset.
const MOVE_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_page.png"
const MOVE_PAGE_F: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_page_f.png"


static func player_is_male() -> bool:
	if NewGameState != null:
		return NewGameState.is_male
	return true


static func detail_box_path() -> String:
	return DETAIL_BOX_M if player_is_male() else DETAIL_BOX_F


static func info_page_name_path() -> String:
	return INFO_PAGE_M if player_is_male() else INFO_PAGE_F
