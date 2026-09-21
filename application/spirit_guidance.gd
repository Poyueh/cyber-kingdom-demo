extends RefCounted
## Persisted visits use simulation ticks. Advice is a read-only projection of the world.
const Opening=preload("res://application/campaign_guide.gd")
const Expedition=preload("res://application/expedition_guide.gd")
const Clock=preload("res://domain/time/tick_clock.gd")
const TICKS_PER_SECOND: int=Clock.TICKS_PER_SECOND
const OPENING_SECONDS: float=150.0
const VISIT_SECONDS: float=18.0
const FADE_TICKS: int=60
const SHRINE_OFFSET: float=270.0
var opening_finished: bool=false
var summoned: bool=false
var expires_tick: int
var opening_ticks: int
var visit_ticks: int

func _init(config: Dictionary={}) -> void:
 opening_ticks=Clock.ticks_for(clampf(config.get("spirit_opening_seconds",OPENING_SECONDS),30,600))
 visit_ticks=Clock.ticks_for(clampf(config.get("spirit_visit_seconds",VISIT_SECONDS),6,60))
 expires_tick=opening_ticks

func shrine_x(hall_x: float) -> float:
 return hall_x+SHRINE_OFFSET

func advance(tick: int, opening_goal_met: bool) -> void:
 if opening_finished:return
 if tick>=opening_ticks:
  opening_finished=true
 elif opening_goal_met:
  opening_finished=true
  expires_tick=mini(expires_tick,tick+FADE_TICKS*2)

func active(tick: int) -> bool:
 return tick<expires_tick

func summon(tick: int) -> bool:
 if active(tick):return false
 opening_finished=true
 summoned=true
 expires_tick=tick+visit_ticks
 return true

func opacity(tick: int) -> float:
 return clampf(float(expires_tick-tick)/FADE_TICKS,0,1)

func advice(sim: RefCounted, x: float, opening: bool=true, expedition: bool=true) -> Dictionary:
 var tick: int=int(sim.workforce.elapsed*TICKS_PER_SECOND)
 if not sim.is_running() or not active(tick):return {}
 if opening_finished and not summoned:
  return {"kind":"farewell","x":shrine_x(sim.world.sites.hall),"y":430.0,"key":"spirit","action":"move","stage":0}
 var hint: Dictionary=Opening.next(sim,x) if opening else {}
 if hint.is_empty() and expedition:hint=Expedition.next(sim,x,sim._player_y)
 if hint.is_empty() and summoned:
  hint={"kind":"defend","x":sim.world.sites.hall,"y":430.0,"key":"","action":"move","stage":0}
 return hint
