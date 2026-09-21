extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const CONFIG: Dictionary={"seed":42,"immersive_loop":1,"day_seconds":10000.0}
const BODY: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func step(sim: RefCounted, request: float, ticks: int) -> float:
 var speed: float=0.0
 for index: int in range(ticks):
  speed=sim.travel_axis(request,1.0/30)
  sim.advance(1.0/30,30)
 return speed

func test_exhaustion_requires_walk_then_run_then_stationary_rest(t: Object) -> void:
 var sim: RefCounted=Campaign.new(CONFIG)
 var normal: float=step(sim,0.65,1)
 sim.hero.stamina=0
 var tired: float=step(sim,1,1)
 t.truth(tired>0 and tired<normal,"exhaustion permits only a slower walk, not normal running")
 var recovered_run: float=step(sim,1,120)
 t.equal(recovered_run,normal,"recovering enough stamina restores normal run while sprint is held")
 t.truth(sim.travel.exhausted,"normal running does not clear sprint lock")
 step(sim,1,300)
 t.equal(sim.hero.stamina,sim.hero.stats.max_stamina,"holding sprint during lock still recovers stamina")
 t.equal(step(sim,1,1),normal,"full stamina alone cannot bypass required rest")
 step(sim,0,30)
 t.equal(step(sim,1,1),normal,"a brief stop does not unlock sprint")
 step(sim,0,55)
 t.equal(step(sim,1,1),normal,"movement interrupts the continuous rest interval")
 step(sim,0,65)
 t.truth(step(sim,1,1)>normal,"sufficient stationary rest unlocks sprint")

func test_recovery_checkpoint_matches_uninterrupted_ticks(t: Object) -> void:
 var direct: RefCounted=Campaign.new(CONFIG)
 direct.hero.stamina=0;step(direct,1,1);step(direct,0.65,240);step(direct,0,30)
 var codec: RefCounted=Codec.new()
 var restored: Dictionary=codec.restore(codec.capture(direct,CONFIG,BODY))
 t.truth(not restored.is_empty(),"partial fatigue recovery can be saved and loaded")
 if restored.is_empty():return
 var resumed: RefCounted=restored.session
 t.equal(step(direct,0,35),step(resumed,0,35),"both copies finish the same rest interval")
 t.equal(step(direct,1,12),step(resumed,1,12),"both copies unlock the same sprint")
 t.equal(codec.capture(resumed,CONFIG,BODY).travel,codec.capture(direct,CONFIG,BODY).travel,"save resume yields exactly the uninterrupted recovery state")
 t.truth(absf(resumed.hero.stamina-direct.hero.stamina)<0.00001,"recovery also preserves stamina through save resume")

func test_v10_checkpoint_retains_exhaustion_during_upgrade(t: Object) -> void:
 var sim: RefCounted=Campaign.new(CONFIG)
 sim.hero.stamina=0;step(sim,1,1)
 var codec: RefCounted=Codec.new()
 var old: Dictionary=codec.capture(sim,CONFIG,BODY)
 old.version=10
 for key: String in ["winded","rest_ticks","last_tick"]:old.travel.erase(key)
 var before: Dictionary=old.duplicate(true)
 var restored: Dictionary=codec.restore(old)
 t.truth(not restored.is_empty(),"v10 fatigue checkpoint upgrades")
 t.equal(old,before,"migration never mutates original data")
 if restored.is_empty():return
 var slow: float=step(restored.session,1,1)
 t.truth(slow>0 and slow<1,"loading an exhausted old save cannot grant running or sprinting")

func test_zero_time_does_not_advance_recovery(t: Object) -> void:
 var sim: RefCounted=Campaign.new(CONFIG)
 sim.hero.stamina=0;step(sim,1,1)
 var codec: RefCounted=Codec.new()
 var before: Dictionary=codec.capture(sim,CONFIG,BODY)
 for index: int in range(100):sim.travel_axis(0,0)
 t.equal(codec.capture(sim,CONFIG,BODY),before,"paused input cannot consume the rest timer")
