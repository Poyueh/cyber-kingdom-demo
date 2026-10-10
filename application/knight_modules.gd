extends RefCounted
## One active socket; the catalogue and owned discoveries form a per-journey collection.
const TickClock=preload("res://domain/time/tick_clock.gd")
const Catalog=preload("res://domain/module_specs.gd")
const Conditions=preload("res://domain/module_conditions.gd")
const Actions=preload("res://application/module_actions.gd")
const Buff=preload("res://domain/stats/modifier.gd")
const IDS: Array[String]=Catalog.IDS
const DEFAULT_SWAP_COST: int=8
var swap_cost: int=DEFAULT_SWAP_COST
class Relic extends RefCounted:
 var id: String
 var x: float
 var region: int
var relics: Array[Relic]=[]
var specs: Array[Catalog.Spec]=[]
var found: Array[String]=[]
var stored: Array[String]=[]
var equipped: String=""
var ready_tick: int=0
var charge_ticks: int=0
var charge_last_tick: int=0
func _init(frontier: RefCounted, config: Dictionary={}) -> void:
 swap_cost=clampi(config.get("prices",{}).get("module_swap",DEFAULT_SWAP_COST),1,30)
 specs=Catalog.build(config)
 for spec: Catalog.Spec in specs:
  if config.has("module_catalog_version") and spec.planet!=int(config.get("planet_id",0)):continue
  var selected: RefCounted=null
  for node: RefCounted in frontier.nodes:
   if node.kind!="cache" or (node.x<0)!=(spec.side<0):continue
   if selected==null or absf(node.x)>absf(selected.x):selected=node
  if selected==null:continue
  var relic: Relic=Relic.new()
  relic.id=spec.id;relic.x=selected.x+44;relic.region=selected.region
  relics.append(relic)
func spec_for(id: String) -> Catalog.Spec:
 for spec: Catalog.Spec in specs:
  if spec.id==id:return spec
 return null
func observe(sim: RefCounted, x: float, y: float) -> void:
 var now: int=roundi(sim.workforce.elapsed*TickClock.TICKS_PER_SECOND)
 if ready_tick>0 and now>=ready_tick:
  ready_tick=0
  if not equipped.is_empty():sim.effects.append({"kind":"module_ready","module":equipped,"x":x,"life":0.9})
 if absf(y-430)>35:return
 for relic: Relic in relics:
  if found.has(relic.id) or not sim.frontier.regions[relic.region].discovered or absf(x-relic.x)>38:continue
  if not sim.trials.unlocked(relic.id):continue
  found.append(relic.id);stored.append(relic.id);equipped=relic.id
  sim.effects.append({"kind":"module_pickup","module":relic.id,"x":x,"life":5.0})
  if specs.size()>2 and found.size() in [1,4,8]:sim.effects.append({"kind":"module_milestone","module":relic.id,"count":found.size(),"x":x,"life":5.0})
 if sim.frontier.city_level<=0 or absf(x-sim.world.sites.drill)>=73:return
 for id: String in found:
  if stored.has(id):continue
  stored.append(id)
  sim.effects.append({"kind":"module_stored","module":id,"x":x,"life":3.0})
func equip(id: String) -> bool:
 if not stored.has(id) or equipped==id:return false
 equipped=id
 return true
func activate(sim: RefCounted, x: float) -> bool:
 var now: int=roundi(sim.workforce.elapsed*TickClock.TICKS_PER_SECOND)
 var spec: Catalog.Spec=spec_for(equipped)
 if spec==null or now<ready_tick or sim.hero.stamina<spec.cost:return false
 if not Actions.execute(sim,spec,x,now):return false
 sim.hero.stamina-=spec.cost;ready_tick=now+spec.cooldown
 sim.effects.append({"kind":"module_"+equipped,"x":x,"direction":sim.hero.facing,"life":0.8 if spec.id not in ["arc","lance"] else 0.5})
 return true
func advance_effects(sim: RefCounted) -> void:
 var now: int=roundi(sim.workforce.elapsed*TickClock.TICKS_PER_SECOND)
 for person: Dictionary in sim.world.people:
  for key: String in ["module_command_until","module_workshop_until"]:
   var role: String="hunter" if key=="module_command_until" else "engineer"
   if person.has(key) and (person[key]<=now or person.role!=role):person.erase(key)
 for enemy: Dictionary in sim.raiders:
  if enemy.has("module_chill_until") and enemy.module_chill_until<=now:enemy.erase("module_chill_until")
 if charge_ticks<=0:return
 var ticks: int=mini(charge_ticks,maxi(0,now-charge_last_tick))
 var spec: Catalog.Spec=spec_for("capacitor")
 sim.hero.stamina=minf(sim.hero.stats.max_stamina,sim.hero.stamina+spec.power*float(ticks)/spec.duration)
 charge_ticks-=ticks;charge_last_tick=now if charge_ticks>0 else 0
func movement_speed(enemy: Dictionary, speed: float, now: int) -> float:
 if not enemy.has("module_chill_until"):return speed
 var spec: Catalog.Spec=spec_for("frost")
 return Conditions.adjusted(speed,spec.boss_power if enemy.get("kind","")=="dragon" else spec.power,Buff.Op.MULT,&"module:frost",enemy.module_chill_until,now)
func arrow_damage(person: Dictionary, damage: int, now: int) -> int:
 if not person.has("module_command_until") or person.role!="hunter":return damage
 return roundi(Conditions.adjusted(damage,spec_for("command").power,Buff.Op.ADD,&"module:command",person.module_command_until,now))
func construction_seconds(person: Dictionary, seconds: float, now: int) -> float:
 if not person.has("module_workshop_until") or person.role!="engineer":return seconds
 return Conditions.adjusted(seconds,spec_for("workshop").power,Buff.Op.MULT,&"module:workshop",person.module_workshop_until,now)
func capture() -> Dictionary:
 return {"found":found.duplicate(),"stored":stored.duplicate(),"equipped":equipped,"ready_tick":ready_tick,"charge_ticks":charge_ticks,"charge_last_tick":charge_last_tick}
func restore(data: Variant, elapsed: float) -> bool:
 if not data is Dictionary or data.size()!=6:return false
 if not data.get("found") is Array or not data.get("stored") is Array or not data.get("equipped") is String:return false
 for key: String in ["ready_tick","charge_ticks","charge_last_tick"]:
  if not data.get(key) is int or data[key]<0:return false
 for key: String in ["found","stored"]:
  var seen: Array[String]=[]
  for id: Variant in data[key]:
   if not id is String or spec_for(id)==null or seen.has(id):return false
   seen.append(id)
 if not data.stored.all(func(id: String)->bool:return data.found.has(id)):return false
 if not data.equipped.is_empty() and not data.stored.has(data.equipped):return false
 var now: int=roundi(elapsed*TickClock.TICKS_PER_SECOND)
 var limit: int=0
 for spec: Catalog.Spec in specs:limit=maxi(limit,spec.cooldown)
 if data.ready_tick>now+limit+1:return false
 if data.charge_ticks>0:
  var spec: Catalog.Spec=spec_for("capacitor")
  if spec==null or not data.found.has("capacitor") or data.charge_ticks>spec.duration or data.charge_last_tick!=now or data.ready_tick<now+data.charge_ticks:return false
 elif data.charge_last_tick!=0:return false
 found.assign(data.found);stored.assign(data.stored);equipped=data.equipped;ready_tick=data.ready_tick
 charge_ticks=data.charge_ticks;charge_last_tick=data.charge_last_tick
 return true
