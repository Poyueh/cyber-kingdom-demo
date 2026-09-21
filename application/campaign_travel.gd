extends RefCounted
## Ready -> winded slow walk -> recovering run -> rested sprint.
const Rules=preload("res://domain/travel_recovery_rules.gd")
var rules: Rules=Rules.new()
var exhausted: bool=false
var fast_multiplier: float=1.65
var drain_per_second: float=18.0
var forced_rest: bool=false
var rest_remaining: float=0.0 # Legacy checkpoint field, retained for older journeys.
var winded: bool=false
var rest_ticks: int=0
var last_tick: int=0

func configure(config: Dictionary) -> void:
 rules.apply(config)

func axis(hero: RefCounted, request: float, seconds: float, tick: int=0) -> float:
 if seconds<=0 or not is_finite(seconds) or not hero.is_alive():return 0
 if not forced_rest:return _legacy_axis(hero,request,seconds)
 var elapsed: int=maxi(0,tick-last_tick)
 last_tick=tick
 if exhausted:
  if hero.stamina>=hero.stats.max_stamina*rules.run_recovery_ratio:winded=false
  if absf(request)>0 or hero.attack_remaining>0 or winded:rest_ticks=0
  else:rest_ticks=mini(rest_ticks+elapsed,rules.rest_tick_limit)
  if rest_ticks>=rules.rest_tick_limit and hero.stamina>=hero.stats.max_stamina*rules.sprint_recovery_ratio:
   exhausted=false;winded=false;rest_ticks=0
  else:return signf(request)*(rules.tired_speed_multiplier if winded else 1.0)
 if absf(request)<0.9:return signf(request)
 if hero.attack_remaining>0:return 0
 var cost: float=(drain_per_second+hero.stats.stamina_regen)*seconds
 if not hero.spend_stamina(cost):
  hero.stamina=0;exhausted=true;winded=true;rest_ticks=0
  return signf(request)*rules.tired_speed_multiplier
 return signf(request)*fast_multiplier

func breath_load(hero: RefCounted) -> float:
 if not forced_rest:return 0
 if winded:return 1.0
 if exhausted:return clampf(1.0-hero.stamina/hero.stats.max_stamina,0.25,1.0)
 return 1.0-smoothstep(0.0,0.3,hero.stamina/hero.stats.max_stamina)

func _legacy_axis(hero: RefCounted, request: float, seconds: float) -> float:
 if exhausted:
  rest_remaining=maxf(0,rest_remaining-seconds)
  if rest_remaining>0 or hero.stamina<hero.stats.max_stamina*0.3:return signf(request)
  exhausted=false
 if absf(request)<0.9:return signf(request)
 if hero.attack_remaining>0:return 0
 if not hero.spend_stamina((drain_per_second+hero.stats.stamina_regen)*seconds):
  exhausted=true
  return signf(request)
 return signf(request)*fast_multiplier
