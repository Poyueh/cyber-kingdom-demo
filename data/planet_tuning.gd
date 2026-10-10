extends Resource
## Editable biome balance, exported as numeric rules at the composition boundary.
@export_range(0,6) var planet_id: int=0
@export_range(1,30) var rocket_cost: int=20
@export_range(1,30) var rocket_repair: int=12
@export_range(1.0,120.0) var rocket_work: float=30.0
@export_range(60.0,360.0) var day_seconds: float=180.0
@export_range(30.0,180.0) var night_seconds: float=60.0
@export_range(1,10) var night_first: int=4
@export_range(1,6) var night_growth: int=2
@export_flags("Forest", "Desert", "Frost", "Swamp", "Volcanic", "Storm", "Void") var route_requires: int = 0
@export_range(50.0,400.0) var dragon_reach: float = 300.0
@export_range(40.0,180.0) var dragon_speed: float = 100.0
@export_range(1.0,5.0) var dragon_warning: float = 2.1
@export_range(1.0,4.0) var dragon_followup: float = 1.7
@export_range(4.0,18.0) var dragon_recovery: float = 7.0
@export_range(40.0,200.0) var dragon_radius: float = 105.0
@export_range(1,4) var dragon_beats: int = 1
@export_range(-350.0,350.0) var dragon_spacing: float = 190.0
@export_range(0,3) var dragon_pattern: int = 0
@export_range(100,6000,100) var dragon_health: int = 1800
func rules() -> Dictionary:
 return {"dragon_health":dragon_health,"route_requires":route_requires,"dragon_reach":dragon_reach,"dragon_speed":dragon_speed,"dragon_warning":dragon_warning,"dragon_followup":dragon_followup,"dragon_recovery":dragon_recovery,"dragon_radius":dragon_radius,"dragon_beats":dragon_beats,"dragon_spacing":dragon_spacing,"dragon_pattern":dragon_pattern,"planet_id":planet_id,"rocket_cost":rocket_cost,"rocket_repair":rocket_repair,"rocket_work":rocket_work,"day_seconds":day_seconds,"night_seconds":night_seconds,"night_first":night_first,"night_growth":night_growth}
