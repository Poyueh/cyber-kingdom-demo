extends RefCounted
## Immutable numeric attack profile injected from planet Resources.
var reach: float
var speed: float
var warning: float
var followup: float
var recovery: float
var radius: float
var beats: int
var spacing: float
var pattern: int
func _init(config: Dictionary) -> void:
 # Defaults apply only to pre-profile legacy snapshots and independent prototypes.
 var ice: bool=int(config.get("planet_id",0))==2
 reach=float(config.get("dragon_reach",240.0 if ice else 300.0))
 speed=float(config.get("dragon_speed",85.0 if ice else 100.0))
 warning=float(config.get("dragon_warning",1.9 if ice else 2.1))
 followup=float(config.get("dragon_followup",1.7))
 recovery=float(config.get("dragon_recovery",8.5 if ice else 7.0))
 radius=float(config.get("dragon_radius",85.0 if ice else 105.0))
 beats=int(config.get("dragon_beats",2 if ice else 1))
 spacing=float(config.get("dragon_spacing",190.0))
 pattern=int(config.get("dragon_pattern",0))
func next_aim(previous: float, origin: float, direction: float, beat: int) -> float:
 match pattern:
  1:return previous+direction*spacing*(1 if beat==1 else -2) # alternating spore pods
  2:return origin+direction*90 if beat==beats-1 else previous+direction*spacing # artillery then stomp
  3:return previous # echo repeats the recorded location, never follows input
 return previous+direction*spacing
static func valid_config(config: Dictionary) -> bool:
 var limits: Dictionary={"dragon_reach":Vector2(50,400),"dragon_speed":Vector2(40,180),"dragon_warning":Vector2(1,5),"dragon_followup":Vector2(1,4),"dragon_recovery":Vector2(4,18),"dragon_radius":Vector2(40,200),"dragon_beats":Vector2(1,4),"dragon_spacing":Vector2(-350,350),"dragon_pattern":Vector2(0,3)}
 for key: String in limits:
  if not config.has(key):continue
  var value: Variant=config[key]
  if not (value is int or value is float) or not is_finite(float(value)) or value<limits[key].x or value>limits[key].y:return false
  if key in ["dragon_beats","dragon_pattern"] and floorf(value)!=value:return false
 return true
