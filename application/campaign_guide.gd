extends RefCounted
## Stateless first-day advice. Reads the current run; never spends or reveals anything.
static func next(sim: RefCounted, x: float) -> Dictionary:
 return funded_hint(sim,x,_next(sim,x))

static func _next(sim: RefCounted, x: float) -> Dictionary:
 if not sim.is_running() or sim.clock.survived>0 or sim.frontier.city_level>=2:return {}
 if sim.frontier.city_level==0:return _hint("camp",sim.world.sites.hall,"hall","invest",1)
 if sim.clock.is_night or sim.clock.remaining<=30:
  return _hint("defend",sim.world.sites.hall,"","move",7)
 if sim.pouch.amount==0:return funding_hint(sim,x)
 var engineers=sim.world.people.filter(func(p):return p.role=="engineer")
 if engineers.is_empty():return job_hint(sim,x,"hammer","workshop",2)
 var harvesting: bool=sim.frontier.nodes.any(func(n):return n.kind=="tree" and (n.marked or n.collected))
 if not harvesting:
  var trees: Array=[]
  for i in range(sim.frontier.nodes.size()):
   var node=sim.frontier.nodes[i]
   if sim.life.enabled and not sim.work_area.contains(node.x):continue
   if node.kind=="tree" and not node.collected and sim.frontier.regions[node.region].discovered and not sim.ecology.clearing_last_tree(node):
    trees.append(_hint("harvest",node.x,"node:%d"%i,"invest",4))
  return _nearest(trees,x) if not trees.is_empty() else _explore(sim,x,4)
 var defenders=sim.world.people.filter(func(p):return p.role in ["hunter","guard"])
 if defenders.is_empty():return job_hint(sim,x,"bow","hunt_tools",5)
 var walls: Array=[]
 for key in ["wall","wall_left"]:
  var wall: Dictionary=sim.world.walls[key]
  if wall.level==0 and not wall.pending:walls.append(_hint("wall",sim.world.sites[key],key,"invest",6))
 if not walls.is_empty():return _nearest(walls,x)
 return {}

static func job_hint(sim,x: float,tool: String,site: String,stage: int) -> Dictionary:
 var citizens=sim.world.people.filter(func(p):return p.role=="citizen")
 if citizens.is_empty():
  var people: Array=[]
  for i in range(sim.world.people.size()):
   var person: Dictionary=sim.world.people[i]
   if person.role=="wanderer" and person.hurt<=0 and sim.person_visible(person):
    people.append(_hint("recruit",person.x,"recruit:%d"%i,"invest",stage))
  return _nearest(people,x) if not people.is_empty() else _explore(sim,x,stage)
 if tool=="bow" and sim.world.tools.blade>0:
  return _hint("hunter",sim.world.sites.hunt_tools,"hunt_tools","wait",stage)
 var hint=_hint("tool" if tool=="hammer" else "hunter",sim.world.sites[site],site,"invest",stage+1 if stage==2 else stage)
 if sim.world.tools[tool]>0:hint.action="wait"
 return hint

static func funded_hint(sim: RefCounted, x: float, hint: Dictionary) -> Dictionary:
 if hint.get("action","")!="invest" or str(hint.get("key","")).is_empty():return hint
 var choice: Dictionary=sim.context_for_key(float(hint.x),str(hint.key))
 if choice.id.is_empty():return hint
 var remaining: int=maxi(0,int(choice.cost)-int(choice.paid))
 return funding_hint(sim,x) if remaining>sim.pouch.amount else hint

static func funding_hint(sim: RefCounted, x: float) -> Dictionary:
 var options: Array[Dictionary]=[]
 if sim.life.enabled:
  for person: Dictionary in sim.world.people:
   if person.role=="wanderer" or int(person.get("crystals",0))<=0:continue
   if person.hurt>0 or not sim.person_visible(person) or sim.life.threatened(person,sim.raiders):continue
   options.append(_hint("resident_income",person.x,"","move",0))
 if sim.merchant.enabled and sim.merchant.phase in [sim.merchant.Phase.APPROACHING,sim.merchant.Phase.READY]:
  options.append(_hint("merchant",sim.merchant.x,"","move",0))
 for drop in sim.pouch.drops:
  if drop.amount>0 and not drop.offering:options.append(_hint("collect",drop.x,"","move",0))
 for i in range(sim.frontier.nodes.size()):
  var node=sim.frontier.nodes[i]
  if node.kind=="cache" and not node.collected and sim.frontier.regions[node.region].discovered:
   var hint=_hint("chest",node.x,"node:%d"%i,"open",0)
   hint["y"]=node.y
   options.append(hint)

 for i: int in range(sim.trails.sites.size()):
  if sim.trails.available(i):
   var hint: Dictionary=_hint("chest",sim.trails.sites[i].x,"trail:%d"%i,"open",0)
   hint["goal"]="trail.claim"
   options.append(hint)

 if not options.is_empty():return _nearest(options,x)
 var pending: Dictionary=_pending_income(sim,x)
 return pending if not pending.is_empty() else _explore(sim,x,0)

static func _pending_income(sim: RefCounted, x: float) -> Dictionary:
 var options: Array[Dictionary]=[]
 if sim.life.enabled:
  for node: RefCounted in sim.frontier.nodes:
   if not node.marked or node.delivered or node.worker<0:continue
   if not sim.frontier.regions[node.region].discovered:continue
   var worker: Dictionary=sim.world.people[node.worker]
   if worker.role!="engineer" or worker.hurt>0 or sim.life.threatened(worker,sim.raiders):continue
   options.append(_hint("work_income",node.x,"","wait",0))
 if sim.merchant.enabled:
  if sim.merchant.phase==sim.merchant.Phase.RETURNING:
   options.append(_hint("merchant_return",sim.merchant.home_x,"","wait",0))
  elif sim.merchant.phase in [sim.merchant.Phase.OUTBOUND,sim.merchant.Phase.AWAY]:
   options.append(_hint("merchant_wait",sim.merchant.home_x,"","wait",0))
 return _nearest(options,x) if not options.is_empty() else {}

static func _explore(sim,x: float,stage: int) -> Dictionary:
 var regions: Array=[]
 for region in sim.frontier.regions:
  if not region.discovered:
   regions.append(_hint("explore",clampf(x,region.x+32,region.x+region.width-32),"","move",stage))
 return _nearest(regions,x) if not regions.is_empty() else {}

static func _nearest(options: Array,x: float) -> Dictionary:
 var result: Dictionary=options[0]
 for item in options:
  if absf(item.x-x)<absf(result.x-x):result=item
 return result

static func _hint(kind: String,x: float,key: String,action: String,stage: int) -> Dictionary:
 return {"kind":kind,"x":x,"y":430.0,"key":key,"action":action,"stage":stage}
