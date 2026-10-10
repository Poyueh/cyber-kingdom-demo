extends RefCounted
static func rocket_x(sim: RefCounted) -> float:return sim.world.sites.hall-760.0
static func core_x(sim: RefCounted) -> float:return sim.world.sites.hall-215.0
static func resolve(sim: RefCounted) -> void:
 sim.mission.resolve(sim.hero.is_alive(),sim.raiders.is_empty())
 if not sim.planet.enabled:return
 if sim.mission.outcome=="victory" and not sim.planet.completed:
  sim.planet.cleared=true;sim.mission.outcome="active"
static func candidates(sim: RefCounted, x: float, y: float) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if not sim.planet.enabled or absf(y-430)>42:return result
 if sim.planet.cleared and not sim.planet.core_claimed and absf(x-core_x(sim))<73:
  result.append(sim._choice("dragon_core",core_x(sim),"planet.claim_core",0))
 if absf(x-rocket_x(sim))>=73 or not sim.planet.reactor:return result
 if sim.planet.rocket_ready:
  result.append(sim._choice("star_map",rocket_x(sim),"planet.launch",0,sim.raiders.is_empty() and sim.can_wield_sword(),"planet.unsafe"))
 elif not sim.planet.rocket_pending:
  result.append(sim._choice("rocket",rocket_x(sim),"planet.rebuild" if sim.planet.wrecked else "planet.build",sim.planet.cost()))
 return result
static func execute(sim: RefCounted, id: String) -> void:
 match id:
  "dragon_core":
   if sim.planet.claim_core():sim.effects.append({"kind":"chest_burst","x":core_x(sim),"y":380.0,"life":0.8})
  "rocket":sim.planet.rocket_pending=true;sim.planet.work=0.0
  "star_map":sim.planet.launch_requested=true
static func engineer(sim: RefCounted, index: int, seconds: float) -> float:
 if not sim.planet.enabled or not sim.planet.rocket_pending:return NAN
 var workers: Array=sim.world.people.filter(func(p: Dictionary)->bool:return p.role=="engineer")
 var person: Dictionary=sim.world.people[index]
 if workers.find(person)>=2:return NAN
 var at: float=rocket_x(sim)
 person.work_state="work" if absf(person.x-at)<28 else "walk"
 if absf(person.x-at)<28:sim.planet.work_on(sim.modules.construction_seconds(person,seconds,roundi(sim.workforce.elapsed*30)))
 return at

static func guidance(sim: RefCounted) -> Dictionary:
 if not sim.planet.enabled or not sim.planet.cleared:return {}
 var hint: Dictionary={"kind":"chest","x":core_x(sim),"y":430.0,"key":"dragon_core","action":"open","stage":8,"goal":"planet.claim_info"}
 if not sim.planet.core_claimed:return hint
 hint.merge({"kind":"tool","x":rocket_x(sim),"key":"rocket","action":"invest","goal":"planet.rocket_info"},true)
 if sim.planet.rocket_pending:hint.merge({"action":"wait","goal":"planet.worker_info"},true)
 if sim.planet.rocket_ready:hint.merge({"kind":"explore","key":"star_map","action":"open","goal":"planet.launch_info"},true)
 return hint
