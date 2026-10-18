extends RefCounted
var recovery_ratio: float
func _init(ratio: float) -> void:recovery_ratio=ratio
func axis(travel: RefCounted, hero: RefCounted, request: float, seconds: float) -> float:
 travel.winded=false;travel.breath_ticks=0;travel.rest_ticks=0
 if travel.exhausted and hero.stamina>=hero.stats.max_stamina*recovery_ratio:travel.exhausted=false
 if absf(request)<0.9 or travel.exhausted:return signf(request)
 if hero.attack_remaining>0:return 0.0
 if not hero.spend_stamina((travel.drain_per_second+hero.stats.stamina_regen)*seconds):
  hero.stamina=0;travel.exhausted=true
  return signf(request)
 return signf(request)*travel.fast_multiplier
