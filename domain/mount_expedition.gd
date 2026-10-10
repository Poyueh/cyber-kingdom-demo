extends RefCounted
## Forest-local circuit and raid; the unlocked mount travels with the knight.
const Clock=preload("res://domain/time/tick_clock.gd")
var enabled: bool=false
var ruin_x: float=0.0
var stable_x: float=0.0
var levers: Array[float]=[]
var rotations: Array[int]=[0,0]
var recovered: bool=false
var unlocked: bool=false
var riding: bool=false
var warning_ticks: int=0
var warning_until: int=0
var raid_day: int=0
var recovery_used: bool=false
var cost: int=0
var extra_enemies: int=0
var recovery_discount: int=0
func _init(config: Dictionary, home: float) -> void:
 enabled=config.get("mount_enabled",0)==1 and config.get("planet_id",0)==0
 stable_x=home-1000
 if config.get("mount_enabled",0)!=1:return
 ruin_x=home-float(config.mount_distance)
 levers.assign([ruin_x+float(config.mount_spacing)*2,ruin_x+float(config.mount_spacing)])
 cost=int(config.mount_cost)
 warning_ticks=Clock.ticks_for(config.mount_warning)
 extra_enemies=int(config.mount_assault)
 recovery_discount=int(config.mount_recovery)
func powered() -> bool:return rotations==[1,2]
func turn(index: int) -> bool:
 if not enabled or recovered or index not in [0,1]:return false
 rotations[index]=(rotations[index]+1)%3
 return true
func recover() -> bool:
 if not enabled or recovered or not powered():return false
 recovered=true
 return true
func restore_stable(now: int) -> bool:
 if not enabled or not recovered or unlocked:return false
 unlocked=true;riding=true;warning_until=now+warning_ticks
 return true
func toggle() -> bool:
 if not unlocked:return false
 riding=not riding
 return true
func night_bonus(day: int, now: int) -> int:
 if not enabled or warning_until==0 or now<warning_until:return 0
 if raid_day==0:
  raid_day=day
  return extra_enemies
 if day>raid_day and not recovery_used:
  recovery_used=true
  return -recovery_discount
 return 0
func warning(now: int) -> bool:
 return enabled and warning_until>0 and raid_day==0 and now>=warning_until-warning_ticks
func capture() -> Dictionary:
 return {"rotations":rotations.duplicate(),"recovered":recovered,"unlocked":unlocked,"riding":riding,"warning_until":warning_until,"raid_day":raid_day,"recovery_used":recovery_used}
func restore(data: Variant, now: int, day: int) -> bool:
 if not data is Dictionary or data.size()!=7:return false
 if not data.get("rotations") is Array or data.rotations.size()!=2:return false
 for v: Variant in data.rotations:
  if not v is int or v<0 or v>2:return false
 for key: String in ["recovered","unlocked","riding","recovery_used"]:
  if not data.get(key) is bool:return false
 for key: String in ["warning_until","raid_day"]:
  if not data.get(key) is int or data[key]<0:return false
 if data.raid_day>day or data.warning_until>now+warning_ticks:return false
 if data.recovered and (not enabled or data.rotations!=[1,2]):return false
 if data.riding and not data.unlocked:return false
 if data.warning_until>0 and (not enabled or not data.recovered or not data.unlocked):return false
 if data.raid_day>0 and data.warning_until==0:return false
 if data.recovery_used and data.raid_day==0:return false
 if not enabled and (data.rotations!=[0,0] or data.recovered or data.warning_until>0):return false
 rotations.assign(data.rotations);recovered=data.recovered;unlocked=data.unlocked;riding=data.riding
 warning_until=data.warning_until;raid_day=data.raid_day;recovery_used=data.recovery_used
 return true
static func valid_config(config: Dictionary) -> bool:
 var limits: Dictionary={"mount_enabled":Vector2(0,1),"mount_distance":Vector2(1800,3800),"mount_spacing":Vector2(240,400),"mount_cost":Vector2(1,12),"mount_warning":Vector2(30,180),"mount_assault":Vector2(2,12),"mount_recovery":Vector2(1,12)}
 if not limits.keys().any(func(k: String)->bool:return config.has(k)):return true
 for key: String in limits:
  var value: Variant=config.get(key)
  if not (value is int or value is float) or not is_finite(float(value)):return false
  if value<limits[key].x or value>limits[key].y:return false
  if key in ["mount_enabled","mount_cost","mount_assault","mount_recovery"] and floorf(value)!=value:return false
 return true
