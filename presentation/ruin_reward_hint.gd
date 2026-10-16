extends RefCounted
## Local, read-only reward explanation; no new quest state or saved flags.
const Style=preload("res://presentation/module_style.gd")
const Known=preload("res://application/ruin_interactions.gd")
const NEAR: float=120.0
static func pickup(view: Node, id: String, touch: bool) -> String:
 return view.tr("reward.equipped %s")%view.tr(Style.title(id))+"\n"+view.tr(Style.detail(id))+"\n"+view.tr("reward.use.touch" if touch else "reward.use.keyboard")
static func nearby(view: Node, sim: RefCounted, at: float, touch: bool) -> String:
 if not sim.life.enabled:return ""
 for site: RefCounted in sim.trials.sites:
  if sim.modules.found.has(site.id):continue
  var near: bool=absf(at-site.x)<NEAR and Known.known(sim,site.x)
  for x: float in site.positions:
   if absf(at-x)<NEAR and Known.known(sim,x):near=true
  if not near:continue
  var title: String=view.tr("reward.preview %s")%view.tr(Style.title(site.id))
  if site.progress==3:
   title=("← " if site.x<at else "→ ")+view.tr("reward.claim %s")%view.tr(Style.title(site.id))
  return title+"\n"+view.tr(Style.detail(site.id))
 var q: RefCounted=sim.mount_quest
 if q.enabled and not q.recovered:
  var near: bool=absf(at-q.ruin_x)<NEAR and Known.known(sim,q.ruin_x)
  for x: float in q.levers:
   if absf(at-x)<NEAR and Known.known(sim,x):near=true
  if near:
   var title: String=view.tr("reward.horse.preview")
   if q.powered():title=("← " if q.ruin_x<at else "→ ")+view.tr("reward.horse.claim.touch" if touch else "reward.horse.claim.keyboard")
   return title+"\n"+view.tr("reward.horse.cost %d")%q.cost
 return ""
