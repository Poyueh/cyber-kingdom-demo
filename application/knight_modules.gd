extends RefCounted
## Exploration inventory and special actions; no rendering/input or wall clock.
const TickClock=preload("res://domain/time/tick_clock.gd")
const IDS: Array[String]=["arc","lance"]
class Spec extends RefCounted:
 var id: String
 var damage: int
 var cost: float
 var reach: float
 var cooldown: int
class Relic extends RefCounted:
 var id: String
 var x: float
 var region: int
var relics: Array[Relic]=[]
var specs: Array[Spec]=[]
var found: Array[String]=[]
var stored: Array[String]=[]
var equipped: String=""
var ready_tick: int=0

func _init(frontier: RefCounted, config: Dictionary={}) -> void:
 for id in IDS:
  var spec: Spec=Spec.new();spec.id=id
  var prefix: String="module_"+id+"_"
  spec.damage=clampi(config.get(prefix+"damage",32 if id=="arc" else 55),1,150)
  spec.cost=clampf(config.get(prefix+"cost",20.0 if id=="arc" else 25.0),1,60)
  spec.reach=clampf(config.get(prefix+"range",150.0 if id=="arc" else 300.0),60,600)
  spec.cooldown=TickClock.ticks_for(clampf(config.get(prefix+"cooldown",6.0 if id=="arc" else 8.0),1,30))
  specs.append(spec)
 for index in range(2):
  var selected: RefCounted=null
  for node in frontier.nodes:
   if node.kind!="cache" or (node.x<0)!=(index==0):continue
   if selected==null or absf(node.x)>absf(selected.x):selected=node
  if selected==null:continue
  var relic: Relic=Relic.new()
  relic.id=IDS[index];relic.x=selected.x+44;relic.region=selected.region
  relics.append(relic)

func observe(sim: RefCounted, x: float, y: float) -> void:
 if absf(y-430)>35:return
 for relic in relics:
  if found.has(relic.id) or not sim.frontier.regions[relic.region].discovered or absf(x-relic.x)>38:continue
  found.append(relic.id)
  sim.effects.append({"kind":"module_pickup","module":relic.id,"x":x,"life":3.0})
 if sim.frontier.city_level<=0 or absf(x-sim.world.sites.drill)>=73:return
 for id in found:
  if stored.has(id):continue
  stored.append(id)
  sim.effects.append({"kind":"module_stored","module":id,"x":x,"life":3.0})

func equip(id: String) -> bool:
 if not stored.has(id):return false
 equipped=id
 return true

func activate(sim: RefCounted, x: float) -> bool:
 var now: int=roundi(sim.workforce.elapsed*TickClock.TICKS_PER_SECOND)
 if equipped.is_empty():return false
 var spec: Spec=specs[IDS.find(equipped)]
 if now<ready_tick or sim.hero.stamina<spec.cost:return false
 sim.hero.stamina-=spec.cost
 ready_tick=now+spec.cooldown
 for enemy in sim.raiders:
  var distance: float=enemy.x-x
  if absf(distance)>spec.reach:continue
  if equipped=="lance" and distance*sim.hero.facing<0:continue
  if enemy.fighter.take_damage(spec.damage):
   enemy.x=clampf(enemy.x+signf(distance)*24,sim.frontier.left_boundary,sim.frontier.right_boundary)
 sim.effects.append({"kind":"module_"+equipped,"x":x,"direction":sim.hero.facing,"life":0.5})
 return true

func capture() -> Dictionary:
 return {"found":found.duplicate(),"stored":stored.duplicate(),"equipped":equipped,"ready_tick":ready_tick}

func restore(data: Variant, elapsed: float) -> bool:
 if not data is Dictionary or data.size()!=4:return false
 if not data.get("found") is Array or not data.get("stored") is Array or not data.get("equipped") is String or not data.get("ready_tick") is int:return false
 for key in ["found","stored"]:
  var seen: Array[String]=[]
  for id in data[key]:
   if not id is String or not IDS.has(id) or seen.has(id):return false
   seen.append(id)
 if not data.stored.all(func(id: String):return data.found.has(id)):return false
 if not data.equipped.is_empty() and not data.stored.has(data.equipped):return false
 if data.ready_tick<0 or data.ready_tick>roundi(elapsed*TickClock.TICKS_PER_SECOND)+maxi(specs[0].cooldown,specs[1].cooldown)+1:return false
 found.assign(data.found);stored.assign(data.stored);equipped=data.equipped;ready_tick=data.ready_tick
 return true
