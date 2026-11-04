class_name StatStages
extends Object

const MIN_STAGE: int = -6
const MAX_STAGE: int = 6


static func clamp_stage(stage: int) -> int:
	return clampi(stage, MIN_STAGE, MAX_STAGE)


## Stage de combate → multiplicador (1.0 = neutro).
static func multiplier(stage: int) -> float:
	var s: int = clamp_stage(stage)
	if s >= 0:
		return (2.0 + float(s)) / 2.0
	return 2.0 / (2.0 - float(s))


static func apply(base_stat: int, stage: int) -> int:
	return maxi(1, int(float(base_stat) * multiplier(stage)))
