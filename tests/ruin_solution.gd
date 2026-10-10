extends RefCounted
## Authored player routes, independent of the puzzle implementation.
static func solve(sim: RefCounted, planet: int) -> void:
 var actions: Array[int]=[];var times: Array[int]=[]
 match planet:
  1:actions.assign([0,2])
  2:actions.assign([0,0,1,2])
  3:actions.assign([1,2])
  4:actions.assign([1,1,0,2])
  5:actions.assign([0,1,2]);times.assign([0,4,8])
  6:actions.assign([0,1,2]);times.assign([4,6,8])
 var site: RefCounted=sim.trials.sites[0]
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 var base: int=int(sim.workforce.elapsed/24)*24+24
 for i: int in range(actions.size()):
  if not times.is_empty():sim.workforce.elapsed=float(base+times[i])
  sim.interact(site.positions[actions[i]],"trial:%s:%d"%[site.id,actions[i]])
