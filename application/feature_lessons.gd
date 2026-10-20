extends RefCounted
## Learn from successful actions and actual use, never from showing a caption.
const IDS: Array[String]=["barracks","rally","rescue_repair","rescue_recruit","farm","farm_tools","module","mount","rift","rocket","star_map","merchant","tower","ruin","mount_stable"]
static func observe(sim: RefCounted) -> void:
 var command: RefCounted=sim.command
 if sim.frontier.farm_active:command.learn("farm")
 if sim.world.tools.hoe>0 or sim.world.people.any(func(p: Dictionary)->bool:return p.role=="farmer"):command.learn("farm_tools")
 if sim.world.tools.blade>0 or sim.world.people.any(func(p: Dictionary)->bool:return p.role=="guard"):command.learn("barracks")
 if sim.mount_quest.unlocked:command.learn("mount_stable")
 if sim.mount_quest.riding:command.learn("mount")
 if sim.mission.rifts.any(func(r: Dictionary)->bool:return r.ordered or r.sealed):command.learn("rift")
 if sim.planet.rocket_ready or sim.planet.rocket_pending:command.learn("rocket")
 if sim.buildings.values().any(func(b: Dictionary)->bool:return b.kind=="tower" and b.level>0):command.learn("tower")
static func executed(sim: RefCounted, id: String) -> void:
 var mapped: String={"command_armory":"barracks","armory":"barracks","mount_switch":"mount","mount_stable":"mount_stable","module_station":"module","merchant":"merchant","rift":"rift","rocket":"rocket","star_map":"star_map","farm":"farm","farm_tools":"farm_tools","tower":"tower","trial":"ruin"}.get(id,"")
 if not mapped.is_empty():sim.command.learn(mapped)
static func next(sim: RefCounted, x: float) -> Dictionary:
 if not sim.command.enabled or sim.core_loop.skipped or not sim.is_running():return {}
 if sim.clock.is_night or sim.life.threatened({"x":x},sim.raiders) or sim.mission.dragon_summoned:return {}
 var hint: Dictionary=sim.command.guidance(x)
 if not hint.is_empty():return hint
 var existing: Dictionary=preload("res://application/planet_operations.gd").guidance(sim)
 if not existing.is_empty():
  var feature: String="rocket" if existing.get("key")=="rocket" else "star_map" if existing.get("key")=="star_map" else ""
  if feature.is_empty() or feature not in sim.command.used:return existing
 var choices: Array[Dictionary]=[]
 if sim.frontier.city_level>=2:
  if "farm_tools" not in sim.command.used:choices.append(sim.command._hint("farm_tools",sim.world.sites.farm_tools,"farm_tools","tool"))
  if "farm" not in sim.command.used:choices.append(sim.command._hint("farm",sim.world.sites.farm,"farm","harvest"))
 if not sim.modules.found.is_empty() and "module" not in sim.command.used:choices.append(sim.command._hint("module",sim.world.sites.drill,"","tool"))
 if sim.merchant.can_dispatch() and "merchant" not in sim.command.used:choices.append(sim.command._hint("merchant",sim.merchant.x,"merchant","trade"))
 if "mount" not in sim.command.used and sim.mount_quest.unlocked:choices.append(sim.command._hint("mount",sim.mount_quest.stable_x,"mount_switch","explore"))
 elif "mount_stable" not in sim.command.used and sim.mount_quest.recovered:choices.append(sim.command._hint("mount_stable",sim.mount_quest.stable_x,"mount_stable","tool"))
 if "rift" not in sim.command.used and sim.rift_requirements().is_empty():
  for i: int in range(sim.mission.rifts.size()):
   var rift: Dictionary=sim.mission.rifts[i]
   if rift.discovered and not rift.sealed:choices.append(sim.command._hint("rift",rift.x,"rift:%d"%i,"rift"))
 if "tower" not in sim.command.used:
  for id: String in sim.buildings:
   if sim.buildings[id].kind=="tower" and sim.building_visible(id):choices.append(sim.command._hint("tower",sim.buildings[id].x,"building:%s:%d"%[id,sim.buildings[id].level],"tool"))
 if "ruin" not in sim.command.used:
  for relic: RefCounted in sim.modules.relics:
   if not sim.trials.unlocked(relic.id) and preload("res://application/ruin_interactions.gd").known(sim,relic.x):choices.append(sim.command._hint("ruin",relic.x,"","explore"))
 choices.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return absf(a.x-x)<absf(b.x-x))
 return choices[0] if not choices.is_empty() else {}
