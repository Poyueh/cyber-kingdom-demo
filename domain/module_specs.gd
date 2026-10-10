extends RefCounted
const Clock=preload("res://domain/time/tick_clock.gd")
const IDS: Array[String]=["arc","lance","magnet","frost","gravity","workshop","command","capacitor"]
class Spec extends RefCounted:
 var id: String
 var damage: int
 var cost: float
 var reach: float
 var cooldown: int
 var planet: int=0
 var side: int=1
 var targets: int=100
 var duration: int=0
 var power: float=0
 var boss_power: float=0
 var boss_duration: int=0
 var threshold: float=0
static func build(config: Dictionary) -> Array[Spec]:
 var result: Array[Spec]=[]
 for id: String in ["arc","lance"]:
  var spec: Spec=Spec.new();spec.id=id;spec.side=-1 if id=="arc" else 1
  var prefix: String="module_"+id+"_"
  # Legacy two-module runs retain their existing values and fallback rules.
  spec.damage=clampi(config.get(prefix+"damage",32 if id=="arc" else 55),1,150)
  spec.cost=clampf(config.get(prefix+"cost",20.0 if id=="arc" else 25.0),1,60)
  spec.reach=clampf(config.get(prefix+"range",150.0 if id=="arc" else 300.0),60,600)
  spec.cooldown=Clock.ticks_for(clampf(config.get(prefix+"cooldown",6.0 if id=="arc" else 8.0),1,30))
  result.append(spec)
 if not config.has("module_catalog_version"):return result
 assert(valid_config(config),"Invalid module rules")
 for id: String in IDS.slice(2):
  var spec: Spec=Spec.new();spec.id=id
  var prefix: String="module_"+id+"_"
  for key: String in ["planet","side","damage","cost","reach","targets","power","boss_power","threshold"]:spec.set(key,config[prefix+key])
  for key: String in ["cooldown","duration","boss_duration"]:spec.set(key,Clock.ticks_for(config[prefix+key]))
  result.append(spec)
 return result
static func valid_config(config: Dictionary) -> bool:
 var extended: bool=config.has("module_catalog_version")
 for id: String in IDS.slice(2):
  var prefix: String="module_"+id+"_"
  if not extended:
   for key: String in config:
    if key.begins_with(prefix):return false
   continue
  if config.module_catalog_version!=1:return false
  var limits: Dictionary={"planet":Vector2(1,6),"side":Vector2(-1,1),"damage":Vector2(0,150),"cost":Vector2(0,60),"reach":Vector2(60,600),"cooldown":Vector2(1,30),"targets":Vector2(1,5),"duration":Vector2(0,10),"power":Vector2(0,50),"boss_power":Vector2(0,1),"boss_duration":Vector2(0,10),"threshold":Vector2(0,100)}
  for key: String in limits:
   var value: Variant=config.get(prefix+key)
   if not (value is int or value is float) or not is_finite(value) or value<limits[key].x or value>limits[key].y:return false
   if key in ["planet","side","damage","targets"] and value!=floorf(value):return false
  if config[prefix+"side"] not in [-1,1]:return false
  if id in ["frost","workshop","command","capacitor"] and config[prefix+"duration"]<=0:return false
  if id=="frost" and (config[prefix+"power"]>1 or config[prefix+"boss_duration"]<=0):return false
 return true
