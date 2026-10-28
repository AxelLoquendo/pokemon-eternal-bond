extends Object
class_name DayNightPalette
## Paletas por periodo (las de tu TiempoManager).

const COLOR_MORNING: Color = Color(1.08, 1.02, 0.90, 1.0)
const COLOR_DAY: Color     = Color(1.00, 1.00, 1.00, 1.0)
const COLOR_DUSK: Color    = Color(1.12, 0.592, 0.456, 1.0)
const COLOR_NIGHT: Color   = Color(0.423, 0.388, 1.1, 1.0)


static func color_for_period(period: DayNightManager.Period) -> Color:
	match period:
		DayNightManager.Period.MORNING:
			return COLOR_MORNING
		DayNightManager.Period.DAY:
			return COLOR_DAY
		DayNightManager.Period.EVENING:
			return COLOR_DUSK
		DayNightManager.Period.NIGHT:
			return COLOR_NIGHT
		_:
			return COLOR_DAY
