extends RefCounted
## Building footprints reserve ground before the first construction completes.
const HALF: float=70.0
const GAP: float=10.0
const HIDDEN: Array[String]=["forge","trade","heal","horn","armory","beacon"]
var buildings: Dictionary={}
var investments: Dictionary={}
var reserved: Array[Vector2]=[]
var _world: RefCounted
var _frontier: RefCounted
var _defenses: RefCounted
var _anchors: Array[Vector2]=[]
var _bounds: Vector2=Vector2(INF,INF)
var _stamp: int=0
var _left: float=NAN
var _right: float=NAN
func _init(world: RefCounted, frontier: RefCounted, defenses: RefCounted) -> void:
 _world=world;_frontier=frontier;_defenses=defenses
func occupied(skip: String="") -> Array[Vector2]:
 var result: Array[Vector2]=reserved.duplicate()
 for id: String in _world.sites:
  if id==skip or id in HIDDEN:continue
  if _world.walls.has(id):
   var wall: Dictionary=_world.walls[id]
   if id not in ["wall","wall_left"] and wall.level<=0 and not wall.pending and not funded(id+":"):continue
   result.append(Vector2(_world.sites[id],24));continue
  result.append(Vector2(_world.sites[id],HALF))
 for id: String in buildings:
  var site: Dictionary=buildings[id]
  if id==skip or site.kind=="wall":continue # Same wall identity is already in world.sites.
  if id not in ["beacon","core_tower_right"] and site.level<=0 and not site.pending and not funded("building:"+id+":"):continue
  result.append(Vector2(site.x,36 if site.kind=="tower" else HALF))
 for i: int in range(_frontier.regions.size()):
  var area: Dictionary=_frontier.regions[i]
  if skip=="outpost:%d"%i or not area.outpost_ready:continue
  if area.outpost_built or area.outpost_pending or funded("outpost:%d"%i):result.append(Vector2(area.outpost_x,HALF))
 return result
func funded(prefix: String) -> bool:
 for key: String in investments:
  if key.begins_with(prefix) and int(investments[key])>0:return true
 return false
static func fits(x: float, half: float, anchors: Array[Vector2]) -> bool:
 for anchor: Vector2 in anchors:
  if absf(x-anchor.x)<half+anchor.y+GAP-0.01:return false
 return true
func barracks_x(side: int, inset: float) -> float:
 var anchors: Array[Vector2]=occupied()
 var live: Vector2=_defenses.work_bounds()
 # When the last wall is ruined, use the starting wall ruins rather than squeezing two barracks onto the campfire.
 var bounds: Vector2=Vector2(minf(live.x,_world.sites.wall_left),maxf(live.y,_world.sites.wall))
 var stamp: int=anchors.hash()
 if bounds!=_bounds or stamp!=_stamp:
  _bounds=bounds;_stamp=stamp;_anchors=anchors
  _left=_find(-1,inset);_right=_find(1,inset)
 return _left if side<0 else _right
func _find(side: int, inset: float) -> float:
 var edge: float=_bounds.x if side<0 else _bounds.y
 var ideal: float=edge-side*inset
 var low: float=_bounds.x+HALF+GAP
 var high: float=_world.sites.hall-HALF-GAP
 if side>0:low=_world.sites.hall+HALF+GAP;high=_bounds.y-HALF-GAP
 var best: float=NAN;var distance: float=INF
 for point: int in range(ceili(low),floori(high)+1,2):
  if absf(point-ideal)<distance and fits(point,HALF,_anchors):best=point;distance=absf(point-ideal)
 return best
func available(sim: RefCounted, id: String, x: float, half: float=HALF) -> bool:
 var anchors: Array[Vector2]=occupied(id)
 if sim.command.unlocked():
  for side: int in [-1,1]:
   var at: float=barracks_x(side,sim.command.rules.barracks_inset)
   if is_finite(at):anchors.append(Vector2(at,HALF))
 return fits(x,half,anchors)
