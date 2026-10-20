extends RefCounted
## Targets align with stable resident indices; reassignment costs travel, never crystals.
var targets: Array[String]=[]
func clean(sim: RefCounted) -> void:
 while targets.size()<sim.world.people.size():targets.append("")
 for i: int in range(targets.size()):
  if i>=sim.world.people.size() or sim.world.people[i].role!="hunter":targets[i]=""
 # A destroyed/downgraded tower releases only slots that no longer exist.
 for post: String in ["beacon","core_tower_right"]:
  var kept: int=0
  for i: int in range(targets.size()):
   if targets[i]!=post:continue
   kept+=1
   if kept>capacity(sim,post):targets[i]=""
func capacity(sim: RefCounted, target: String) -> int:
 if target in ["wall","wall_left"]:return sim.world.people.size()
 return clampi(int(sim.buildings[target].level),0,3) if sim.buildings.has(target) else 0
func usable(sim: RefCounted, target: String) -> bool:
 if target in ["wall","wall_left"]:
  var post: String=sim.defenses.active_post(-1 if target=="wall_left" else 1) if not sim.core_loop.trial and sim.core_loop.stage>=3 else target
  var wall: Dictionary=sim.world.walls[post]
  return wall.level>0 and wall.hp>0 and not wall.pending
 if sim.buildings.has(target):
  var site: Dictionary=sim.buildings[target]
  return site.kind=="tower" and site.level>0 and not site.pending
 return false
func position(sim: RefCounted, target: String) -> float:
 if target in ["wall","wall_left"]:
  var post: String=sim.defenses.active_post(-1 if target=="wall_left" else 1) if not sim.core_loop.trial and sim.core_loop.stage>=3 else target
  return sim.world.sites[post]+(90.0 if target=="wall_left" else -90.0)
 return float(sim.buildings[target].x) if sim.buildings.has(target) else sim.world.sites.hall
func side(sim: RefCounted, target: String) -> int:
 return -1 if position(sim,target)<sim.world.sites.hall else 1
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
