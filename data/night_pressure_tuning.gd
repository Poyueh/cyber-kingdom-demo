extends Resource
## Authored values live in night_pressure.tres; exported for Inspector tuning.
@export_range(1,12,1) var first_night: int
@export_range(1,8,1) var additional_per_day: int
@export_range(12,120,1) var nightly_limit: int
@export_range(1,24,1) var concurrent_limit: int

func rules() -> Dictionary:
	return {"night_first":first_night,"night_growth":additional_per_day,
		"night_limit":nightly_limit,"night_concurrent":concurrent_limit}
