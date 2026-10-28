extends RefCounted
class_name WindowSkinCatalog
## Catálogo de skins de caja de texto (speech) y multichoice (choice).
## No aplica texturas; MessageConfig / ventanas consultan los paths.

const DIR: String = "res://Graficos/Window_Skin/"

# ---------------------------------------------------------------------------
# SPEECH (caja de diálogo)
# ---------------------------------------------------------------------------
enum SpeechSkin {
	HGSS_1, HGSS_2, HGSS_3, HGSS_4, HGSS_5,
	HGSS_6, HGSS_7, HGSS_8, HGSS_9, HGSS_10,
	HGSS_11, HGSS_12, HGSS_13, HGSS_14, HGSS_15,
	HGSS_16, HGSS_17, HGSS_18, HGSS_19, HGSS_20,
	DP_1, DP_2, DP_3, DP_4, DP_5,
	DP_6, DP_7, DP_8, DP_9, DP_10,
	DP_11, DP_12, DP_13, DP_14, DP_15,
	DP_16, DP_17, DP_18, DP_19, DP_20,
	PL_1, PL_2, PL_3, PL_4, PL_5,
	PL_6, PL_7, PL_8, PL_9, PL_10,
	PL_11, PL_12, PL_13, PL_14, PL_15,
	PL_16, PL_17, PL_18, PL_19, PL_20,
	EM, FRLG, RS,
	UG_1, UG_2,
}

const SPEECH_PATH: Dictionary = {
	SpeechSkin.HGSS_1: "speech hgss 1.png",
	SpeechSkin.HGSS_2: "speech hgss 2.png",
	SpeechSkin.HGSS_3: "speech hgss 3.png",
	SpeechSkin.HGSS_4: "speech hgss 4.png",
	SpeechSkin.HGSS_5: "speech hgss 5.png",
	SpeechSkin.HGSS_6: "speech hgss 6.png",
	SpeechSkin.HGSS_7: "speech hgss 7.png",
	SpeechSkin.HGSS_8: "speech hgss 8.png",
	SpeechSkin.HGSS_9: "speech hgss 9.png",
	SpeechSkin.HGSS_10: "speech hgss 10.png",
	SpeechSkin.HGSS_11: "speech hgss 11.png",
	SpeechSkin.HGSS_12: "speech hgss 12.png",
	SpeechSkin.HGSS_13: "speech hgss 13.png",
	SpeechSkin.HGSS_14: "speech hgss 14.png",
	SpeechSkin.HGSS_15: "speech hgss 15.png",
	SpeechSkin.HGSS_16: "speech hgss 16.png",
	SpeechSkin.HGSS_17: "speech hgss 17.png",
	SpeechSkin.HGSS_18: "speech hgss 18.png",
	SpeechSkin.HGSS_19: "speech hgss 19.png",
	SpeechSkin.HGSS_20: "speech hgss 20.png",
	SpeechSkin.DP_1: "speech dp 1.png",
	SpeechSkin.DP_2: "speech dp 2.png",
	SpeechSkin.DP_3: "speech dp 3.png",
	SpeechSkin.DP_4: "speech dp 4.png",
	SpeechSkin.DP_5: "speech dp 5.png",
	SpeechSkin.DP_6: "speech dp 6.png",
	SpeechSkin.DP_7: "speech dp 7.png",
	SpeechSkin.DP_8: "speech dp 8.png",
	SpeechSkin.DP_9: "speech dp 9.png",
	SpeechSkin.DP_10: "speech dp 10.png",
	SpeechSkin.DP_11: "speech dp 11.png",
	SpeechSkin.DP_12: "speech dp 12.png",
	SpeechSkin.DP_13: "speech dp 13.png",
	SpeechSkin.DP_14: "speech dp 14.png",
	SpeechSkin.DP_15: "speech dp 15.png",
	SpeechSkin.DP_16: "speech dp 16.png",
	SpeechSkin.DP_17: "speech dp 17.png",
	SpeechSkin.DP_18: "speech dp 18.png",
	SpeechSkin.DP_19: "speech dp 19.png",
	SpeechSkin.DP_20: "speech dp 20.png",
	SpeechSkin.PL_1: "speech pl 1.png",
	SpeechSkin.PL_2: "speech pl 2.png",
	SpeechSkin.PL_3: "speech pl 3.png",
	SpeechSkin.PL_4: "speech pl 4.png",
	SpeechSkin.PL_5: "speech pl 5.png",
	SpeechSkin.PL_6: "speech pl 6.png",
	SpeechSkin.PL_7: "speech pl 7.png",
	SpeechSkin.PL_8: "speech pl 8.png",
	SpeechSkin.PL_9: "speech pl 9.png",
	SpeechSkin.PL_10: "speech pl 10.png",
	SpeechSkin.PL_11: "speech pl 11.png",
	SpeechSkin.PL_12: "speech pl 12.png",
	SpeechSkin.PL_13: "speech pl 13.png",
	SpeechSkin.PL_14: "speech pl 14.png",
	SpeechSkin.PL_15: "speech pl 15.png",
	SpeechSkin.PL_16: "speech pl 16.png",
	SpeechSkin.PL_17: "speech pl 17.png",
	SpeechSkin.PL_18: "speech pl 18.png",
	SpeechSkin.PL_19: "speech pl 19.png",
	SpeechSkin.PL_20: "speech pl 20.png",
	SpeechSkin.EM: "speech em.png",
	SpeechSkin.FRLG: "speech frlg.png",
	SpeechSkin.RS: "speech rs.png",
	SpeechSkin.UG_1: "speech ug 1.png",
	SpeechSkin.UG_2: "speech ug 2.png",
}

# ---------------------------------------------------------------------------
# CHOICE (multichoice / menús)
# ---------------------------------------------------------------------------
enum ChoiceSkin {
	CHOICE_1, CHOICE_2, CHOICE_3, CHOICE_4, CHOICE_5,
	CHOICE_6, CHOICE_7, CHOICE_8, CHOICE_9, CHOICE_10,
	CHOICE_11, CHOICE_12, CHOICE_13, CHOICE_14, CHOICE_15,
	CHOICE_16, CHOICE_17, CHOICE_18, CHOICE_19, CHOICE_20,
	CHOICE_21, CHOICE_22, CHOICE_23, CHOICE_24, CHOICE_25,
	CHOICE_26, CHOICE_27, CHOICE_28,
	DP, UG,
}

const CHOICE_PATH: Dictionary = {
	ChoiceSkin.CHOICE_1: "choice 1.png",
	ChoiceSkin.CHOICE_2: "choice 2.png",
	ChoiceSkin.CHOICE_3: "choice 3.png",
	ChoiceSkin.CHOICE_4: "choice 4.png",
	ChoiceSkin.CHOICE_5: "choice 5.png",
	ChoiceSkin.CHOICE_6: "choice 6.png",
	ChoiceSkin.CHOICE_7: "choice 7.png",
	ChoiceSkin.CHOICE_8: "choice 8.png",
	ChoiceSkin.CHOICE_9: "choice 9.png",
	ChoiceSkin.CHOICE_10: "choice 10.png",
	ChoiceSkin.CHOICE_11: "choice 11.png",
	ChoiceSkin.CHOICE_12: "choice 12.png",
	ChoiceSkin.CHOICE_13: "choice 13.png",
	ChoiceSkin.CHOICE_14: "choice 14.png",
	ChoiceSkin.CHOICE_15: "choice 15.png",
	ChoiceSkin.CHOICE_16: "choice 16.png",
	ChoiceSkin.CHOICE_17: "choice 17.png",
	ChoiceSkin.CHOICE_18: "choice 18.png",
	ChoiceSkin.CHOICE_19: "choice 19.png",
	ChoiceSkin.CHOICE_20: "choice 20.png",
	ChoiceSkin.CHOICE_21: "choice 21.png",
	ChoiceSkin.CHOICE_22: "choice 22.png",
	ChoiceSkin.CHOICE_23: "choice 23.png",
	ChoiceSkin.CHOICE_24: "choice 24.png",
	ChoiceSkin.CHOICE_25: "choice 25.png",
	ChoiceSkin.CHOICE_26: "choice 26.png",
	ChoiceSkin.CHOICE_27: "choice 27.png",
	ChoiceSkin.CHOICE_28: "choice 28.png",
	ChoiceSkin.DP: "choice dp.png",
	ChoiceSkin.UG: "choice ug.png",
}

# ---------------------------------------------------------------------------
# Extras (signpost / gold / flechas)
# ---------------------------------------------------------------------------
const PAUSE_ARROW: String = "pause_arrow.png"
const GOLD_SKIN: String = "goldskin.png"
const SIGN_SKIN: String = "signskin.png"
const SIGN_HGSS_DIR: String = "sign hgss dir.png"
const SIGN_HGSS_LOC: String = "sign hgss loc.png"
const SIGN_HGSS_TOWN: String = "sign hgss town.png"
const SIGN_HGSS_TT: String = "sign hgss tt.png"

const DEFAULT_SPEECH: SpeechSkin = SpeechSkin.HGSS_1
const DEFAULT_CHOICE: ChoiceSkin = ChoiceSkin.CHOICE_1

static func speech_path(id: SpeechSkin = DEFAULT_SPEECH) -> String:
	var file: String = SPEECH_PATH.get(id, SPEECH_PATH[DEFAULT_SPEECH]) as String
	return DIR + file

static func choice_path(id: ChoiceSkin = DEFAULT_CHOICE) -> String:
	var file: String = CHOICE_PATH.get(id, CHOICE_PATH[DEFAULT_CHOICE]) as String
	return DIR + file

static func pause_arrow_path() -> String:
	return DIR + PAUSE_ARROW

static func load_speech(id: SpeechSkin = DEFAULT_SPEECH) -> Texture2D:
	var path: String = speech_path(id)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func load_choice(id: ChoiceSkin = DEFAULT_CHOICE) -> Texture2D:
	var path: String = choice_path(id)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func load_pause_arrow() -> Texture2D:
	var path: String = pause_arrow_path()
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func speech_ids() -> Array:
	return SPEECH_PATH.keys()

static func choice_ids() -> Array:
	return CHOICE_PATH.keys()
