extends RefCounted
class_name SFXGame
## Catálogo global de audio del proyecto.
## No reproduce audio.
## Los sistemas de reproducción utilizan los IDs definidos aquí.
##
## Excluye:
## - Cries de Pokémon.
## - SFX propios de movimientos.

const DEFAULT_TRIM_END: float = 0.0

# ============================================================
# BATTLE BGM
# ============================================================
enum BattleMusicID {
	BGM_BATTLE_CHAMPION,
	BGM_BATTLE_ELITE,
	BGM_BATTLE_FRONTIER,
	BGM_BATTLE_GYM_LEADER,
	BGM_BATTLE_LOW_HP,
	BGM_BATTLE_ROAMING,
	BGM_BATTLE_TRAINER,
	BGM_BATTLE_VICTORY_LEADER,
	BGM_BATTLE_VICTORY_TRAINER,
	BGM_BATTLE_VICTORY_WILD,
	BGM_BATTLE_VICTORY,
	BGM_BATTLE_WILD,

	BGM_RAID_BASIC_ADVENTURE,
	BGM_RAID_BASIC_BATTLE_1,
	BGM_RAID_BASIC_BATTLE_2,
	BGM_RAID_BASIC_CAPTURE,

	BGM_RAID_MAX_ADVENTURE,
	BGM_RAID_MAX_BATTLE_1,
	BGM_RAID_MAX_BATTLE_2,
	BGM_RAID_MAX_BATTLE_3,
	BGM_RAID_MAX_CAPTURE,

	BGM_RAID_TERA_ADVENTURE,
	BGM_RAID_TERA_BATTLE_1,
	BGM_RAID_TERA_BATTLE_2,
	BGM_RAID_TERA_BATTLE_3,
	BGM_RAID_TERA_CAPTURE,

	BGM_RAID_ULTRA_ADVENTURE,
	BGM_RAID_ULTRA_BATTLE_1,
	BGM_RAID_ULTRA_BATTLE_2,
	BGM_RAID_ULTRA_BATTLE_3,
	BGM_RAID_ULTRA_CAPTURE,

	BGM_TRIPLE_TRIAD,
}

const BATTLE_MUSIC_PATH: Dictionary = {
	BattleMusicID.BGM_BATTLE_CHAMPION: "res://Sfx/bgm/Battle Champion.ogg",
	BattleMusicID.BGM_BATTLE_ELITE: "res://Sfx/bgm/Battle Elite.ogg",
	BattleMusicID.BGM_BATTLE_FRONTIER: "res://Sfx/bgm/Battle Frontier.ogg",
	BattleMusicID.BGM_BATTLE_GYM_LEADER: "res://Sfx/bgm/Battle Gym Leader.ogg",
	BattleMusicID.BGM_BATTLE_LOW_HP: "res://Sfx/bgm/Battle low HP.ogg",
	BattleMusicID.BGM_BATTLE_ROAMING: "res://Sfx/bgm/Battle roaming.ogg",
	BattleMusicID.BGM_BATTLE_TRAINER: "res://Sfx/bgm/Battle trainer.ogg",
	BattleMusicID.BGM_BATTLE_VICTORY_LEADER: "res://Sfx/bgm/Battle victory leader.ogg",
	BattleMusicID.BGM_BATTLE_VICTORY_TRAINER: "res://Sfx/bgm/Battle victory trainer.ogg",
	BattleMusicID.BGM_BATTLE_VICTORY_WILD: "res://Sfx/bgm/Battle victory wild.ogg",
	BattleMusicID.BGM_BATTLE_VICTORY: "res://Sfx/bgm/Battle victory.ogg",
	BattleMusicID.BGM_BATTLE_WILD: "res://Sfx/bgm/Battle wild.ogg",

	BattleMusicID.BGM_RAID_BASIC_ADVENTURE: "res://Sfx/bgm/Raid (Basic) adventure.ogg",
	BattleMusicID.BGM_RAID_BASIC_BATTLE_1: "res://Sfx/bgm/Raid (Basic) battle v1.ogg",
	BattleMusicID.BGM_RAID_BASIC_BATTLE_2: "res://Sfx/bgm/Raid (Basic) battle v2.ogg",
	BattleMusicID.BGM_RAID_BASIC_CAPTURE: "res://Sfx/bgm/Raid (Basic) capture.ogg",

	BattleMusicID.BGM_RAID_MAX_ADVENTURE: "res://Sfx/bgm/Raid (Max) adventure.ogg",
	BattleMusicID.BGM_RAID_MAX_BATTLE_1: "res://Sfx/bgm/Raid (Max) battle v1.ogg",
	BattleMusicID.BGM_RAID_MAX_BATTLE_2: "res://Sfx/bgm/Raid (Max) battle v2.ogg",
	BattleMusicID.BGM_RAID_MAX_BATTLE_3: "res://Sfx/bgm/Raid (Max) battle v3.ogg",
	BattleMusicID.BGM_RAID_MAX_CAPTURE: "res://Sfx/bgm/Raid (Max) capture.ogg",

	BattleMusicID.BGM_RAID_TERA_ADVENTURE: "res://Sfx/bgm/Raid (Tera) adventure.ogg",
	BattleMusicID.BGM_RAID_TERA_BATTLE_1: "res://Sfx/bgm/Raid (Tera) battle v1.ogg",
	BattleMusicID.BGM_RAID_TERA_BATTLE_2: "res://Sfx/bgm/Raid (Tera) battle v2.ogg",
	BattleMusicID.BGM_RAID_TERA_BATTLE_3: "res://Sfx/bgm/Raid (Tera) battle v3.ogg",
	BattleMusicID.BGM_RAID_TERA_CAPTURE: "res://Sfx/bgm/Raid (Tera) capture.ogg",

	BattleMusicID.BGM_RAID_ULTRA_ADVENTURE: "res://Sfx/bgm/Raid (Ultra) adventure.ogg",
	BattleMusicID.BGM_RAID_ULTRA_BATTLE_1: "res://Sfx/bgm/Raid (Ultra) battle v1.ogg",
	BattleMusicID.BGM_RAID_ULTRA_BATTLE_2: "res://Sfx/bgm/Raid (Ultra) battle v2.ogg",
	BattleMusicID.BGM_RAID_ULTRA_BATTLE_3: "res://Sfx/bgm/Raid (Ultra) battle v3.ogg",
	BattleMusicID.BGM_RAID_ULTRA_CAPTURE: "res://Sfx/bgm/Raid (Ultra) capture.ogg",

	BattleMusicID.BGM_TRIPLE_TRIAD: "res://Sfx/bgm/Triple Triad.ogg",
}


# ============================================================
# MUSIC EFFECTS
# ============================================================

enum MusicEffectID {
	ME_BERRY_GET,
	ME_BUG_CATCHING_3RD,
	ME_EVOLUTION_START,
	ME_FORGET_MOVE,
	ME_GUI_SAVE_GAME,
	ME_ITEM_GET,
	ME_KEY_ITEM_GET,
	ME_PKMN_HEALING,
	ME_SLOTS_BIG_WIN,
	ME_SLOTS_WIN,
	ME_VOLTORB_FLIP_WIN,
	ME_BATTLE_CAPTURE_SUCCESS,
}

const MUSIC_EFFECT_PATH: Dictionary = {
	MusicEffectID.ME_BERRY_GET: "res://Sfx/me/Berry get.ogg",
	MusicEffectID.ME_BUG_CATCHING_3RD: "res://Sfx/me/Bug catching 3rd.ogg",
	MusicEffectID.ME_EVOLUTION_START: "res://Sfx/me/Evolution start.ogg",
	MusicEffectID.ME_FORGET_MOVE: "res://Sfx/me/Forget move.ogg",
	MusicEffectID.ME_GUI_SAVE_GAME: "res://Sfx/me/GUI save game.ogg",
	MusicEffectID.ME_ITEM_GET: "res://Sfx/me/Item get.ogg",
	MusicEffectID.ME_KEY_ITEM_GET: "res://Sfx/me/Key item get.ogg",
	MusicEffectID.ME_PKMN_HEALING: "res://Sfx/me/Pkmn healing.ogg",
	MusicEffectID.ME_SLOTS_BIG_WIN: "res://Sfx/me/Slots big win.ogg",
	MusicEffectID.ME_SLOTS_WIN: "res://Sfx/me/Slots win.ogg",
	MusicEffectID.ME_VOLTORB_FLIP_WIN: "res://Sfx/me/Voltorb Flip win.ogg",
	MusicEffectID.ME_BATTLE_CAPTURE_SUCCESS: "res://Sfx/me/Battle capture success.ogg",
}


# ============================================================
# SOUND EFFECTS
# ============================================================

enum SoundEffectID {
	SE_BATTLE_ABILITY,
	SE_BATTLE_BALL_DROP,
	SE_BATTLE_BALL_HIT,
	SE_BATTLE_BALL_SHAKE,
	SE_BATTLE_CATCH_CLICK,
	SE_BATTLE_CRITICAL_CATCH_THROW,
	SE_BATTLE_DAMAGE_NORMAL,
	SE_BATTLE_DAMAGE_SUPER,
	SE_BATTLE_DAMAGE_WEAK,
	SE_BATTLE_FLEE,
	SE_BATTLE_ITEM,
	SE_BATTLE_JUMP_TO_BALL,
	SE_BATTLE_RECALL,
	SE_BATTLE_THROW,

	SE_BICYCLE,
	SE_CUT,
	SE_DOOR_ENTER,
	SE_DOOR_EXIT,
	SE_DOOR_SLIDE,
	SE_ELEVATOR_END,
	SE_EXCLAIM,
	SE_FLY,
	SE_HEADBUTT,
	SE_ITEMFINDER,
	SE_PLAYER_BUMP,
	SE_PLAYER_FALL,
	SE_PLAYER_JUMP,
	SE_POISON_STEP,
	SE_REPEL,
	SE_ROCK_SMASH,
	SE_STRENGTH_PUSH,
	SE_SWEET_SCENT,
	SE_SHOUT,

	SE_DX_ACTION,
	SE_DX_ACTION_BUTTON,
	SE_GUI_BAG_CURSOR,
	SE_GUI_BAG_POCKET,
	SE_GUI_MENU_CLOSE,
	SE_GUI_MENU_OPEN,
	SE_GUI_NAMING_CONFIRM,
	SE_GUI_NAMING_TAB_SWAP_END,
	SE_GUI_NAMING_TAB_SWAP_START,
	SE_GUI_PARTY_SWITCH,
	SE_GUI_POKEDEX_OPEN,
	SE_GUI_SAVE_CHOICE,
	SE_GUI_SEL_BUZZER,
	SE_GUI_SEL_CANCEL,
	SE_GUI_SEL_CURSOR,
	SE_GUI_SEL_DECISION,
	SE_GUI_STORAGE_HIDE_PARTY_PANEL,
	SE_GUI_STORAGE_PICK_UP,
	SE_GUI_STORAGE_PUT_DOWN,
	SE_GUI_STORAGE_SHOW_PARTY_PANEL,
	SE_GUI_SUMMARY_CHANGE_PAGE,
	SE_GUI_TRAINER_CARD_OPEN,

	SE_PKMN_EXP_FULL,
	SE_PKMN_EXP_GAIN,
	SE_PKMN_FAINT,
	SE_PKMN_LEVEL_UP,
	SE_PKMN_MOVE_LEARNT,
	SE_USE_ITEM_IN_PARTY,

	SE_PC_ACCESS,
	SE_PC_CLOSE,
	SE_PC_OPEN,
	SE_MART_BUY_ITEM,
	SE_VENDING_MACHINE_DISPENSE,
	SE_WATER_BERRY_PLANT,
	SE_SAFARI_ZONE_END,
	SE_VS_FLASH,
	SE_VS_SWORD,
	SE_Z_MOVE_TITLE,

	SE_MINING_COLLAPSE,
	SE_MINING_CURSOR,
	SE_MINING_FOUND_ALL,
	SE_MINING_HAMMER,
	SE_MINING_IRON,
	SE_MINING_ITEM_GET,
	SE_MINING_PICK,
	SE_MINING_PING,
	SE_MINING_REVEAL,
	SE_MINING_REVEAL_FULL,
	SE_MINING_TOOL_CHANGE,

	SE_SLOTS_COIN,
	SE_SLOTS_STOP,
	SE_TILE_GAME_CURSOR,
	SE_VOLTORB_FLIP_EXPLOSION,
	SE_VOLTORB_FLIP_GAIN_COINS,
	SE_VOLTORB_FLIP_LEVEL_DOWN,
	SE_VOLTORB_FLIP_LEVEL_UP,
	SE_VOLTORB_FLIP_MARK,
	SE_VOLTORB_FLIP_POINT,
	SE_VOLTORB_FLIP_TILE,
}

const SOUND_EFFECT_PATH: Dictionary = {
	SoundEffectID.SE_BATTLE_ABILITY: "res://Sfx/se/Battle ability.ogg",
	SoundEffectID.SE_BATTLE_BALL_DROP: "res://Sfx/se/Battle ball drop.ogg",
	SoundEffectID.SE_BATTLE_BALL_HIT: "res://Sfx/se/Battle ball hit.ogg",
	SoundEffectID.SE_BATTLE_BALL_SHAKE: "res://Sfx/se/Battle ball shake.ogg",
	SoundEffectID.SE_BATTLE_CATCH_CLICK: "res://Sfx/se/Battle catch click.ogg",
	SoundEffectID.SE_BATTLE_CRITICAL_CATCH_THROW: "res://Sfx/se/Battle critical catch throw.ogg",
	SoundEffectID.SE_BATTLE_DAMAGE_NORMAL: "res://Sfx/se/Battle damage normal.ogg",
	SoundEffectID.SE_BATTLE_DAMAGE_SUPER: "res://Sfx/se/Battle damage super.ogg",
	SoundEffectID.SE_BATTLE_DAMAGE_WEAK: "res://Sfx/se/Battle damage weak.ogg",
	SoundEffectID.SE_BATTLE_FLEE: "res://Sfx/se/Battle flee.ogg",
	SoundEffectID.SE_BATTLE_ITEM: "res://Sfx/se/Battle item.ogg",
	SoundEffectID.SE_BATTLE_JUMP_TO_BALL: "res://Sfx/se/Battle jump to ball.ogg",
	SoundEffectID.SE_BATTLE_RECALL: "res://Sfx/se/Battle recall.ogg",
	SoundEffectID.SE_BATTLE_THROW: "res://Sfx/se/Battle throw.ogg",

	SoundEffectID.SE_BICYCLE: "res://Sfx/se/Bicycle.ogg",
	SoundEffectID.SE_CUT: "res://Sfx/se/Cut.ogg",
	SoundEffectID.SE_DOOR_ENTER: "res://Sfx/se/Door enter.ogg",
	SoundEffectID.SE_DOOR_EXIT: "res://Sfx/se/Door exit.ogg",
	SoundEffectID.SE_DOOR_SLIDE: "res://Sfx/se/Door slide.ogg",
	SoundEffectID.SE_ELEVATOR_END: "res://Sfx/se/Elevator end.ogg",
	SoundEffectID.SE_EXCLAIM: "res://Sfx/se/Exclaim.ogg",
	SoundEffectID.SE_FLY: "res://Sfx/se/Fly.ogg",
	SoundEffectID.SE_HEADBUTT: "res://Sfx/se/Headbutt.ogg",
	SoundEffectID.SE_ITEMFINDER: "res://Sfx/se/Itemfinder.ogg",
	SoundEffectID.SE_PLAYER_BUMP: "res://Sfx/se/Player bump.ogg",
	SoundEffectID.SE_PLAYER_FALL: "res://Sfx/se/Player fall.ogg",
	SoundEffectID.SE_PLAYER_JUMP: "res://Sfx/se/Player jump.ogg",
	SoundEffectID.SE_POISON_STEP: "res://Sfx/se/Poison step.ogg",
	SoundEffectID.SE_REPEL: "res://Sfx/se/Repel.ogg",
	SoundEffectID.SE_ROCK_SMASH: "res://Sfx/se/Rock Smash.ogg",
	SoundEffectID.SE_STRENGTH_PUSH: "res://Sfx/se/Strength push.ogg",
	SoundEffectID.SE_SWEET_SCENT: "res://Sfx/se/Sweet Scent.ogg",
	SoundEffectID.SE_SHOUT: "res://Sfx/se/shout.ogg",

	SoundEffectID.SE_DX_ACTION: "res://Sfx/se/DX Action.ogg",
	SoundEffectID.SE_DX_ACTION_BUTTON: "res://Sfx/se/DX Action Button.ogg",
	SoundEffectID.SE_GUI_BAG_CURSOR: "res://Sfx/se/GUI bag cursor.ogg",
	SoundEffectID.SE_GUI_BAG_POCKET: "res://Sfx/se/GUI bag pocket.ogg",
	SoundEffectID.SE_GUI_MENU_CLOSE: "res://Sfx/se/GUI menu close.ogg",
	SoundEffectID.SE_GUI_MENU_OPEN: "res://Sfx/se/GUI menu open.ogg",
	SoundEffectID.SE_GUI_NAMING_CONFIRM: "res://Sfx/se/GUI naming confirm.ogg",
	SoundEffectID.SE_GUI_NAMING_TAB_SWAP_END: "res://Sfx/se/GUI naming tab swap end.ogg",
	SoundEffectID.SE_GUI_NAMING_TAB_SWAP_START: "res://Sfx/se/GUI naming tab swap start.ogg",
	SoundEffectID.SE_GUI_PARTY_SWITCH: "res://Sfx/se/GUI party switch.ogg",
	SoundEffectID.SE_GUI_POKEDEX_OPEN: "res://Sfx/se/GUI pokedex open.ogg",
	SoundEffectID.SE_GUI_SAVE_CHOICE: "res://Sfx/se/GUI save choice.ogg",
	SoundEffectID.SE_GUI_SEL_BUZZER: "res://Sfx/se/GUI sel buzzer.ogg",
	SoundEffectID.SE_GUI_SEL_CANCEL: "res://Sfx/se/GUI sel cancel.ogg",
	SoundEffectID.SE_GUI_SEL_CURSOR: "res://Sfx/se/GUI sel cursor.ogg",
	SoundEffectID.SE_GUI_SEL_DECISION: "res://Sfx/se/GUI sel decision.ogg",
	SoundEffectID.SE_GUI_STORAGE_HIDE_PARTY_PANEL: "res://Sfx/se/GUI storage hide party panel.ogg",
	SoundEffectID.SE_GUI_STORAGE_PICK_UP: "res://Sfx/se/GUI storage pick up.ogg",
	SoundEffectID.SE_GUI_STORAGE_PUT_DOWN: "res://Sfx/se/GUI storage put down.ogg",
	SoundEffectID.SE_GUI_STORAGE_SHOW_PARTY_PANEL: "res://Sfx/se/GUI storage show party panel.ogg",
	SoundEffectID.SE_GUI_SUMMARY_CHANGE_PAGE: "res://Sfx/se/GUI summary change page.ogg",
	SoundEffectID.SE_GUI_TRAINER_CARD_OPEN: "res://Sfx/se/GUI trainer card open.ogg",

	SoundEffectID.SE_PKMN_EXP_FULL: "res://Sfx/se/Pkmn exp full.ogg",
	SoundEffectID.SE_PKMN_EXP_GAIN: "res://Sfx/se/Pkmn exp gain.ogg",
	SoundEffectID.SE_PKMN_FAINT: "res://Sfx/se/Pkmn faint.ogg",
	SoundEffectID.SE_PKMN_LEVEL_UP: "res://Sfx/se/Pkmn level up.ogg",
	SoundEffectID.SE_PKMN_MOVE_LEARNT: "res://Sfx/se/Pkmn move learnt.ogg",
	SoundEffectID.SE_USE_ITEM_IN_PARTY: "res://Sfx/se/Use item in party.ogg",

	SoundEffectID.SE_PC_ACCESS: "res://Sfx/se/PC access.ogg",
	SoundEffectID.SE_PC_CLOSE: "res://Sfx/se/PC close.ogg",
	SoundEffectID.SE_PC_OPEN: "res://Sfx/se/PC open.ogg",
	SoundEffectID.SE_MART_BUY_ITEM: "res://Sfx/se/Mart buy item.ogg",
	SoundEffectID.SE_VENDING_MACHINE_DISPENSE: "res://Sfx/se/Vending machine dispense.ogg",
	SoundEffectID.SE_WATER_BERRY_PLANT: "res://Sfx/se/Water berry plant.ogg",
	SoundEffectID.SE_SAFARI_ZONE_END: "res://Sfx/se/Safari Zone end.ogg",
	SoundEffectID.SE_VS_FLASH: "res://Sfx/se/Vs flash.ogg",
	SoundEffectID.SE_VS_SWORD: "res://Sfx/se/Vs sword.ogg",
	SoundEffectID.SE_Z_MOVE_TITLE: "res://Sfx/se/Z-Move Title.ogg",

	SoundEffectID.SE_MINING_COLLAPSE: "res://Sfx/se/Mining collapse.ogg",
	SoundEffectID.SE_MINING_CURSOR: "res://Sfx/se/Mining cursor.ogg",
	SoundEffectID.SE_MINING_FOUND_ALL: "res://Sfx/se/Mining found all.ogg",
	SoundEffectID.SE_MINING_HAMMER: "res://Sfx/se/Mining hammer.ogg",
	SoundEffectID.SE_MINING_IRON: "res://Sfx/se/Mining iron.ogg",
	SoundEffectID.SE_MINING_ITEM_GET: "res://Sfx/se/Mining item get.ogg",
	SoundEffectID.SE_MINING_PICK: "res://Sfx/se/Mining pick.ogg",
	SoundEffectID.SE_MINING_PING: "res://Sfx/se/Mining ping.ogg",
	SoundEffectID.SE_MINING_REVEAL: "res://Sfx/se/Mining reveal.ogg",
	SoundEffectID.SE_MINING_REVEAL_FULL: "res://Sfx/se/Mining reveal full.ogg",
	SoundEffectID.SE_MINING_TOOL_CHANGE: "res://Sfx/se/Mining tool change.ogg",
	SoundEffectID.SE_SLOTS_COIN: "res://Sfx/se/Slots coin.ogg",
	SoundEffectID.SE_SLOTS_STOP: "res://Sfx/se/Slots stop.ogg",
	SoundEffectID.SE_TILE_GAME_CURSOR: "res://Sfx/se/Tile Game cursor.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_EXPLOSION: "res://Sfx/se/Voltorb Flip explosion.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_GAIN_COINS: "res://Sfx/se/Voltorb Flip gain coins.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_LEVEL_DOWN: "res://Sfx/se/Voltorb Flip level down.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_LEVEL_UP: "res://Sfx/se/Voltorb Flip level up.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_MARK: "res://Sfx/se/Voltorb Flip mark.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_POINT: "res://Sfx/se/Voltorb Flip point.ogg",
	SoundEffectID.SE_VOLTORB_FLIP_TILE: "res://Sfx/se/Voltorb Flip tile.ogg",
}


# ============================================================
# MAP / FIELD BGM
# ============================================================

enum MapMusicID {
	BGM_NONE,

	BGM_CEDOLAN_CITY,
	BGM_LAPPET_TOWN,
	BGM_LERUCEAN_TOWN,
	BGM_TIALL,

	BGM_ROUTE_1,
	BGM_ROUTE_2,
	BGM_ROUTE_3,

	BGM_POKE_CENTER,
	BGM_POKE_MART,
	BGM_GYM,
	BGM_LAB,
	BGM_GAME_CORNER,
	BGM_HALL_OF_FAME,
	BGM_INDIGO_PLATEAU,

	BGM_CAVE,
	BGM_ISLANDS,
	BGM_NATURAL_PARK,
	BGM_SAFARI_ZONE,
	BGM_SAFARI_ZONE_EXTERIOR,
	BGM_SURFING,
	BGM_UNDERWATER,
	BGM_BICYCLE,
	BGM_BICYCLE_NIGHT,

	BGM_TITLE,
	BGM_NEW_START,
	BGM_CREDITS,
	BGM_EVOLUTION,
	BGM_MYSTERY_GIFT,

	BGM_RADIO_LULLABY,
	BGM_RADIO_MARCH,
	BGM_RADIO_OAK,
}

const MAP_MUSIC_PATH: Dictionary = {
	MapMusicID.BGM_NONE: "",

	MapMusicID.BGM_CEDOLAN_CITY: "res://Sfx/bgm/Cedolan City.ogg",
	MapMusicID.BGM_LAPPET_TOWN: "res://Sfx/bgm/Lappet Town.ogg",
	MapMusicID.BGM_LERUCEAN_TOWN: "res://Sfx/bgm/Lerucean Town.ogg",
	MapMusicID.BGM_TIALL: "res://Sfx/bgm/Tiall.ogg",

	MapMusicID.BGM_ROUTE_1: "res://Sfx/bgm/Route 1.ogg",
	MapMusicID.BGM_ROUTE_2: "res://Sfx/bgm/Route 2.ogg",
	MapMusicID.BGM_ROUTE_3: "res://Sfx/bgm/Route 3.ogg",

	MapMusicID.BGM_POKE_CENTER: "res://Sfx/bgm/Poke Center.ogg",
	MapMusicID.BGM_POKE_MART: "res://Sfx/bgm/Poke Mart.ogg",
	MapMusicID.BGM_GYM: "res://Sfx/bgm/Gym.ogg",
	MapMusicID.BGM_LAB: "res://Sfx/bgm/Lab.ogg",
	MapMusicID.BGM_GAME_CORNER: "res://Sfx/bgm/Game Corner.ogg",
	MapMusicID.BGM_HALL_OF_FAME: "res://Sfx/bgm/Hall of Fame.ogg",
	MapMusicID.BGM_INDIGO_PLATEAU: "res://Sfx/bgm/Ingido Plateau.ogg",

	MapMusicID.BGM_CAVE: "res://Sfx/bgm/Cave.ogg",
	MapMusicID.BGM_ISLANDS: "res://Sfx/bgm/Islands.ogg",
	MapMusicID.BGM_NATURAL_PARK: "res://Sfx/bgm/Natural Park.ogg",
	MapMusicID.BGM_SAFARI_ZONE: "res://Sfx/bgm/Safari Zone.ogg",
	MapMusicID.BGM_SAFARI_ZONE_EXTERIOR: "res://Sfx/bgm/Safari Zone exterior.ogg",
	MapMusicID.BGM_SURFING: "res://Sfx/bgm/Surfing.ogg",
	MapMusicID.BGM_UNDERWATER: "res://Sfx/bgm/Underwater.ogg",
	MapMusicID.BGM_BICYCLE: "res://Sfx/bgm/Bicycle.ogg",
	MapMusicID.BGM_BICYCLE_NIGHT: "res://Sfx/bgm/Bicycle_n.ogg",

	MapMusicID.BGM_TITLE: "res://Sfx/bgm/Title.ogg",
	MapMusicID.BGM_NEW_START: "res://Sfx/bgm/New Start.ogg",
	MapMusicID.BGM_CREDITS: "res://Sfx/bgm/Credits.ogg",
	MapMusicID.BGM_EVOLUTION: "res://Sfx/bgm/Evolution.ogg",
	MapMusicID.BGM_MYSTERY_GIFT: "res://Sfx/bgm/Regalo Misterioso.ogg",

	MapMusicID.BGM_RADIO_LULLABY: "res://Sfx/bgm/Radio - Lullaby.ogg",
	MapMusicID.BGM_RADIO_MARCH: "res://Sfx/bgm/Radio - March.ogg",
	MapMusicID.BGM_RADIO_OAK: "res://Sfx/bgm/Radio - Oak.ogg",
}


# ============================================================
# RESOLVERS
# ============================================================
static func battle_music_path(id: BattleMusicID) -> String:
	return str(BATTLE_MUSIC_PATH.get(id, ""))

static func map_music_path(id: MapMusicID) -> String:
	return str(MAP_MUSIC_PATH.get(id, ""))

static func music_effect_path(id: MusicEffectID) -> String:
	return str(MUSIC_EFFECT_PATH.get(id, ""))

static func sound_effect_path(id: SoundEffectID) -> String:
	return str(SOUND_EFFECT_PATH.get(id, ""))

static func path_exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)
