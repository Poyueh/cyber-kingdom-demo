extends Resource
@export_range(2,3,1) var circuit_minimum_switches: int
@export_range(2,3,1) var circuit_maximum_switches: int
@export_range(3,6,1) var balance_minimum_moves: int
@export_range(3,6,1) var balance_maximum_moves: int
@export_range(1,4,1) var balance_target_radius: int
@export var pulse_periods_seconds: Array[float]
@export_range(0.25,2,0.25) var pulse_phase_step_seconds: float
func rules() -> Dictionary:
	return {"version":1,"circuit_minimum":circuit_minimum_switches,"circuit_maximum":circuit_maximum_switches,"balance_minimum":balance_minimum_moves,"balance_maximum":balance_maximum_moves,"balance_target_radius":balance_target_radius,"pulse_periods":pulse_periods_seconds.duplicate(),"pulse_step":pulse_phase_step_seconds}
