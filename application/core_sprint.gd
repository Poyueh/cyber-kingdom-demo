extends RefCounted
## Guided journeys: breathing stop -> slow walk -> run -> full-energy sprint.
const Rules=preload("res://domain/travel_recovery_rules.gd")
var rules: Rules
var recovery_ratio: float
func _init(parameters: Rules) -> void:
 rules=parameters
 recovery_ratio=rules.guided_sprint_recovery_ratio

func _depleted(travel: RefCounted, hero: RefCounted) -> void:
 if travel.exhausted or hero.stamina>0:return
 hero.stamina=0
 travel.exhausted=true;travel.winded=true;travel.rest_ticks=0
 travel.breath_ticks=rules.guided_breath_tick_limit

func _recover(travel: RefCounted, hero: RefCounted) -> void:
 if not travel.exhausted or travel.breath_ticks>0:return
 travel.winded=hero.stamina<hero.stats.max_stamina*rules.guided_run_recovery_ratio
 if hero.stamina>=hero.stats.max_stamina*recovery_ratio:
  travel.exhausted=false;travel.winded=false;travel.rest_ticks=0

func advance(travel: RefCounted, hero: RefCounted, seconds: float, tick: int) -> void:
 _depleted(travel,hero)
 var breathing: bool=travel.breath_ticks>0
 var elapsed: int=maxi(0,tick-travel.last_tick)
 travel.last_tick=tick
 # Combat timers still advance; only natural stamina regeneration waits.
 hero.advance(seconds,not breathing)
 travel.breath_ticks=maxi(0,travel.breath_ticks-elapsed)
 _recover(travel,hero)

func axis(travel: RefCounted, hero: RefCounted, request: float, seconds: float) -> float:
 _depleted(travel,hero)
 _recover(travel,hero)
 if travel.breath_ticks>0:return 0.0
 if travel.exhausted:return signf(request)*(rules.tired_speed_multiplier if travel.winded else 1.0)
 if absf(request)<0.9:return signf(request)
 if hero.attack_remaining>0:return 0.0
 if not hero.spend_stamina((travel.drain_per_second+hero.stats.stamina_regen)*seconds):hero.stamina=0
 _depleted(travel,hero)
 if travel.exhausted:return 0.0
 return signf(request)*travel.fast_multiplier
