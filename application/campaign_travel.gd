extends RefCounted
## Exhaustion limits sprinting, never ordinary walking or passive recovery.
var exhausted: bool=false
var fast_multiplier: float=1.65
var drain_per_second: float=18.0
var forced_rest: bool=false
var rest_remaining: float=0.0
func axis(hero, request: float, seconds: float) -> float:
 if seconds<=0 or not is_finite(seconds) or not hero.is_alive():return 0
 if exhausted:
  rest_remaining=maxf(0,rest_remaining-seconds)
  var recovery: float=0.35 if forced_rest else 0.3
  if rest_remaining>0 or hero.stamina<hero.stats.max_stamina*recovery:return signf(request)
  exhausted=false
 if absf(request)<0.9:return signf(request)
 if hero.attack_remaining>0:return 0
 var cost: float=(drain_per_second+hero.stats.stamina_regen)*seconds
 if not hero.spend_stamina(cost):
  exhausted=true
  if forced_rest:
   hero.stamina=0;rest_remaining=1.5
  return signf(request)
 return signf(request)*fast_multiplier
