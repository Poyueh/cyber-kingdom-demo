extends Resource
## Fixed creation-time economy and formation spacing for the expedition system.
@export_range(1,12,1) var rally_cost: int=2
@export_range(1,12,1) var repair_cost: int=6
@export_range(1,12,1) var recruit_cost: int=4
@export_range(1,3,1) var squad_limit: int=3
@export_range(1,3,1) var passenger_limit: int=3
@export_range(90,180,10) var flag_offset: float=130.0
@export_range(200,400,10) var barracks_inset: float=270.0
@export_range(140,400,10) var escort_radius: float=320.0
@export_range(150,420,10) var march_speed: float=340.0
@export_range(20,120,5) var city_inset: float=55.0
const ROLES: Array[String]=["guard","guard","guard","hunter","hunter","engineer"]
const LIMITS: Dictionary={"rally_cost":Vector2(1,12),"repair_cost":Vector2(1,12),"recruit_cost":Vector2(1,12),"squad_limit":Vector2(1,3),"passenger_limit":Vector2(1,3),"flag_offset":Vector2(90,180),"barracks_inset":Vector2(200,400),"escort_radius":Vector2(140,400),"march_speed":Vector2(150,420),"city_inset":Vector2(20,120)}
func configuration() -> Dictionary:
 var result: Dictionary={}
 for key: String in LIMITS:result["command_"+key]=get(key)
 return result
func apply(config: Dictionary) -> void:
 for key: String in LIMITS:
  if config.has("command_"+key):set(key,config["command_"+key])
static func valid(config: Dictionary) -> bool:
 for key: String in LIMITS:
  if not config.has("command_"+key):continue
  var value: Variant=config["command_"+key]
  if not (value is int or value is float) or not is_finite(float(value)) or value<LIMITS[key].x or value>LIMITS[key].y:return false
  if key.ends_with("cost") or key.ends_with("limit"):
   if float(value)!=floorf(float(value)):return false
 return true
