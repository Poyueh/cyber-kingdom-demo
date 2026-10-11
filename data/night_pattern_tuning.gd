extends Resource
@export_range(3,8,1) var first_day: int
@export_range(45,120,1) var warning_seconds: int
@export_range(10,30,1) var regroup_seconds: int
func rules() -> Dictionary:
	return {"night_pattern_version":1,"night_pattern_first_day":first_day,"night_pattern_warning":warning_seconds,"night_pattern_gap":regroup_seconds}
