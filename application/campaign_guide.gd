extends RefCounted
## Stateless first-day advice. Reads the current run; never spends or reveals anything.
static func next(sim, x: float) -> Dictionary:
 if not sim.is_running() or sim.clock.survived>0 or sim.frontier.city_level>=2:return {}
 if sim.clock.is_night or sim.clock.remaining<=30:
  return _hint("defend",sim.world.sites.hall,"","move",7)
 if sim.pouch.amount==0:return funding_hint(sim,x)
 if sim.frontier.city_level==0:return _hint("camp",sim.world.sites.hall,"hall","invest",1)
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

static func funding_hint(sim,x: float) -> Dictionary:
 var options: Array=[]
 for drop in sim.pouch.drops:
  if drop.amount>0 and not drop.offering and drop.age>=drop.grace:options.append(_hint("collect",drop.x,"","move",0))
 for i in range(sim.frontier.nodes.size()):
  var node=sim.frontier.nodes[i]
  if node.kind=="cache" and not node.collected and sim.frontier.regions[node.region].discovered:
   var hint=_hint("chest",node.x,"node:%d"%i,"open",0)
   hint["y"]=node.y
   options.append(hint)

 return _nearest(options,x) if not options.is_empty() else _explore(sim,x,0)

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
