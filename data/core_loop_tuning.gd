extends Resource
class_name CoreLoopTuning
## Resolved once for a new forest trial; saved runs retain these values.
@export var encounter: Resource=preload("res://data/trails/forest.tres")
@export var day_seconds: float=300.0
@export var night_seconds: float=55.0
@export var warning_seconds: float=20.0
@export var harvest_seconds: float=8.0
@export var harvest_crystals: int=4
@export var cache_crystals: int=8
@export var starting_crystals: int=6
## The Demo is a first impression: one harvest should pay for the guided first day with room to manage.
@export_range(0,30,1) var demo_starting_crystals: int=12
@export var enemy_health: int=28
@export var enemy_damage: int=8
@export var wall_damage: int=8
@export var archer_range: float=320.0
@export var minimum_defenders: int=1
@export var first_enemies: int=2
@export var second_enemies: int=4
@export var second_side_delay: float=18.0
@export var arrival_radius: float=45.0
@export var sprint_recovery_ratio: float=0.3
@export var return_margin: float=30.0
@export var prices: Dictionary={"recruit":1,"workshop":2,"hunt_tools":3,"mark":1,"wall":3,"wall_upgrade":4}
func resolve(base: Dictionary) -> Dictionary:
 var result: Dictionary=base.duplicate(true)
 for key: String in result.keys():
  if key.begins_with("mechanism_") or key.begins_with("ruin_layout_"):result.erase(key)
 for key: String in ["ruin_variation","level_design","trail_design"]:result.erase(key)
 result.merge({"core_loop_version":1,"core_enemy_health":enemy_health,"core_enemy_damage":enemy_damage,"core_wall_damage":wall_damage,"hunter_range":archer_range,"core_warning":warning_seconds,"core_min_defenders":minimum_defenders,"core_arrival_radius":arrival_radius,"core_sprint_ratio":sprint_recovery_ratio,"core_second_gap":second_side_delay,
  "day_seconds":day_seconds,"night_seconds":night_seconds,"night_first":first_enemies,"night_growth":second_enemies-first_enemies,"night_limit":second_enemies,"night_concurrent":4,
  "starting_crystals":starting_crystals,"tree_crystals":harvest_crystals,"chest_crystals":cache_crystals,"attack_stamina":0.0,"return_margin":return_margin,"voyage_enabled":0,"planet_id":0,"merchant_enabled":0,"ruin_enabled":0,"mount_enabled":0},true)
 var encounter_rules: Dictionary=encounter.rules()
 for key: String in encounter_rules:
  if key!="planet_id":result["core_trail_"+key]=encounter_rules[key]
 result["core_trail_combat_side"]=1
 result.prices=prices.duplicate(true)
 result.economy.work_seconds=harvest_seconds
 return result

## Main campaign shares onboarding and controls, but keeps all authored worlds.
func resolve_campaign(base: Dictionary) -> Dictionary:
 var shared: Dictionary=resolve(base)
 var result: Dictionary=base.duplicate(true)
 for key: String in shared:
  if key.begins_with("core_"):result[key]=shared[key]
 result.core_loop_version=2
 result.core_first_enemies=first_enemies
 result.core_second_enemies=second_enemies
 result.attack_stamina=0.0
 result.return_margin=return_margin
 result.hunter_range=archer_range
 if int(base.planet_id)==0:
  result.tree_crystals=harvest_crystals
  result.chest_crystals=cache_crystals
  result.economy=result.economy.duplicate(true)
  result.economy.work_seconds=harvest_seconds
 return result

## Demo: the guided main forest in full, but contained: no voyage. After the forest
## dragon the knight claims its core and builds the rocket; the finished rocket is the
## finale. Other worlds are not in the Demo package at all.
func resolve_demo(base: Dictionary) -> Dictionary:
 var result: Dictionary=resolve_campaign(base)
 result.core_loop_version=3
 result.voyage_enabled=0
 result.rocket_finale=1
 result.starting_crystals=demo_starting_crystals
 return result
