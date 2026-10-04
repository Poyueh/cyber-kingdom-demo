extends Resource
@export_range(5,60,1) var relay_seconds: float
@export_range(180,320,10) var station_spacing: float
@export_range(24,60,2) var interaction_radius: float
func rules() -> Dictionary:
 return {"ruin_enabled":1,"ruin_seconds":relay_seconds,"ruin_spacing":station_spacing,"ruin_radius":interaction_radius}
