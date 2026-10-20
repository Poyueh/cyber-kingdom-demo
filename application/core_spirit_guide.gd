extends RefCounted
## Read-only UI projection: targets are actual jobs, carriers and completed defences.
const Opening=preload("res://application/campaign_guide.gd")
static func next(sim: RefCounted, x: float) -> Dictionary:
 if not sim.is_running() or sim.core_loop.skipped or sim.core_loop.stage>=5:return {}
 var lesson: String=sim.core_loop.hint(sim)
 var hint: Dictionary={}
 match lesson:
  "core.light":hint=make("camp",sim.world.sites.hall,"hall","invest")
  "core.recruit":hint=Opening.job_hint(sim,x,"hammer","workshop",0)
  "core.hammer":hint=Opening.job_hint(sim,x,"hammer","workshop",0)
  "core.bow":hint=Opening.job_hint(sim,x,"bow","hunt_tools",1)
  "core.harvest":hint=tree(sim,x)
  "core.working":hint=work(sim,x)
  "core.collect":hint=income(sim,x)
  "core.wall":
   var wall: Dictionary=sim.world.walls.wall
   hint=make("wall",sim.world.sites.wall,"wall:0:false","wait" if wall.pending else "invest")
  "core.assign":hint=make("guard",sim.core_loop.orders.station_x(sim),"guard_station","invest")
  "core.first_warning","core.first_night","core.second_night":
   var side: String="wall_left" if lesson=="core.second_night" and sim.raid_pressure().left>sim.raid_pressure().right else "wall"
   hint=make("defend",sim.world.sites[side],"","wait")
  "core.autonomy":hint=make("rest",x,"","wait")
 if hint.is_empty():return {}
 if hint.kind=="guard" and not sim.core_loop.orders.targets.has("wall") and sim.pouch.amount<sim.core_loop.orders.rules.assignment_cost:
  var source: Dictionary=Opening.funding_hint(sim,x)
  if not source.is_empty():hint=source
 hint=Opening.funded_hint(sim,x,hint)
 if hint.is_empty():return {}
 var mood: String="lead"
 if hint.kind in ["work_income","tool","hunter","wall"] and hint.action=="wait":mood="work"
 if hint.kind in ["collect","resident_income"]:mood="receive"
 if hint.kind in ["defend","guard"]:mood="guard"
 if hint.kind=="rest":mood="rest"
 hint["core"]=true;hint["mood"]=mood;hint["lesson"]=lesson
 var goal: String="spirit.core."+str(hint.kind)
 if mood=="work":
  goal="spirit.core.wait_tool" if hint.kind in ["tool","hunter"] else "spirit.core.wait_wall" if hint.kind=="wall" else "spirit.core.working"
 if hint.kind=="guard":
  goal="spirit.core.arriving" if sim.core_loop.orders.targets.has("wall") else "spirit.core.assign"
 hint["goal"]=goal
 return hint

static func make(kind: String, x: float, key: String, action: String) -> Dictionary:
 return {"kind":kind,"x":x,"y":430.0,"key":key,"action":action,"stage":0}

static func tree(sim: RefCounted, x: float) -> Dictionary:
 var choices: Array[Dictionary]=[]
 for i: int in range(sim.frontier.nodes.size()):
  var node: RefCounted=sim.frontier.nodes[i]
  if node.kind!="tree" or node.marked or node.collected:continue
  if not sim.work_area.contains(node.x) or not sim.frontier.regions[node.region].discovered:continue
  var hint: Dictionary=make("harvest",node.x,"node:%d"%i,"invest")
  if sim.context_for_key(node.x,hint.key).enabled:choices.append(hint)
 return Opening._nearest(choices,x) if not choices.is_empty() else Opening.funding_hint(sim,x)

static func work(sim: RefCounted, x: float) -> Dictionary:
 var choices: Array[Dictionary]=[]
 for node: RefCounted in sim.frontier.nodes:
  if node.marked and not node.delivered:choices.append(make("work_income",node.x,"","wait"))
 return Opening._nearest(choices,x) if not choices.is_empty() else income(sim,x)

static func income(sim: RefCounted, x: float) -> Dictionary:
 var choices: Array[Dictionary]=[]
 for key: String in sim.core_loop.harvest_held:
  var person: Dictionary=sim.world.people[key.to_int()]
  if person.role!="wanderer" and int(person.get("crystals",0))>0 and not sim.life.threatened(person,sim.raiders):
   choices.append(make("resident_income",person.x,"","move"))
 for drop: Dictionary in sim.pouch.drops:
  if sim.core_loop.harvest_drops.has(drop.id) and drop.amount>0:choices.append(make("collect",drop.x,"","move"))
 return Opening._nearest(choices,x) if not choices.is_empty() else Opening.funding_hint(sim,x)
