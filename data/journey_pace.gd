extends Resource
## New-journey configuration offsets, not live combat modifiers.
@export_enum("Expedition","Settler","Siege") var pace_id: int
@export var title_key: StringName
@export var description_key: StringName
@export var icon: StringName
@export_range(-30,120,10) var daylight_adjustment: float
@export_range(-2,4,1) var first_night_adjustment: int
@export_range(-1,3,1) var nightly_growth_adjustment: int
@export_range(-20,30,1) var nightly_limit_adjustment: int
func rules() -> Dictionary:
	return {"id":pace_id,"day_adjustment":daylight_adjustment,"first_adjustment":first_night_adjustment,"growth_adjustment":nightly_growth_adjustment,"limit_adjustment":nightly_limit_adjustment}
