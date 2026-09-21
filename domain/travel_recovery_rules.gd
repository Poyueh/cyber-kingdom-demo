class_name TravelRecoveryRules
extends Resource
const Clock=preload("res://domain/time/tick_clock.gd")
## Canonical defaults shared by Inspector data and standalone core simulations.
@export_range(0.2,0.8,0.02) var tired_speed_multiplier: float=0.42
@export_range(0.1,0.5,0.05) var run_recovery_ratio: float=0.30
@export_range(0.5,1.0,0.05) var sprint_recovery_ratio: float=0.75
@export_range(0.5,5.0,0.1) var sprint_rest_seconds: float=2.0

var rest_tick_limit: int=Clock.ticks_for(sprint_rest_seconds)

func configuration() -> Dictionary:
 return {"tired_speed_multiplier":tired_speed_multiplier,"run_recovery_ratio":run_recovery_ratio,"sprint_recovery_ratio":sprint_recovery_ratio,"sprint_rest_seconds":sprint_rest_seconds}

func apply(config: Dictionary) -> void:
 tired_speed_multiplier=clampf(config.get("tired_speed_multiplier",tired_speed_multiplier),0.2,0.8)
 run_recovery_ratio=clampf(config.get("run_recovery_ratio",run_recovery_ratio),0.1,0.5)
 sprint_recovery_ratio=clampf(config.get("sprint_recovery_ratio",sprint_recovery_ratio),0.5,1.0)
 sprint_rest_seconds=clampf(config.get("sprint_rest_seconds",sprint_rest_seconds),0.5,5.0)

 rest_tick_limit=Clock.ticks_for(sprint_rest_seconds)
