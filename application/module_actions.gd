extends RefCounted
## Bounded actions on the existing battle and workforce. Visuals observe emitted events.
const Catalog=preload("res://domain/module_specs.gd")
static func execute(sim: RefCounted, spec: Catalog.Spec, x: float, now: int) -> bool:
 match spec.id:
  "magnet":return sim.pouch.pull_existing(spec.targets,x,430,spec.reach)>0
  "command","workshop":return _support(sim,spec,x,now)
  "capacitor":
   if sim.hero.stamina>=spec.threshold or sim.modules.charge_ticks>0:return false
   sim.modules.charge_ticks=spec.duration;sim.modules.charge_last_tick=now
   return true
  _:return _attack(sim,spec,x,now)
static func _attack(sim: RefCounted, spec: Catalog.Spec, x: float, now: int) -> bool:
 var targets: Array[Dictionary]=[]
 for enemy: Dictionary in sim.raiders:
  var distance: float=enemy.x-x
  if not enemy.fighter.is_alive() or absf(distance)>spec.reach:continue
  if spec.id!="arc" and distance*sim.hero.facing<0:continue
  targets.append(enemy)
 targets.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return absf(a.x-x)<absf(b.x-x))
 for enemy: Dictionary in targets.slice(0,spec.targets):
  if not enemy.fighter.take_damage(spec.damage):continue
  match spec.id:
   "frost":
    enemy["module_chill_until"]=now+(spec.boss_duration if enemy.get("kind","")=="dragon" else spec.duration)
   "gravity":
    if enemy.get("kind","") not in ["dragon","warden"]:
     var anchor: float=x+sim.hero.facing*spec.reach*0.5
     sim.move_raider(enemy,move_toward(enemy.x,anchor,spec.power))
   _:
    sim.move_raider(enemy,clampf(enemy.x+signf(enemy.x-x)*24,sim.frontier.left_boundary,sim.frontier.right_boundary))
 return true
static func _support(sim: RefCounted, spec: Catalog.Spec, x: float, now: int) -> bool:
 var role: String="hunter" if spec.id=="command" else "engineer"
 if role=="engineer" and not _paid_work(sim):return false
 var candidates: Array[Dictionary]=[]
 for person: Dictionary in sim.world.people:
  if person.role!=role or person.hurt>0 or absf(person.x-x)>spec.reach:continue
  if role=="engineer" and sim.life.threatened(person,sim.raiders):continue
  candidates.append(person)
 candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return absf(a.x-x)<absf(b.x-x))
 var selected: int=mini(spec.targets,candidates.size())
 for i: int in range(selected):
  candidates[i]["module_"+spec.id+"_until"]=now+spec.duration
  sim.effects.append({"kind":"module_link","module":spec.id,"x":x,"to":candidates[i].x,"life":0.6})
 return selected>0
static func _paid_work(sim: RefCounted) -> bool:
 if sim.planet.rocket_pending:return true
 for wall: Dictionary in sim.world.walls.values():
  if wall.pending:return true
 for site: Dictionary in sim.buildings.values():
  if site.pending:return true
 for region: Dictionary in sim.frontier.regions:
  if region.outpost_pending:return true
 return false
