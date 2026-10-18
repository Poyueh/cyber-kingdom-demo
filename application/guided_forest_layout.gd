extends RefCounted
const CoreLayout=preload("res://application/core_loop_layout.gd")
const Sites=preload("res://domain/building_sites.gd")
## Keep distant authored regions, relics, gates and existing world boundaries.
static func apply(sim: RefCounted, config: Dictionary) -> void:
 var map: RefCounted=sim.frontier
 var distant: Array=map.nodes.filter(func(n: RefCounted)->bool:return absf(n.x)>1500.0)
 var original_regions: Array=map.regions.duplicate(true)
 var original_rifts: Array=sim.mission.rifts.duplicate(true)
 var original_relics: Array=sim.modules.relics.duplicate(true)
 var bounds: Vector2=Vector2(map.left_boundary,map.right_boundary)
 CoreLayout.apply(sim,config)
 var central: Array=map.regions.slice(0,2).duplicate(true)
 map.regions.assign(original_regions)
 for area: Dictionary in central:
  area["level_role"]=0
  map.regions.append(area)
 for node: RefCounted in map.nodes:
  for i: int in range(map.regions.size()):
   var area: Dictionary=map.regions[i]
   if node.x>=area.x and node.x<area.x+area.width:node.region=i;break
 map.nodes.append_array(distant)
 map.left_boundary=bounds.x;map.right_boundary=bounds.y
 sim.pouch.left_boundary=bounds.x;sim.pouch.right_boundary=bounds.y
 sim.defenses=preload("res://domain/frontier_defenses.gd").new(sim.world,map,config)
 sim.work_area=preload("res://domain/resident_work_area.gd").new(sim.world,sim.defenses,float(config.get("work_margin",850.0)))
 sim.workforce.work_area=sim.work_area
 sim.buildings=Sites.generate(map,sim.map_seed,-610.0)
 sim.buildings["core_tower_right"]=Sites._site("tower",670.0,-1,-1)
 sim._register_building_walls()
 sim.mission.rifts.assign(original_rifts)
 sim.modules.relics.assign(original_relics)
 sim.merchant.enabled=int(config.get("merchant_enabled",0))==1
 for site: RefCounted in sim.trails.sites:
  for i: int in range(map.regions.size()):
   var area: Dictionary=map.regions[i]
   if site.x>=area.x and site.x<area.x+area.width:site.region=i;break
