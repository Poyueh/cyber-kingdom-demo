extends RefCounted
## Read-only UI data. Unknown regions never disclose terrain or unclaimed rewards.
const TITLES: Dictionary={"forest":"旅人林地","quarry":"龍脊晶谷","ruins":"斷環聖所"}
static func read(sim: RefCounted, knight_x: float) -> Dictionary:
 var regions: Array[Dictionary]=[]
 var markers: Array[Dictionary]=[_marker("camp",sim.world.sites.hall,"營火")]
 for region: Dictionary in sim.frontier.regions:
  var known: bool=region.discovered
  regions.append({"x":float(region.x),"width":float(region.width),"kind":region.kind if known else "unknown","title":TITLES.get(region.kind,"未探索") if known else "未探索"})
 regions.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.x<b.x)
 for node: RefCounted in sim.frontier.nodes:
  if node.kind=="cache" and not node.collected and sim.frontier.regions[node.region].discovered:
   markers.append(_marker("chest",node.x,"寶箱"))
 for relic: RefCounted in sim.modules.relics:
  if not sim.modules.found.has(relic.id) and sim.frontier.regions[relic.region].discovered:
   markers.append(_marker("gear" if sim.trials.unlocked(relic.id) else "lock",relic.x,"特殊部件" if sim.trials.unlocked(relic.id) else "封印遺跡"))
 for rift: Dictionary in sim.mission.rifts:
  if rift.discovered:markers.append(_marker("check" if rift.sealed else "rift",rift.x,"已封印" if rift.sealed else "地獄之門"))
 return {"left":float(sim.frontier.left_boundary),"right":float(sim.frontier.right_boundary),"knight":knight_x,"regions":regions,"markers":markers}
static func _marker(kind: String, x: float, title: String) -> Dictionary:
 return {"kind":kind,"x":x,"title":title}
