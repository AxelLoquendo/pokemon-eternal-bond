class_name SummaryGenderSkins
extends Object
## Rutas de UI del summary según NewGameState.is_male.

const DETAIL_BOX_M: String = "res://Graficos/UI/Summary_Screen/detail_box.png"
const DETAIL_BOX_F: String = "res://Graficos/UI/Summary_Screen/detail_box_f.png"
const INFO_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Info_Page_M.png"
const INFO_PAGE_F: String = "res://Graficos/UI/Summary_Screen/Info_Page_F.png"
const SKILLS_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Skills_Page/skills_page.png"
const SKILLS_PAGE_F: String = "res://Graficos/UI/Summary_Screen/Skills_Page_M.png" # fallback si no hay F de page name
const SKILLS_BOX_M: String = "res://Graficos/UI/Summary_Screen/Skills_Page/skills_box.png"
const SKILLS_BOX_F: String = "res://Graficos/UI/Summary_Screen/Skills_Page/skills_box_f.png"
const MOVE_PAGE_M: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_page.png"
const MOVE_PAGE_F: String = "res://Graficos/UI/Summary_Screen/Move_Page/move_page_f.png"


static func player_is_male() -> bool:
	return NewGameState == null or NewGameState.is_male


static func _pick(male_path: String, female_path: String) -> String:
	if player_is_male():
		return male_path
	if ResourceLoader.exists(female_path):
		return female_path
	return male_path


static func detail_box_path() -> String:
	return _pick(DETAIL_BOX_M, DETAIL_BOX_F)


static func info_page_name_path() -> String:
	return _pick(INFO_PAGE_M, INFO_PAGE_F)


static func skills_page_name_path() -> String:
	# Skills_Page_M.png está en raíz Summary_Screen; skills_page.png en subcarpeta
	if player_is_male():
		if ResourceLoader.exists(SKILLS_PAGE_M):
			return SKILLS_PAGE_M
		return "res://Graficos/UI/Summary_Screen/Skills_Page/skills_page.png"
	# Preferir Skills_Page_M solo es nombre M; para female no hay page name F → skills_page
	return "res://Graficos/UI/Summary_Screen/Skills_Page/skills_page.png"


static func skills_box_path() -> String:
	return _pick(SKILLS_BOX_M, SKILLS_BOX_F)


static func move_page_name_path() -> String:
	return _pick(MOVE_PAGE_M, MOVE_PAGE_F)


static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
