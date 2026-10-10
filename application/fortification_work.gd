extends RefCounted
## Paid construction shares engineer movement. At night only protected routes qualify.
static func target(sim,index: int,seconds: float,night: bool) -> float:
 var person: Dictionary=sim.world.people[index]
 var jobs: Array[Dictionary]=[]
 if night:
  for id in sim.world.walls:
   if sim.world.walls[id].pending:jobs.append({"kind":"wall","id":id,"x":sim.world.sites[id]})
  for i in range(sim.frontier.regions.size()):
   var region=sim.frontier.regions[i]
   if region.outpost_pending:jobs.append({"kind":"outpost","index":i,"x":region.outpost_x})
 for id in sim.buildings:
  var site: Dictionary=sim.buildings[id]
  if site.pending:jobs.append({"kind":"building","id":id,"x":site.x})
 var choice: Dictionary={};var nearest:=INF
 var bounds: Vector2=sim.defenses.work_bounds()
 for job in jobs:
  var at: float=job.x-(12*signf(job.x-sim.world.sites.hall) if job.kind=="wall" else 0)
  if night:
   if minf(at,person.x)<bounds.x or maxf(at,person.x)>bounds.y:continue
   if sim.raiders.any(func(e):return e.fighter.is_alive() and e.x>minf(at,person.x)-90 and e.x<maxf(at,person.x)+90):continue
  if absf(at-person.x)<nearest:choice=job;choice["target"]=at;nearest=absf(at-person.x)
 if choice.is_empty():return NAN
 person["sheltering"]=false;person["work_state"]="walk"
 if nearest<=8:
  person.work_state="work"
  var work: float=sim.modules.construction_seconds(person,seconds,roundi(sim.workforce.elapsed*30))
  if choice.kind=="wall":sim.world.work_wall(index,work,choice.id)
  elif choice.kind=="outpost":sim.frontier.work_outpost(choice.index,work)
  else:
   var site: Dictionary=sim.buildings[choice.id]
   site.progress+=work
   if site.progress>=sim.build_seconds:
    site.pending=false;site.progress=0.0;site.level+=1
    sim.effects.append({"kind":"construction_done","x":site.x,"life":0.5})
    if choice.id=="beacon":sim.built.beacon=true
 return choice.target
