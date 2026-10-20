extends RefCounted
## Persistent trial facts; UI hints never decide whether work or defence happened.
const Guards=preload("res://application/core_guard_orders.gd")
## Dusk never falls while an ordered archer is still walking to the wall.
const ARRIVAL_HOLD_SECONDS: float=3.0
var enabled: bool=false
var trial: bool=false
var forest: bool=false
var contained: bool=false # Demo: whole forest, no voyage; the dragon is the finale.
var stage: int=0 # learning, preparation, first dusk/night, autonomous, second night, complete
var income: int=0
var skipped: bool=false
var orders: Guards=Guards.new()
var checkpoint_index: int=0
var checkpoint: Dictionary={} # One closed snapshot, never containing another checkpoint.
var checkpoint_pending: int=0
var harvest_held: Dictionary={} # Serialization ledger: resident index -> harvested crystal count.
var harvest_drops: Array[int]=[]
var enemy_health: int=0
var enemy_damage: int=0
var wall_damage: int=0
var warning_seconds: float=0.0
var minimum_defenders: int=0
var arrival_radius: float=0.0
var second_gap: float=0.0
var first_count: int=0
var second_count: int=0

func _init(config: Dictionary={}) -> void:
 enabled=config.get("core_loop_version",0) in [1,2,3]
 trial=config.get("core_loop_version",0)==1
 contained=config.get("core_loop_version",0)==3
 forest=int(config.get("planet_id",0))==0
 if enabled and not trial and not forest:stage=5
 if not enabled:return
 enemy_health=int(config.core_enemy_health);enemy_damage=int(config.core_enemy_damage);wall_damage=int(config.core_wall_damage)
 warning_seconds=float(config.core_warning)
 minimum_defenders=int(config.core_min_defenders)
 arrival_radius=float(config.core_arrival_radius)
 second_gap=float(config.core_second_gap)
 first_count=int(config.get("core_first_enemies",config.night_first))
 second_count=int(config.get("core_second_enemies",config.night_first+config.night_growth))

func harvested(index: int, count: int) -> void:
 if enabled and income==0:harvest_held[str(index)]=int(harvest_held.get(str(index),0))+count

func offered(index: int, first_id: int, count: int) -> void:
 if not enabled or income>0:return
 var credit: int=mini(count,int(harvest_held.get(str(index),0)))
 harvest_held.erase(str(index))
 for offset: int in range(credit):harvest_drops.append(first_id+offset+1)

func picked_up(id: int, count: int) -> void:
 if enabled and count>0 and harvest_drops.has(id):
  income+=count;harvest_drops.erase(id)

func observe(sim: RefCounted) -> void:
 if not enabled:return
 orders.clean(sim)
 for key: String in harvest_held.keys():
  var index: int=key.to_int()
  if index>=sim.world.people.size() or sim.world.people[index].role=="wanderer":harvest_held.erase(key)
 harvest_drops=harvest_drops.filter(func(id: int)->bool:return sim.pouch.drops.any(func(d: Dictionary)->bool:return d.id==id))
 if stage==0 and income>0:
  stage=1;checkpoint_pending=1
  harvest_held.clear();harvest_drops.clear()
  sim.effects.append({"kind":"tool_produced","x":sim.world.sites.hunt_tools,"life":1.0})
 if stage==1 and ready(sim) and checkpoint_index==1:
  stage=2;sim.clock.remaining=warning_seconds
 if stage==2 and not sim.clock.is_night and orders.arrived(sim,"wall",arrival_radius)<minimum_defenders and orders.assigned(sim,"wall")>=minimum_defenders:
  sim.clock.remaining=maxf(sim.clock.remaining,ARRIVAL_HOLD_SECONDS)
 if stage==2 and sim.clock.survived==1:
  stage=3;checkpoint_pending=2
 if stage==3 and sim.clock.is_night:stage=4
 if stage==4 and sim.clock.survived>=2:
  stage=5
  if not trial:
   checkpoint.clear();checkpoint_index=0;checkpoint_pending=0
   sim.effects.append({"kind":"tool_produced","x":sim.world.sites.hall,"life":1.0})

func ready(sim: RefCounted) -> bool:
 if income<=0 or sim.frontier.city_level<=0 or not sim.can_wield_sword():return false
 var wall: Dictionary=sim.world.walls.wall
 if wall.level<=0 or wall.hp<=0 or wall.pending:return false
 if orders.assigned(sim,"wall")<minimum_defenders:return false
 return sim.investments.is_empty() and not sim.effects.any(func(e: Dictionary)->bool:return e.kind=="camp_ignition")

func site_allowed(site: String, sim: RefCounted) -> bool:
 if not enabled or (not trial and stage>=3):return true
 if site=="hall":return true
 if site=="workshop":return true
 if income<=0:return false
 if site in ["hunt_tools","wall","wall_left","beacon"]:return true
 return sim.buildings.has(site) and sim.buildings[site].kind=="tower"

func filter_choices(sim: RefCounted, choices: Array[Dictionary]) -> Array[Dictionary]:
 if not enabled or (not trial and stage>=3):return choices
 var result: Array[Dictionary]=[]
 for choice: Dictionary in choices:
  if choice.id not in ["guard_station","hall","core_charge","recruit","workshop","hunt_tools","mark","chest","trail_cache","wall","wall_left","tower"]:continue
  if choice.id in ["hunt_tools","wall","wall_left","tower"] and income<=0:continue
  if choice.id=="hall" and sim.frontier.city_level>0:continue
  if choice.id=="mark" and not sim.world.people.any(func(p: Dictionary)->bool:return p.role=="engineer"):
   choice.enabled=false;choice.reason="core.need_engineer"
  result.append(choice)
 return result

func hint(sim: RefCounted) -> String:
 if stage==5:return "core.complete" if trial else ""
 if stage==4:return "core.second_night"
 if stage==3:return "core.autonomy"
 if stage==2:return "core.first_night" if sim.clock.is_night else "core.first_warning"
 if sim.frontier.city_level==0:return "core.light"
 if not sim.world.people.any(func(p: Dictionary)->bool:return p.role!="wanderer"):return "core.recruit"
 if not sim.world.people.any(func(p: Dictionary)->bool:return p.role=="engineer"):return "core.hammer"
 if income==0:
  if not harvest_held.is_empty() or not harvest_drops.is_empty():return "core.collect"
  if sim.frontier.nodes.any(func(n: RefCounted)->bool:return n.marked and not n.delivered):return "core.working"
  return "core.harvest"
 if not sim.world.people.any(func(p: Dictionary)->bool:return p.role=="hunter"):return "core.bow"
 if sim.world.walls.wall.level==0 or sim.world.walls.wall.pending:return "core.wall"
 return "core.assign"

func capture() -> Dictionary:
 return {"stage":stage,"income":income,"skipped":skipped,"orders":orders.targets.duplicate(),"checkpoint_index":checkpoint_index,"checkpoint":checkpoint.duplicate(true),"checkpoint_pending":checkpoint_pending,"harvest_held":harvest_held.duplicate(),"harvest_drops":harvest_drops.duplicate()}

func restore(data: Variant) -> bool:
 if not data is Dictionary or data.size()!=9:return false
 for key: String in ["stage","income","checkpoint_index","checkpoint_pending"]:
  if not data.get(key) is int:return false
 if data.stage<0 or data.stage>5 or data.income<0 or data.income>30:return false
 if data.checkpoint_index not in [0,1,2] or data.checkpoint_pending not in [0,1,2]:return false
 if not data.get("skipped") is bool or not data.get("checkpoint") is Dictionary:return false
 if not data.get("harvest_held") is Dictionary or data.harvest_held.size()>40:return false
 if not data.get("harvest_drops") is Array or data.harvest_drops.size()>64:return false
 if not data.get("orders") is Array or data.orders.size()>40:return false
 for target: Variant in data.orders:
  if not target is String or target not in ["","wall","wall_left","beacon","core_tower_right"]:return false
 for key: Variant in data.harvest_held:
  if not key is String or not key.is_valid_int() or int(key)<0 or int(key)>=40:return false
  if not data.harvest_held[key] is int or data.harvest_held[key]<0 or data.harvest_held[key]>12:return false
 for id: Variant in data.harvest_drops:
  if not id is int or id<1:return false
 if enabled:
  if data.stage==0 and (data.income!=0 or data.checkpoint_index!=0 or data.checkpoint_pending!=0):return false
  if data.checkpoint_pending==1 and (data.stage!=1 or data.checkpoint_index!=0):return false
  if data.checkpoint_pending==2 and (data.stage!=3 or data.checkpoint_index!=1):return false
  if data.stage==2 and data.checkpoint_index!=1:return false
  if data.stage>=4 and (trial or data.stage<5) and data.checkpoint_index!=2:return false
  if not trial and not forest and data.stage!=5:return false
  if data.orders.count("beacon")>3 or data.orders.count("core_tower_right")>3:return false
 if not enabled and data!={"stage":0,"income":0,"skipped":false,"orders":[],"checkpoint_index":0,"checkpoint":{},"checkpoint_pending":0,"harvest_held":{},"harvest_drops":[]}:return false
 stage=data.stage;income=data.income;skipped=data.skipped
 orders.targets.assign(data.orders)
 checkpoint_index=data.checkpoint_index;checkpoint_pending=data.checkpoint_pending;checkpoint=data.checkpoint.duplicate(true)
 harvest_held=data.harvest_held.duplicate();harvest_drops.assign(data.harvest_drops)
 return true
