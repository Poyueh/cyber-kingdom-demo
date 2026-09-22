extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Hold = preload("res://application/investment_hold.gd")
const Pouch = preload("res://domain/crystal_pouch.gd")
const Codec = preload("res://application/campaign_snapshot.gd")

func test_unlit_camp_and_tools(t) -> void:
 var sim = Campaign.new({"immersive_loop":1})
 t.truth(not sim.can_wield_sword(),"arrival has no sword")
 t.truth(sim.interact(sim.world.sites.hall,"hall"),"draw sword lights camp")
 t.equal(sim.frontier.city_level,1,"sword ignites first camp")
 t.truth(sim.can_wield_sword(),"lit camp grants sword")
 t.truth(sim.built.workshop and sim.built.hunt_tools,"work and bow facilities assemble")
 t.truth(sim.context_for_key(sim.world.sites.forge,"forge").id.is_empty(),"shield equipment absent")
 t.truth(sim.context_for_key(sim.world.sites.armory,"armory").id.is_empty(),"spear rack locked before tier three")
 sim.frontier.city_level=3
 t.truth(sim.context_for_key(sim.world.sites.armory,"armory").enabled,"tier three unlocks spear equipment")

func test_unfinished_payment_returns_to_ground(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.world.people.clear();sim.frontier.city_level=1
 var hold=Hold.new()
 var before: int=sim.pouch.amount
 hold.step(0.016,true,true,sim,sim.world.sites.workshop)
 hold.step(0.016,false,true,sim,sim.world.sites.workshop)
 t.equal(sim.pouch.ground_total(),0,"unfinished payment hangs above building for one second")
 hold.step(1.01,false,true,sim,sim.world.sites.workshop)
 t.equal(sim.pouch.amount,before-1,"refund must be physically collected")
 t.equal(sim.pouch.ground_total(),1,"unfinished crystal falls back")
 t.truth(sim.investments.is_empty(),"cancelled slots no longer stay filled")

func test_residents_collect_offer_and_recruit(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.world.people.clear();sim.frontier.city_level=1;sim.pouch.amount=0
 sim.world.people.append({"x":30.0,"role":"wanderer","hurt":0.0,"cooldown":0.0,"region":-1})
 sim.pouch.drop(1,30)
 sim.advance(0.5,1000)
 t.equal(sim.world.people[0].role,"citizen","ordinary nearby crystal recruits wanderer")
 sim.pouch.drop(3,sim.world.people[0].x)
 sim.advance(0.5,1000)
 t.equal(sim.world.people[0].get("crystals",0),3,"resident holds ground yield")
 sim.advance(0.1,sim.world.people[0].x)
 t.equal(sim.world.people[0].get("crystals",0),0,"approaching knight receives an offering burst")
 t.equal(sim.pouch.ground_total()+sim.pouch.amount,3,"offering conserves held crystals")
 for i in range(120):sim.advance(1.0/60,sim.world.people[0].x)
 t.equal(sim.pouch.amount,3,"resident cannot recapture their gift before it reaches knight")

func test_fast_run_exhaustion_and_rest(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.hero.stamina=0
 t.equal(sim.travel_axis(1,0.1),0.0,"empty fast run stops for breathing")
 sim.hero.stamina=10
 t.equal(sim.travel_axis(0.5,0.1),0.0,"movement cannot bypass compulsory breathing")
 sim.hero.stamina=sim.hero.stats.max_stamina
 sim.advance(2.1,30)
 sim.travel_axis(0,0.1)
 t.truth(sim.travel_axis(0.5,0.1)>0,"movement resumes after recovery")

func test_repeated_yield_is_bounded_and_conserved(t) -> void:
 var pouch=Pouch.new(12,12)
 for i in range(1200):pouch.drop(1,800)
 t.equal(pouch.ground_total(),1200,"merged harvest retains all crystals")
 t.truth(pouch.drops.size()<=2,"same-position yield cannot grow per-crystal storage")

func test_new_rules_save_and_resume(t) -> void:
 var config: Dictionary={"seed":42,"immersive_loop":1}
 var sim=Campaign.new(config)
 sim.world.people.clear();sim.frontier.city_level=1
 sim.world.people.append({"x":30.0,"role":"engineer","hurt":0.0,"cooldown":0.0,"region":-1,"crystals":4})
 sim.hero.stamina=0;sim.travel_axis(1,0.1)
 var codec=Codec.new()
 var snapshot: Dictionary=codec.capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(snapshot)
 t.truth(not restored.is_empty(),"new journey restores resident wallet and exhaustion")
 if restored.is_empty():return
 t.equal(restored.session.world.people[0].crystals,4,"resident wallet survives save")
 t.truth(restored.session.travel.exhausted,"reloading does not bypass exhaustion")
 t.equal(restored.session.travel_axis(0.65,0.1),0.0,"restored exhausted knight must finish breathing")
 var old=Campaign.new({"seed":42})
 var legacy: Dictionary=codec.capture(old,{"seed":42},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 legacy.version=6;legacy.erase("modules");legacy.erase("spirit");legacy.erase("survival");legacy.erase("travel")
 t.truth(not codec.restore(legacy).is_empty(),"v6 saves migrate without losing their original rules")

func test_night_work_and_threat_retreat(t) -> void:
 var sim=Campaign.new({"seed":42,"immersive_loop":1,"day_seconds":1000.0})
 sim.world.people.clear();sim.frontier.city_level=1
 sim.clock.is_night=true;sim.clock.remaining=100
 sim.world.people.append({"x":-350.0,"role":"farmer","hurt":0.0,"cooldown":0.0,"region":-1})
 sim.frontier.farm_active=true
 sim.advance(0.5,900)
 t.truth(not sim.world.people[0].sheltering,"night alone does not stop work")
 var enemy: Dictionary=sim._spawn_raider();enemy.x=-430;sim.raiders.append(enemy)
 sim.advance(0.1,900)
 t.truth(sim.world.people[0].sheltering,"nearby enemy interrupts work")

func test_full_pouch_sinks_excess(t) -> void:
 var sim=Campaign.new({"seed":42,"immersive_loop":1})
 sim.world.people.clear();sim.pouch.amount=sim.pouch.capacity
 sim.pouch.drop(1,800)
 sim.advance(0.1,800)
 t.equal(sim.pouch.ground_total(),0,"extra crystal falls into water at full pouch")
 t.truth(sim.effects.any(func(e):return e.kind=="crystal_sink"),"overflow produces visible water feedback")

func test_every_resident_job_carries_and_offers(t) -> void:
 for role in ["citizen","engineer","farmer","hunter","guard"]:
  var sim=Campaign.new({"immersive_loop":1})
  sim.world.people.clear();sim.pouch.amount=0
  var person: Dictionary={"x":30.0,"role":role,"hurt":0.0,"cooldown":0.0}
  sim.world.people.append(person);sim.pouch.drop(2,30)
  sim.life.collect(sim.world,sim.pouch,[],1000,430)
  t.equal(person.get("crystals",0),2,role+" collects and holds crystals")
  sim.life.collect(sim.world,sim.pouch,[],30,430)
  t.equal(person.crystals,0,role+" offers crystals when knight approaches")
  t.equal(sim.pouch.ground_total(),2,role+" gift is conserved")

func test_damaged_v6_config_is_protected(t) -> void:
 var codec=Codec.new()
 var sim=Campaign.new({"seed":42})
 var packet: Dictionary=codec.capture(sim,{"seed":42},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 packet.version=6;packet.erase("modules");packet.erase("spirit");packet.erase("survival");packet.erase("travel");packet.config=[]
 t.truth(codec.restore(packet).is_empty(),"malformed legacy config is rejected before constructing a campaign")

func test_single_taps_resume_during_refund_grace(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.world.people.clear();sim.frontier.city_level=1
 var hold=Hold.new()
 var x: float=sim.world.sites.workshop
 hold.step(0.01,true,true,sim,x)
 hold.step(0.01,false,true,sim,x)
 hold.step(0.8,false,true,sim,x)
 t.equal(sim.context(x).paid,1,"partial payment remains visible inside one-second grace")
 hold.step(0.01,true,true,sim,x)
 hold.step(0.01,false,true,sim,x)
 hold.step(1.2,false,true,sim,x)
 t.equal(sim.world.tools.hammer,1,"second single tap completes tool during grace")
 t.equal(sim.pouch.ground_total(),0,"completed purchase has no late refund")

func test_refund_waits_then_falls_at_building_when_knight_leaves(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.world.people.clear();sim.frontier.city_level=1
 var hold=Hold.new()
 var x: float=sim.world.sites.workshop
 hold.step(0.01,true,true,sim,x)
 hold.step(0.01,false,true,sim,x+500)
 hold.step(0.8,false,true,sim,x+500)
 t.equal(sim.pouch.ground_total(),0,"leaving does not skip the grace period")
 hold.step(0.21,false,true,sim,x+500)
 t.equal(sim.pouch.ground_total(),1,"expired payment refunds exactly once")
 t.truth(absf(sim.pouch.drops[0].x-x)<1,"refund falls at the building rather than following the knight")
 hold.step(2,false,true,sim,x+500)
 t.equal(sim.pouch.ground_total(),1,"expired grace cannot duplicate crystals")

func test_each_tap_renews_the_payment_window(t) -> void:
 var sim=Campaign.new({"immersive_loop":1})
 sim.world.people.clear();sim.frontier.city_level=1
 var hold=Hold.new()
 var x: float=sim.world.sites.hall
 var cost: int=sim.context(x).cost
 for i in range(cost):
  hold.step(0.01,true,true,sim,x)
  hold.step(0.01,false,true,sim,x)
  hold.step(0.8,false,true,sim,x)
 t.equal(sim.frontier.city_level,2,"spaced single taps each renew one second until camp upgrade completes")
 hold.step(2,false,true,sim,x)
 t.equal(sim.pouch.ground_total(),0,"renewed completed payment never refunds later")

func test_walking_recovers_without_rearming_sprint_early(t) -> void:
 var config: Dictionary={"immersive_loop":1,"fast_run_multiplier":2.6,"rest_regen":10.0,"seed":42}
 var sim=Campaign.new(config)
 sim.hero.stamina=0
 sim.travel_axis(1,0.1)
 var can_walk: bool=true
 for i in range(30):
  sim.advance(1.0/60.0,800)
  can_walk=can_walk and sim.travel_axis(0.5,1.0/60.0)==0.0
 t.truth(can_walk,"movement stays locked during initial breathing")
 t.truth(sim.hero.stamina>0 and sim.hero.stamina<10,"breathing gradually restores energy")
 t.equal(sim.travel_axis(1,0.1),0.0,"brief input does not bypass breathing stop")
 var codec=Codec.new()
 var saved: Dictionary=codec.capture(sim,config,{"x":800.0,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(saved)
 t.truth(not restored.is_empty(),"stronger fast-run ratio remains saveable")
 if restored.is_empty():return
 var same_motion: bool=true
 for i in range(240):
  sim.advance(1.0/60,800);restored.session.advance(1.0/60,800)
  same_motion=same_motion and sim.travel_axis(0.5,1.0/60)==restored.session.travel_axis(0.5,1.0/60)
 t.truth(same_motion,"recovery follows same movement after reload")
 t.equal(sim.hero.stamina,restored.session.hero.stamina,"recovery energy is deterministic across save")
 t.equal(sim.travel_axis(1,0.1),1.0,"recovered running still needs a stationary rest before sprinting")
 for i in range(300):
  sim.advance(1.0/60,800);sim.travel_axis(0,1.0/60)
 t.truth(sim.travel_axis(1,0.1)>2.3,"rested sprint is clearly faster than normal running")

func test_smaller_arrival_pouch_can_start_worker_economy(t) -> void:
 var tuning=load("res://data/campaign.tres")
 var sim=Campaign.new(tuning.campaign_rules())
 t.truth(sim.pouch.amount<=6,"new journey starts with a small supply")
 t.truth(sim.interact(sim.world.sites.hall,"hall"),"arrival supply can light camp")
 t.truth(sim.interact(sim.world.sites.workshop,"workshop"),"remaining supply can provide engineering tool")
 t.truth(sim.pouch.amount>=sim.prices.recruit+sim.prices.mark,"reserve can recruit and commission first harvest")
