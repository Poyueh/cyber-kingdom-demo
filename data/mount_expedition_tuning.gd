extends Resource
@export_range(1800,3800,100) var ruin_distance: float
@export_range(240,400,20) var relay_spacing: float
@export_range(1,12,1) var stable_cost: int
@export_range(30,180,5) var warning_seconds: float
@export_range(2,12,1) var assault_extra: int
@export_range(1,12,1) var recovery_discount: int
@export_range(2,20,1) var dragon_growth_days: int
func rules() -> Dictionary:
 return {"mount_enabled":1,"mount_distance":ruin_distance,"mount_spacing":relay_spacing,"mount_cost":stable_cost,"mount_warning":warning_seconds,"mount_assault":assault_extra,"mount_recovery":recovery_discount,"dragon_growth_days":dragon_growth_days}
