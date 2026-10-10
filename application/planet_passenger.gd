extends RefCounted
const Clock=preload("res://domain/time/tick_clock.gd")
## Only the knight and merchant travel. Local people, resources and time stay home.
static func carry(source: RefCounted, destination: RefCounted) -> void:
 destination.mount_quest.unlocked=source.mount_quest.unlocked
 destination.mount_quest.riding=source.mount_quest.riding
 destination.pouch.amount=source.pouch.amount
 destination.survival.armed=source.survival.armed
 destination.survival.sword_on_ground=false
 destination.hero.stamina=source.hero.stamina
 destination.hero.hp=source.hero.hp
 for key: String in ["exhausted","winded","rest_ticks","breath_ticks","rest_remaining"]:destination.travel.set(key,source.travel.get(key))
 destination.travel.last_tick=roundi(destination.workforce.elapsed*Clock.TICKS_PER_SECOND)
 var modules: Dictionary=source.modules.capture()
 modules.ready_tick=roundi(destination.workforce.elapsed*Clock.TICKS_PER_SECOND)+maxi(0,modules.ready_tick-roundi(source.workforce.elapsed*Clock.TICKS_PER_SECOND))
 if modules.charge_ticks>0:modules.charge_last_tick=roundi(destination.workforce.elapsed*Clock.TICKS_PER_SECOND)
 var restored: bool=destination.modules.restore(modules,destination.workforce.elapsed)
 assert(restored,"Passenger module state must remain valid")
 for site: RefCounted in destination.trials.sites:
  if modules.found.has(site.id):destination.trials.unlock(site.id)
 var merchant: Dictionary=source.merchant.capture()
 merchant.x=destination.merchant.home_x;merchant.last_tick=roundi(destination.workforce.elapsed*Clock.TICKS_PER_SECOND);merchant.moving=false
 var remaining: int=maxi(0,source.merchant.return_day-source.clock.day)
 merchant.return_day=0 if source.merchant.return_day==0 else destination.clock.day+remaining
 # Arrival uses a local calendar; the return reward is still the same paid trip.
 destination.merchant.phase=merchant.phase;destination.merchant.x=merchant.x
 destination.merchant.last_tick=merchant.last_tick;destination.merchant.return_day=merchant.return_day
 destination.merchant.facing=merchant.facing;destination.merchant.walk_distance=merchant.walk_distance;destination.merchant.moving=false
