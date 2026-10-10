extends RefCounted
const Known=preload("res://application/ruin_interactions.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
## UI choices are projections. Input and drawing stay outside the rule layer.
static func candidates(sim: RefCounted, x: float, y: float) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if absf(y-430)>42 or not sim.life.enabled:return result
 var q: RefCounted=sim.mount_quest
 if q.enabled and not q.recovered:
  for i: int in range(2):
   if absf(x-q.levers[i])<=44 and Known.known(sim,q.levers[i]):
    var row: Dictionary=sim._choice("mount_lever",q.levers[i],"轉動導流器")
    row.key="mount_lever:%d"%i;row["lever"]=i;result.append(row)
  if absf(x-q.ruin_x)<=60 and Known.known(sim,q.ruin_x) and q.powered():result.append(sim._choice("mount_recover",q.ruin_x,"喚醒機械戰馬"))
 if sim.frontier.city_level>0 and absf(x-q.stable_x)<=60:
  if q.unlocked and sim.can_wield_sword():result.append(sim._choice("mount_switch",q.stable_x,"下馬" if q.riding else "騎乘機械戰馬"))
  elif q.recovered and not q.unlocked and sim.can_wield_sword():result.append(sim._choice("mount_stable",q.stable_x,"修復馬廄",q.cost))
 return result
static func execute(sim: RefCounted, choice: Dictionary) -> void:
 var q: RefCounted=sim.mount_quest
 match choice.id:
  "mount_lever":q.turn(choice.lever)
  "mount_recover":
   q.recover();sim.effects.append({"kind":"mount_recovered","x":choice.x,"life":7.0})
  "mount_stable":
   q.restore_stable(roundi(sim.workforce.elapsed*Clock.TICKS_PER_SECOND))
   sim.effects.append({"kind":"mount_warning","x":choice.x,"life":8.0})
  "mount_switch":q.toggle()
