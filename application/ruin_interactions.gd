extends RefCounted
const Clock=preload("res://domain/time/tick_clock.gd")
## Adapt nearby discovered world circuits to the existing E / swipe interaction.
static func candidates(sim: RefCounted, x: float, y: float) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if absf(y-430)>42:return result
 for site: RefCounted in sim.trials.sites:
  if site.progress==3:continue
  for index: int in range(3):
   var at: float=site.positions[index]
   if absf(at-x)>sim.trials.radius or not known(sim,at):continue
   result.append({"id":"trial","x":at,"text":"接通符石","cost":0,"currency":"","enabled":true,"reason":"","key":"trial:%s:%d"%[site.id,index],"paid":0,"trial":site.id,"station":index})
 return result
static func known(sim: RefCounted, x: float) -> bool:
 for region: Dictionary in sim.frontier.regions:
  if x>=region.x and x<=region.x+region.width:return region.discovered
 return false
static func execute(sim: RefCounted, choice: Dictionary) -> void:
 var success: bool=sim.trials.activate(choice.trial,choice.station,roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND))
 sim.effects.append({"kind":"rune_success" if success else "rune_reset","x":choice.x,"life":0.8})
 if sim.trials.unlocked(choice.trial):sim.effects.append({"kind":"ruin_open","x":sim.trials.get_site(choice.trial).x,"life":1.5})
