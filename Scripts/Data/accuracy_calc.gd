class_name AccuracyCalc
extends Object
## ¿Acerta el movimiento? accuracy del move en 0–100 (0 = nunca falla en datos raros;
## en PBS, accuracy 0 en status a veces significa "siempre pega": tratalo en batalla).


static func hit_chance(
	move_accuracy: int,
	accuracy_stage: int = 0,
	evasion_stage: int = 0
) -> float:
	if move_accuracy <= 0:
		return 0.0
	if move_accuracy >= 100 and accuracy_stage == 0 and evasion_stage == 0:
		return 1.0

	var stage: int = StatStages.clamp_stage(accuracy_stage - evasion_stage)
	var stage_mult: float = StatStages.multiplier(stage)
	# Accuracy stages usan la misma tabla que los stats en gen modernas simplificada.
	var chance: float = float(move_accuracy) / 100.0 * stage_mult
	return clampf(chance, 0.0, 1.0)


static func rolls_hit(
	move_accuracy: int,
	accuracy_stage: int = 0,
	evasion_stage: int = 0
) -> bool:
	var chance: float = hit_chance(move_accuracy, accuracy_stage, evasion_stage)
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	return randf() < chance
