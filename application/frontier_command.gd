extends RefCounted
## Command posts are projections of live walls. Only expedition and rescue facts persist.
const Rules=preload("res://domain/command_rules.gd")
const Squad=preload("res://domain/expedition_squad.gd")
const Lessons=preload("res://application/feature_lessons.gd")
var rules: Rules=Rules.new()
var squads: Array[Squad]=[]
var used: Array[String]=[]
var repaired: bool=false
var waiting: int=0
var last_day: int=0
var ship_x: float=0.0
var enabled: bool=false
var _ship_placed: bool=false
var _orders_enabled: bool=false
var _world: RefCounted
var _frontier: RefCounted
var _defenses: RefCounted
var space: RefCounted
func _init(world: RefCounted, frontier: RefCounted, defenses: RefCounted, config: Dictionary) -> void:
 _world=world;_frontier=frontier;_defenses=defenses;rules.apply(config)
 space=preload("res://application/construction_space.gd").new(world,frontier,defenses)
 enabled=int(config.get("immersive_loop",0))==1 and int(config.get("core_loop_version",0))!=1
 ship_x=_world.sites.hall+2200 # Final placement binds the actual building blueprints immediately after construction.
func unlocked() -> bool:return enabled and _frontier.city_level>=3
func edge(side: int) -> float:
 var bounds: Vector2=_defenses.work_bounds()
 return bounds.x if side<0 else bounds.y
func flag_x(side: int) -> float:return edge(side)+side*rules.flag_offset
func barracks_x(side: int=1) -> float:return space.barracks_x(side,rules.barracks_inset)
func bind_space(sim: RefCounted) -> void:
 _orders_enabled=sim.core_loop.enabled
 if not _ship_placed:
  ship_x=_wreck_location(sim.buildings);_ship_placed=true
 space.buildings=sim.buildings;space.investments=sim.investments
 space.reserved.assign([Vector2(ship_x,192),Vector2(sim.mount_quest.stable_x,100),Vector2(sim.spirit.shrine_x(_world.sites.hall),40),Vector2(preload("res://application/planet_operations.gd").rocket_x(sim),70)])
func reserved_indices(sim: RefCounted) -> Array[int]:
 var result: Array[int]=[]
 for squad: Squad in squads:
  for index: int in squad.members:result.append(index)
 if sim.investments.get("rally:-1",0)>0 or sim.investments.get("rally:1",0)>0:
  for index: int in roster(sim):
   if index not in result:result.append(index)
 return result
func contains(index: int) -> bool:
 for squad: Squad in squads:
  if index in squad.members:return true
 return false
func inside(x: float) -> bool:return x>edge(-1)+rules.city_inset and x<edge(1)-rules.city_inset
func _wreck_location(buildings: Dictionary={}) -> float:
 # A ship is wide: prefer actual free building footprints over distance to a single resource point.
 var anchors: Array[Vector2]=[]
 for id: String in _world.sites:
  anchors.append(Vector2(float(_world.sites[id]),24 if _world.walls.has(id) else 70))
 for site: Dictionary in buildings.values():anchors.append(Vector2(site.x,36 if site.kind=="tower" else 24 if site.kind=="wall" else 70))
 for region: Dictionary in _frontier.regions:
  if region.get("outpost_ready",false):anchors.append(Vector2(region.outpost_x,70))
 var best: float=minf(_world.sites.hall+2200,_frontier.right_boundary-250)
 var clearance: float=-INF
 var best_nature: float=-INF
 for x: int in range(roundi(_world.sites.hall+1750),roundi(minf(_world.sites.hall+3500,_frontier.right_boundary-210)),20):
  if not _frontier.regions.any(func(region: Dictionary)->bool:return x>=region.x+100 and x<=region.x+region.width-100):continue
  var gap: float=INF
  for anchor: Vector2 in anchors:gap=minf(gap,absf(anchor.x-x)-anchor.y)
  var nature: float=INF
  for node: RefCounted in _frontier.nodes:nature=minf(nature,absf(node.x-x))
  # Once the complete ship fits, keep it reasonably close rather than always pushing it to the far edge.
  var usable: float=minf(gap,202.0)
  if usable>clearance or (is_equal_approx(usable,clearance) and nature>best_nature):
   clearance=usable;best_nature=nature;best=x
 return best
func ship_visible() -> bool:
 if not enabled:return false
 for region: Dictionary in _frontier.regions:
  if ship_x>=region.x and ship_x<region.x+region.width:return region.discovered
 return false
func roster(sim: RefCounted) -> Array[int]:
 var result: Array[int]=[]
 for role: String in Rules.ROLES:
  var selected: int=-1;var nearest: float=INF
  for i: int in range(_world.people.size()):
   var person: Dictionary=_world.people[i]
   if person.role!=role or person.hurt>0 or contains(i) or i in result:continue
   if role in ["hunter","guard"] and i<sim.core_loop.orders.targets.size() and not sim.core_loop.orders.targets[i].is_empty():continue
   if role=="engineer" and (sim.mission.rifts.any(func(r: Dictionary)->bool:return r.worker==i and r.ordered and not r.sealed) or _frontier.nodes.any(func(n: RefCounted)->bool:return n.worker==i and n.carried)):continue
   var distance: float=absf(person.x-sim._hero_x)
   if distance<nearest:selected=i;nearest=distance
  if selected>=0:result.append(selected)
 return result
func shortages(sim: RefCounted) -> Array[Dictionary]:
 var available: Array[int]=roster(sim);var result: Array[Dictionary]=[]
 for role: String in ["guard","hunter","engineer"]:
  var count: int=0
  for index: int in available:
   if _world.people[index].role==role:count+=1
  var missing: int=Rules.ROLES.count(role)-count
  if missing>0:result.append({"icon":{"guard":"sword","hunter":"bow","engineer":"hammer"}[role],"value":missing})
 return result
func candidates(sim: RefCounted, x: float, y: float) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if not enabled or absf(y-430)>42:return result
 if unlocked():
  for side: int in [-1,1]:
   if absf(x-flag_x(side))>=73:continue
   var missing: Array[Dictionary]=shortages(sim)
   var choice: Dictionary=sim._choice("rally",flag_x(side),"command.rally",rules.rally_cost,squads.size()<rules.squad_limit and missing.is_empty(),"command.missing")
   choice.key="rally:%d"%side;choice["side"]=side;choice["prerequisites"]=missing
   if squads.size()>=rules.squad_limit:choice.reason="command.limit";choice.prerequisites=[]
   result.append(choice)
  for side: int in [-1,1]:
   var at: float=barracks_x(side)
   if not is_finite(at) or absf(x-at)>=73:continue
   var station: Dictionary=sim._choice("sword_station",at,"defense.sword_station",0)
   station.key="sword_station:%d"%side;station["side"]=side
   if sim.core_loop.enabled:result.append(station)
   var gear: Dictionary=sim._choice("command_armory",at,"command.barracks",sim.prices.armory,_world.tools.blade<3,"core.stock")
   gear.key="command_armory" if side>0 else "command_armory:-1"
   result.append(gear)
 if ship_visible() and absf(x-ship_x)<73:
  var id: String="rescue_recruit" if repaired else "rescue_repair"
  var capacity: bool=_world.people.size()<40
  var ready: bool=unlocked() and (not repaired or (waiting>0 and capacity))
  var choice: Dictionary=sim._choice(id,ship_x,"command."+id,rules.recruit_cost if repaired else rules.repair_cost,ready,"command.wait" if waiting==0 else "command.population")
  choice["prerequisites"]=[] if unlocked() else [{"icon":"camp","value":3}]
  result.append(choice)
 return result
func execute(sim: RefCounted, choice: Dictionary) -> void:
 match choice.id:
  "rally":
   var members: Array[int]=roster(sim)
   if members.size()!=Rules.ROLES.size() or squads.size()>=rules.squad_limit:return
   squads.append(Squad.new(members,choice.side));learn("rally")
   for index: int in members:
    for node: RefCounted in _frontier.nodes:
     if node.worker==index and not node.carried:node.worker=-1
   sim.effects.append({"kind":"tool_produced","x":choice.x,"life":1.0})
  "command_armory":_world.tools.blade+=1;learn("barracks")
  "rescue_repair":repaired=true;last_day=sim.clock.day;learn("rescue_repair");sim.effects.append({"kind":"construction_done","x":ship_x,"life":1.0})
  "rescue_recruit":
   if waiting<=0:return
   waiting-=1;sim._add_person(ship_x,-1);_world.people.back().role="citizen";learn("rescue_recruit")
   sim.effects.append({"kind":"recruited","x":ship_x,"y":430.0,"life":0.7})
func stock_gear(sim: RefCounted, x: float) -> bool:
 var key: String="command_armory:-1" if x<_world.sites.hall else "command_armory"
 var choice: Dictionary=sim.context_for_key(x,key)
 if choice.id!="command_armory" or not choice.enabled or sim.pouch.amount<choice.cost-choice.paid:return false
 for unit: int in range(choice.cost-choice.paid):
  if not sim.interact(x,key):return false
 return true
func learn(id: String) -> void:
 if enabled and id in Lessons.IDS and id not in used:used.append(id)
func observe(sim: RefCounted) -> void:
 if not enabled:return
 bind_space(sim)
 if repaired and sim.clock.day>last_day:
  waiting=mini(rules.passenger_limit,waiting+sim.clock.day-last_day);last_day=sim.clock.day
 for squad: Squad in squads:
  squad.members=squad.members.filter(func(i: int)->bool:return i<_world.people.size() and _world.people[i].role in ["guard","hunter","engineer"])
 squads=squads.filter(func(s: Squad)->bool:return not s.members.is_empty())
 if not squads.is_empty() and inside(sim._hero_x):
  squads.clear();sim.effects.append({"kind":"command_dismissed","x":sim._hero_x,"life":2.0})
 Lessons.observe(sim)
func _formation(index: int, hero_x: float, facing: int) -> float:
 for group: int in range(squads.size()):
  var slot: int=squads[group].members.find(index)
  if slot<0:continue
  var role: String=_world.people[index].role
  var offset: float=(65.0+slot*30.0+group*90.0) if role=="guard" else -(55.0+(slot-3)*30.0+group*90.0)
  return clampf(hero_x+facing*offset,_frontier.left_boundary+24,_frontier.right_boundary-24)
 return hero_x
func target(sim: RefCounted, index: int, seconds: float) -> float:
 var person: Dictionary=_world.people[index]
 if not contains(index):return _claim_sword(sim,person)
 person["y"]=430.0;person["work_state"]="walk";person["sheltering"]=true
 if person.role=="guard":preload("res://application/sword_guard.gd").advance(sim,person,seconds)
 elif person.role=="hunter":sim._shoot_nearest_raider(person,sim.hunter_range,sim.archer_damage(),sim.hunter_interval)
 else:
  var work: float=_escort_work(sim,index,seconds)
  if is_finite(work):return work
 var at: float=_formation(index,sim._hero_x,sim.hero.facing)
 var enemies: Array=sim.raiders.filter(func(e: Dictionary)->bool:return e.fighter.is_alive() and absf(e.x-sim._hero_x)<rules.escort_radius)
 if person.role=="guard" and not enemies.is_empty():
  var enemy: Dictionary=enemies[0]
  for candidate: Dictionary in enemies:
   if absf(candidate.x-person.x)<absf(enemy.x-person.x):enemy=candidate
  at=enemy.x-signf(enemy.x-person.x)*58
 return at
func _claim_sword(sim: RefCounted, person: Dictionary) -> float:
 if not unlocked() or person.role!="citizen" or _world.tools.blade<=0:return NAN
 var left: float=barracks_x(-1);var right: float=barracks_x(1)
 var at: float=left if is_finite(left) and (not is_finite(right) or absf(person.x-left)<absf(person.x-right)) else right
 if not is_finite(at):return NAN
 for kind: String in _world.tools:
  if kind!="blade" and sim._can_claim_tool(kind) and _world.tools[kind]>0 and absf(_world.tool_location(kind)-person.x)<absf(at-person.x):return NAN
 if sim.life.threatened(person,sim.raiders):return NAN
 if absf(person.x-at)<22:
  _world.tools.blade-=1;person.role="guard";person["defense_post"]="wall";person.erase("roam_role")
 return at
func _escort_work(sim: RefCounted, index: int, seconds: float) -> float:
 var person: Dictionary=_world.people[index]
 if sim.life.threatened(person,sim.raiders):return NAN
 var work: float=sim.modules.construction_seconds(person,seconds,roundi(sim.workforce.elapsed*30))
 for rift: Dictionary in sim.mission.rifts:
  if rift.worker==index and rift.ordered and not rift.sealed and absf(rift.x-sim._hero_x)<=rules.escort_radius:return sim.expedition.target(index,seconds)
 for id: String in _world.walls:
  if not _world.walls[id].pending or absf(_world.sites[id]-sim._hero_x)>rules.escort_radius:continue
  var at: float=_world.sites[id]-signf(_world.sites[id]-_world.sites.hall)*12
  if absf(person.x-at)<8:person.work_state="work";_world.work_wall(index,work,id)
  return at
 for id: String in sim.buildings:
  var site: Dictionary=sim.buildings[id]
  if not site.pending or absf(site.x-sim._hero_x)>rules.escort_radius:continue
  if absf(person.x-site.x)<8:
   person.work_state="work";site.progress+=work
   if site.progress>=sim.build_seconds:site.pending=false;site.progress=0.0;site.level+=1
  return site.x
 return NAN
func guidance(x: float) -> Dictionary:
 if not unlocked():return {}
 var choices: Array[Dictionary]=[]
 var side: int=-1 if x<_world.sites.hall else 1
 if "barracks" not in used and is_finite(barracks_x(side)):
  var key: String="sword_station:%d"%side if _orders_enabled else "command_armory" if side>0 else "command_armory:-1"
  choices.append(_hint("barracks",barracks_x(side),key,"tool"))
 if _orders_enabled and "sword_station" not in used and _world.people.any(func(p: Dictionary)->bool:return p.role=="guard") and is_finite(barracks_x(side)):
  choices.append(_hint("sword_station",barracks_x(side),"sword_station:%d"%side,"guard"))
 if "rally" not in used:
  choices.append(_hint("rally",flag_x(side),"rally:%d"%side,"guard"))
 if "rescue_repair" not in used:choices.append(_hint("rescue_repair",ship_x,"rescue_repair","tool"))
 elif waiting>0 and "rescue_recruit" not in used:choices.append(_hint("rescue_recruit",ship_x,"rescue_recruit","recruit"))
 choices.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return absf(a.x-x)<absf(b.x-x))
 return choices[0] if not choices.is_empty() else {}
func _hint(id: String, x: float, key: String, kind: String) -> Dictionary:
 return {"kind":kind,"x":x,"y":430.0,"key":key,"action":"invest","stage":9,"core":true,"mood":"offer","goal":"command.guide."+id,"lesson":"command.guide."+id}
func capture() -> Dictionary:
 var groups: Array[Dictionary]=[]
 for squad: Squad in squads:groups.append(squad.capture())
 return {"squads":groups,"used":used.duplicate(),"repaired":repaired,"waiting":waiting,"last_day":last_day}
func restore(data: Variant, day: int) -> bool:
 if not data is Dictionary or data.size()!=5:return false
 if not data.get("squads") is Array or not data.get("used") is Array or not data.get("repaired") is bool:return false
 for key: String in ["waiting","last_day"]:
  if not data.get(key) is int or data[key]<0:return false
 if data.waiting>rules.passenger_limit or data.last_day>day or data.squads.size()>rules.squad_limit or data.used.size()>Lessons.IDS.size():return false
 if not data.repaired and (data.waiting!=0 or data.last_day!=0):return false
 if data.repaired and data.last_day<1:return false
 var members: Array[int]=[];var learned: Array[String]=[];var groups: Array[Squad]=[]
 for id: Variant in data.used:
  if not id is String or id not in Lessons.IDS or id in learned:return false
  learned.append(id)
 for group: Variant in data.squads:
  if not group is Dictionary or group.size()!=2 or group.get("side") not in [-1,1] or not group.get("members") is Array:return false
  if group.members.is_empty() or group.members.size()>Rules.ROLES.size():return false
  var roster_indices: Array[int]=[];var roles: Array[String]=[]
  for index: Variant in group.members:
   if not index is int or index<0 or index>=_world.people.size() or index in members:return false
   var role: String=_world.people[index].role
   roles.append(role)
   if role not in Rules.ROLES or roles.count(role)>Rules.ROLES.count(role):return false
   members.append(index);roster_indices.append(index)
  groups.append(Squad.new(roster_indices,group.side))
 if not enabled and data!={"squads":[],"used":[],"repaired":false,"waiting":0,"last_day":0}:return false
 squads=groups;used=learned;repaired=data.repaired;waiting=data.waiting;last_day=data.last_day
 return true
