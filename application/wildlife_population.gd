extends RefCounted
## Author a bounded population only when a newly resolved world opts in.
const Level=preload("res://domain/planet_level_layout.gd")
static func apply(sim: RefCounted, config: Dictionary) -> void:
 if not config.has("wildlife_version"):return
 var map: RefCounted=sim.frontier
 var count: int=int(config.wildlife_per_forest)
 map.animals.clear()
 if sim.core_loop.enabled and sim.core_loop.forest:
  for index: int in range(6):_add(map,float(config["wildlife_near_%d"%index]))
 for index: int in range(map.regions.size()):
  var region: Dictionary=map.regions[index]
  if region.kind!="forest" or not Level.is_supply(region):continue
  # The near-camp group owns the overlapping onboarding regions.
  if sim.core_loop.enabled and sim.core_loop.forest and absf(region.x+region.width/2)<1700:continue
  for slot: int in range(count):
   var position: float=region.x+region.width*(0.18+0.64*float(slot)/maxi(1,count-1))
   if sim.core_loop.enabled and sim.core_loop.forest and absf(position)<1500:continue
   _add(map,position,index)

static func _add(map: RefCounted, position: float, region_index: int=-1) -> void:
 if region_index<0:
  for index: int in range(map.regions.size()):
   var region: Dictionary=map.regions[index]
   if region.kind=="forest" and position>=region.x and position<region.x+region.width:region_index=index;break
 if region_index>=0:map.animals.append({"x":position,"region":region_index,"alive":true})

static func valid(config: Dictionary) -> bool:
 if not config.has("wildlife_version"):return not config.has("wildlife_per_forest") and not config.has("wildlife_near_0")
 if config.wildlife_version!=1 or config.get("wildlife_per_forest") not in [2,3,4]:return false
 var previous: float=-INF
 for index: int in range(6):
  var value: Variant=config.get("wildlife_near_%d"%index)
  if not (value is float or value is int):return false
  if not is_finite(value) or value<=previous or absf(value)<1100 or absf(value)>1500:return false
  previous=value
 return true
