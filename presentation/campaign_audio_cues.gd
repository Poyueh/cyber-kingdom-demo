extends RefCounted
## Ephemeral presentation observer. No sound history enters campaign saves.
const EFFECTS={"core_hit":"heavy","tower_arrow":"slash1","tower_laser":"dash","construction_done":"build","pay":"pay","chest_burst":"chest","recruited":"recruit","crystal_pickup":"pickup","hit":"hit"}
var _session: RefCounted
var _seen: Array=[]
var _active:=false
var _combo:=0
var _dash:=0.0
var _hp:=0
var _absorbed:=0
var _city:=0
var _night:=false
var _sealed:=0
var _outcome:="running"
func sample(sim,x: float,paused: bool) -> Array[String]:
 var result: Array[String]=[]
 var active: bool=sim.hero.is_attack_active()
 var sealed: int=sim.mission.rifts.filter(func(r):return r.sealed).size()
 if _session==sim and not paused:
  if active and (not _active or _combo!=sim.hero.combo_step):result.append("slash%d"%maxi(1,sim.hero.combo_step))
  if sim.hero.dash_remaining>_dash:result.append("dash")
  for effect in sim.effects:
   if _seen.any(func(old):return is_same(old,effect)):continue
   if absf(effect.x-x)>800 and effect.kind!="core_hit":continue
   var kind: String=EFFECTS.get(effect.kind,"")
   if kind=="hit" and effect.get("heavy",false):kind="heavy"
   if not kind.is_empty() and not result.has(kind):result.append(kind)
  if sim.hero.hp<_hp or sim.hero.shield_absorbed>_absorbed:result.append("hurt")
  if sim.frontier.city_level>_city:result.append("build")
  if sim.clock.is_night and not _night:result.append("night")
  if sealed>_sealed:result.append("seal")
  if sim.mission.outcome!=_outcome and sim.mission.outcome in ["victory","defeat"]:result.append(sim.mission.outcome)
 _session=sim
 _seen=sim.effects.duplicate()
 _active=active;_combo=sim.hero.combo_step;_dash=sim.hero.dash_remaining
 _hp=sim.hero.hp;_absorbed=sim.hero.shield_absorbed
 _city=sim.frontier.city_level;_night=sim.clock.is_night;_sealed=sealed;_outcome=sim.mission.outcome
 return result
