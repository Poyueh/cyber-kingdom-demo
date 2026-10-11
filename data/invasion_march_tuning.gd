extends Resource
@export_range(1.1,4.0,0.1) var remote_multiplier: float
@export_range(1000,2000,50) var caution_radius: float
@export_range(200,1200,50) var blend_distance: float
func rules() -> Dictionary:
	return {"march_version":1,"march_multiplier":remote_multiplier,"march_caution_radius":caution_radius,"march_blend_distance":blend_distance}
