class_name CriticalCalc
extends Object
## Ratio de crítico por stage (Gen 3–6 simplificado).

# stage 0..3 → probabilidad
const _RATES: Array[float] = [1.0 / 16.0, 1.0 / 8.0, 1.0 / 2.0, 1.0]


static func chance(crit_stage: int = 0) -> float:
	var i: int = clampi(crit_stage, 0, _RATES.size() - 1)
	return _RATES[i]


static func rolls_critical(crit_stage: int = 0) -> bool:
	return randf() < chance(crit_stage)


## Multiplicador de daño si fue crítico (Gen 6+: x1.5).
static func damage_multiplier(is_critical: bool) -> float:
	return 1.5 if is_critical else 1.0
