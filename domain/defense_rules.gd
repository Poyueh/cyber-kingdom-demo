extends Resource
## Shared readable commands and melee timing; the same resource feeds game and animation.
@export_range(1,4,1) var assignment_cost: int=1
@export var station_offset: float=64.0
@export var station_radius: float=42.0
@export var sword_reach: float=92.0
@export var sword_damage: int=24
@export var sword_cycle: float=1.1
@export var strike_remaining: float=0.66
@export var shield_reaction: float=0.22
const LIMITS: Dictionary={"assignment_cost":Vector2(1,4),"station_offset":Vector2(40,80),"station_radius":Vector2(28,60),"sword_reach":Vector2(70,110),"sword_damage":Vector2(12,40),"sword_cycle":Vector2(0.9,1.5),"strike_remaining":Vector2(0.4,0.8),"shield_reaction":Vector2(0.1,0.35)}
func configuration() -> Dictionary:
 var result: Dictionary={}
 for key: String in LIMITS:result["defense_"+key]=get(key)
 return result
func apply(config: Dictionary) -> void:
 for key: String in LIMITS:
  if config.has("defense_"+key):set(key,config["defense_"+key])
static func valid(config: Dictionary) -> bool:
 for key: String in LIMITS:
  if not config.has("defense_"+key):continue
  var value: Variant=config["defense_"+key]
  if not (value is int or value is float) or not is_finite(float(value)) or value<LIMITS[key].x or value>LIMITS[key].y:return false
  if key in ["assignment_cost","sword_damage"] and value!=floorf(value):return false
 return true
