extends RefCounted
## Bounded, deterministic ruin circuits. Only bounded progress, deadlines and mechanism state are mutable.
const Mechanism=preload("res://domain/ruin_mechanism.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
class Site extends RefCounted:
 var id: String
 var x: float
 var region: int
 var mechanism: Mechanism
 var timed: bool
 var order: Array[int]=[0,1,2]
 var positions: Array[float]=[]
 var progress: int=0
 var deadline: int=0
var sites: Array[Site]=[]
var duration: int=0
var radius: float=0
func _init(relics: Array, config: Dictionary, rng: RandomNumberGenerator) -> void:
 if int(config.get("ruin_enabled",0))!=1:return
 duration=Clock.ticks_for(config.ruin_seconds);radius=config.ruin_radius
 for relic: RefCounted in relics:
  var site: Site=Site.new()
  site.id=relic.id;site.x=relic.x;site.region=relic.region;site.timed=relic.id=="lance"
  var inward: float=-signf(site.x)
  for index: int in range(3):site.positions.append(site.x+inward*float(config.ruin_spacing)*(3-index))
  if not site.timed:
   for index: int in range(2,0,-1):
    var other: int=rng.randi_range(0,index)
    var previous: int=site.order[index];site.order[index]=site.order[other];site.order[other]=previous
  if Mechanism.configured(config):
   site.mechanism=Mechanism.new(config,int(config.planet_id));site.timed=false;site.progress=site.mechanism.progress()
  sites.append(site)
static func valid_config(config: Dictionary) -> bool:
 if not Mechanism.valid_config(config):return false
 var limits: Dictionary={"ruin_enabled":Vector2(0,1),"ruin_seconds":Vector2(5,60),"ruin_radius":Vector2(24,60),"ruin_spacing":Vector2(180,320)}
 if not limits.keys().any(func(key: String)->bool:return config.has(key)):return true
 for key: String in limits:
  var value: Variant=config.get(key)
  if not (value is int or value is float) or not is_finite(float(value)):return false
  if value<limits[key].x or value>limits[key].y:return false
 return config.ruin_enabled in [0,1]
func get_site(id: String) -> Site:
 for site: Site in sites:
  if site.id==id:return site
 return null
func unlocked(id: String) -> bool:
 var site: Site=get_site(id)
 return site==null or site.progress==3
func advance(now: int) -> void:
 for site: Site in sites:
  if site.deadline>0 and now>=site.deadline:site.progress=0;site.deadline=0
func activate(id: String, station: int, now: int) -> bool:
 advance(now)
 var site: Site=get_site(id)
 if site==null or site.progress==3 or station<0 or station>2:return false
 if site.mechanism!=null:
  var success: bool=site.mechanism.activate(station,now)
  site.progress=site.mechanism.progress()
  return success
 if station!=site.order[site.progress]:
  site.progress=0;site.deadline=0
  return false
 if site.progress==0 and site.timed:site.deadline=now+duration
 site.progress+=1
 if site.progress==3:site.deadline=0
 return true
func capture() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for site: Site in sites:
  var row: Dictionary={"id":site.id,"progress":site.progress,"deadline":site.deadline}
  if site.mechanism!=null:row["mechanism"]=site.mechanism.capture()
  result.append(row)
 return result
func restore(data: Variant, now: int) -> bool:
 if not data is Array or data.size()!=sites.size():return false
 for index: int in range(sites.size()):
  var row: Variant=data[index]
  var site: Site=sites[index]
  if not row is Dictionary or row.size()!=(4 if site.mechanism!=null else 3) or row.get("id")!=site.id:return false
  if not row.get("progress") is int or not row.get("deadline") is int:return false
  if row.progress<0 or row.progress>3 or row.deadline<0:return false
  var running: bool=site.timed and row.progress in [1,2]
  if running and (row.deadline<=now or row.deadline>now+duration):return false
  if not running and row.deadline!=0:return false
  if site.mechanism!=null:
   var before: Dictionary=site.mechanism.capture()
   var valid: bool=site.mechanism.restore(row.get("mechanism"),row.progress)
   site.mechanism.restore(before,site.progress)
   if not valid:return false
 for index: int in range(sites.size()):
  sites[index].progress=data[index].progress;sites[index].deadline=data[index].deadline
  if sites[index].mechanism!=null:sites[index].mechanism.restore(data[index].mechanism,data[index].progress)
 return true

func unlock(id: String) -> void:
 var site: Site=get_site(id)
 if site==null:return
 if site.mechanism!=null:site.mechanism.unlock()
 site.progress=3;site.deadline=0
