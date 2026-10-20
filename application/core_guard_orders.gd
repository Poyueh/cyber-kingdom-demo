extends RefCounted
## Stable side orders follow live defenses; the station owns payment and access.
const Rules=preload("res://domain/defense_rules.gd")
var rules: Rules=Rules.new()
func station_x(sim: RefCounted) -> float:return sim.world.sites.hunt_tools+rules.station_offset
func at_station(sim: RefCounted, x: float) -> bool:return sim.core_loop.enabled and sim.frontier.city_level>0 and sim.core_loop.income>0 and absf(x-station_x(sim))<=rules.station_radius
func order(sim: RefCounted, target: String, delta: int, x: float) -> bool:
 if not at_station(sim,x) or not sim.is_running() or delta not in [-1,1]:return false
 if delta>0 and sim.pouch.amount<rules.assignment_cost:return false
 if not assign(sim,target,delta):return false
 if delta>0:
  sim.command.learn("guard_station")
  sim.pouch.amount-=rules.assignment_cost
  sim.effects.append({"kind":"crystal_spent","x":station_x(sim),"life":0.5})
 return true
var targets: Array[String]=[]
func clean(sim: RefCounted) -> void:
 if targets.size()>sim.world.people.size():targets.resize(sim.world.people.size())
 while targets.size()<sim.world.people.size():targets.append("")
 for i: int in range(targets.size()):
  if i>=sim.world.people.size() or sim.world.people[i].role!="hunter":targets[i]=""
 # A destroyed/downgraded tower releases only slots that no longer exist.
 for post: String in ["beacon","core_tower_right"]:
  var kept: int=0
  for i: int in range(targets.size()):
   if targets[i]!=post:continue
   kept+=1
   if kept>capacity(sim,post):targets[i]="wall_left" if side(sim,post)<0 else "wall"
func tower_id(sim: RefCounted, target: String) -> String:
 var direction: int=-1 if target=="beacon" else 1
 var result: String=target
 var bounds: Vector2=sim.defenses.work_bounds()
 for id: String in sim.buildings:
  var site: Dictionary=sim.buildings[id]
  if site.kind!="tower" or site.level<=0 or site.pending:continue
  if direction*(site.x-sim.world.sites.hall)<=0:continue
  if site.x<bounds.x or site.x>bounds.y:continue
  if not sim.buildings.has(result) or sim.buildings[result].level<=0 or direction*site.x>direction*sim.buildings[result].x:result=id
 return result
func capacity(sim: RefCounted, target: String) -> int:
 if target in ["wall","wall_left"]:return sim.world.people.size()
 var id: String=tower_id(sim,target)
 return clampi(int(sim.buildings[id].level),0,3) if sim.buildings.has(id) else 0
func usable(sim: RefCounted, target: String) -> bool:
 if target in ["wall","wall_left"]:
  var post: String=sim.defenses.active_post(-1 if target=="wall_left" else 1)
  var wall: Dictionary=sim.world.walls[post]
  return wall.level>0 and wall.hp>0 and not wall.pending
 if sim.buildings.has(target):
  var site: Dictionary=sim.buildings[tower_id(sim,target)]
  return site.kind=="tower" and site.level>0 and not site.pending
 return false
func position(sim: RefCounted, target: String) -> float:
 if target in ["wall","wall_left"]:
  var direction: int=-1 if target=="wall_left" else 1
  var bounds: Vector2=sim.defenses.work_bounds()
  return (bounds.x if direction<0 else bounds.y)-direction*90.0
 var id: String=tower_id(sim,target)
 return float(sim.buildings[id].x) if sim.buildings.has(id) else sim.world.sites.hall
func side(sim: RefCounted, target: String) -> int:
 return -1 if position(sim,target)<sim.world.sites.hall else 1
func has_candidate(sim: RefCounted, target: String) -> bool:
 for i: int in range(sim.world.people.size()):
  if sim.world.people[i].role=="hunter" and not sim.command.contains(i) and (i>=targets.size() or targets[i]!=target):return true
 return false
func assign(sim: RefCounted, target: String, delta: int) -> bool:
 clean(sim)
 if target not in ["wall","wall_left","beacon","core_tower_right"]:return false
 if delta<0:
  for i: int in range(targets.size()-1,-1,-1):
   if targets[i]==target:targets[i]="";return true
  return false
 if not usable(sim,target) or (target not in ["wall","wall_left"] and targets.count(target)>=capacity(sim,target)):return false
 var selected: int=-1
 var distance: float=INF
 for i: int in range(targets.size()):
  if sim.world.people[i].role!="hunter" or targets[i]==target or sim.command.contains(i):continue
  var score: float=absf(sim.world.people[i].x-position(sim,target))+(0 if targets[i].is_empty() else 10000)
  if score<distance:selected=i;distance=score
 if selected<0:return false
 targets[selected]=target
 sim.world.people[selected]["defense_post"]="wall_left" if side(sim,target)<0 else "wall"
 return true
## Archers ordered to a usable post, whether or not they have reached it yet.
func assigned(sim: RefCounted, target: String) -> int:
 if not usable(sim,target):return 0
 var count: int=0
 for i: int in range(mini(targets.size(),sim.world.people.size())):
  if targets[i]==target and sim.world.people[i].role=="hunter":count+=1
 return count
func arrived(sim: RefCounted, target: String, radius: float) -> int:
 if not usable(sim,target):return 0
 var count: int=0
 for i: int in range(mini(targets.size(),sim.world.people.size())):
  if targets[i]==target and sim.world.people[i].role=="hunter" and absf(sim.world.people[i].x-position(sim,target))<=radius:count+=1
 return count
func destination(sim: RefCounted, index: int) -> float:
 clean(sim)
 var target: String=targets[index]
 if target.is_empty():return sim.world.sites.hunt_tools
 if not usable(sim,target):return sim.world.sites.hall+side(sim,target)*100.0
 var at: float=position(sim,target)
 if target in ["beacon","core_tower_right"]:
  var rank: int=0
  for i: int in range(index):
   if targets[i]==target:rank+=1
  at+=(rank-(targets.count(target)-1)*0.5)*20.0
 return at
func must_return(sim: RefCounted, index: int) -> bool:
 if index>=targets.size() or targets[index].is_empty():return true
 var target: String=targets[index]
 if target not in ["wall","wall_left"] or not usable(sim,target):return true
 if sim.core_loop.stage<3 or sim.clock.is_night:return true
 var journey: float=absf(sim.world.people[index].x-destination(sim,index))/sim._person_speed
 return sim.clock.remaining<=journey+sim.return_margin or sim.life.threatened(sim.world.people[index],sim.raiders)
