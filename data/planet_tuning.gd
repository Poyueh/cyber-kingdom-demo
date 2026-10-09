extends Resource
## Editable biome balance, exported as numeric rules at the composition boundary.
@export_range(0,2) var planet_id: int=0
@export_range(1,30) var rocket_cost: int=20
@export_range(1,30) var rocket_repair: int=12
@export_range(1.0,120.0) var rocket_work: float=30.0
@export_range(60.0,360.0) var day_seconds: float=180.0
@export_range(30.0,180.0) var night_seconds: float=60.0
@export_range(1,10) var night_first: int=4
@export_range(1,6) var night_growth: int=2
func rules() -> Dictionary:
 return {"planet_id":planet_id,"rocket_cost":rocket_cost,"rocket_repair":rocket_repair,"rocket_work":rocket_work,"day_seconds":day_seconds,"night_seconds":night_seconds,"night_first":night_first,"night_growth":night_growth}
