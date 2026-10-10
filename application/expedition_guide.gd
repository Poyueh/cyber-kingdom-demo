extends RefCounted
## Read-only advice for the campaign's real expedition conditions.
const Opening=preload("res://application/campaign_guide.gd")
static func next(sim: RefCounted,x: float,y: float=430.0) -> Dictionary:
 return Opening.funded_hint(sim,x,_next(sim,x,y))

static func _next(sim: RefCounted,x: float,y: float) -> Dictionary:
 if not sim.is_running():return {}
 var pending: Array=[]
 for i in range(sim.mission.rifts.size()):
  var r: Dictionary=sim.mission.rifts[i]
  if r.ordered and not r.sealed:pending.append(i)
 if not pending.is_empty():
  # Escort an assigned worker before queuing another trip for the same engineer.
  var assigned=pending.filter(func(i):return sim.mission.rifts[i].worker>=0)
  if not assigned.is_empty():pending=assigned
  pending.sort_custom(func(a,b):return absf(sim.mission.rifts[a].x-x)<absf(sim.mission.rifts[b].x-x))
  return _ordered(sim,pending[0],x,y)
 if sim.mission.dragon_summoned and not sim.mission.dragon_defeated:
  return _hint("dragon",sim.world.sites.hall,"","move","shield")
 if sim.mission.rifts.all(func(r):return r.sealed):
  var live=sim.raiders.filter(func(r):return r.fighter.is_alive())
  if live.is_empty():return {}
  live.sort_custom(func(a,b):return absf(a.x-x)<absf(b.x-x))
  return _hint("clear_enemies",live[0].x,"","fight","sword")
 if sim.clock.survived==0 and sim.frontier.city_level<2:return {}
 if sim.frontier.city_level==0:return _hint("camp",sim.world.sites.hall,"hall","invest","crystal")
 if sim.clock.is_night or sim.clock.remaining<=30:return _hint("defend",sim.world.sites.hall,"","move","moon")
 if sim.pouch.amount==0:return Opening.funding_hint(sim,x)
 for requirement in sim.rift_requirements():
  match requirement.icon:
   "camp":
    if sim.frontier.city_level==0:return _hint("camp",sim.world.sites.hall,"hall","invest","crystal")
    if sim.mission.core_hp<sim.mission.core_max_hp:return _hint("core",sim.world.sites.hall,"core_charge","invest","heal")
    var advice=_hint("upgrade",sim.world.sites.hall,"hall:%d"%sim.frontier.city_level,"invest","camp")
    advice["requirement_count"]=requirement.value
    return advice
   "survived":return _hint("defend",sim.world.sites.hall,"","wait","moon")
   "hammer":return Opening.job_hint(sim,x,"hammer","workshop",0)
 var visible: Array=[]
 var unseen: Array=[]
 for i in range(sim.mission.rifts.size()):
  var r: Dictionary=sim.mission.rifts[i]
  if r.sealed:continue
  if r.discovered:visible.append(_hint("rift",r.x,"rift:%d"%i,"invest","crystal"))
  else:unseen.append(_hint("explore",sim.frontier.left_boundary+40 if r.side<0 else sim.frontier.right_boundary-40,"","move","rift"))
 var choices: Array=visible if not visible.is_empty() else unseen
 if choices.is_empty():return {}
 choices.sort_custom(func(a,b):return absf(a.x-x)<absf(b.x-x))
 return choices[0]

static func _ordered(sim,index: int,x: float,y: float) -> Dictionary:
 var r: Dictionary=sim.mission.rifts[index]
 if r.worker<0 or sim.world.people[r.worker].role!="engineer":
  var engineers=sim.world.people.filter(func(p):return p.role=="engineer")
  if engineers.is_empty():
   if sim.pouch.amount==0:return Opening.funding_hint(sim,x)
   return Opening.job_hint(sim,x,"hammer","workshop",0)
  engineers.sort_custom(func(a,b):return absf(a.x-x)<absf(b.x-x))
  var worker_index: int=sim.world.people.find(engineers[0])
  if sim.frontier.nodes.any(func(n):return n.worker==worker_index and n.carried):
   return _hint("delivery",engineers[0].x,"","wait","bag")
  return _hint("escort",engineers[0].x,"","follow","rift")
 var state: Dictionary=sim.expedition_status(index,x,y)
 if not state.worker_ready:return _hint("escort",sim.world.people[r.worker].x,"","follow","rift")
 if not state.knight_near:return _hint("join",r.x,"","move","hammer")
 if state.contested or not r.wardens_spawned:return _hint("fight",r.x,"","fight","sword")
 var hint=_hint("seal",r.x,"","stay","hammer")
 hint["seal_progress"]=r.progress/sim.mission.seal_seconds
 return hint

static func _hint(kind: String,x: float,key: String,action: String,detail: String) -> Dictionary:
 return {"kind":kind,"x":x,"y":430.0,"key":key,"action":action,"stage":0,"detail":detail}
