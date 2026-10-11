extends Resource
@export_range(1.1,2.0,0.1) var exposed_damage_multiplier: float
@export_range(5.0,10.0,0.5) var minimum_recovery_seconds: float
func rules() -> Dictionary:
	return {"dragon_opening_version":1,"dragon_opening_multiplier":exposed_damage_multiplier,"dragon_opening_minimum":minimum_recovery_seconds}
