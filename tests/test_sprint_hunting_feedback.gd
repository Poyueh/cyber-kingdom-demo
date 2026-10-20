extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Fixture=preload("res://tests/test_demo_finale_save.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const STEP: float=1.0/30.0
const BODY: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func configuration(mode: int=3) -> Dictionary:
 var config: Dictionary=Fixture.new().demo_config()
 config.core_loop_version=mode
 config.voyage_enabled=int(mode==2)
 if mode!=3:config.erase("rocket_finale")
 return config

func tick(sim: RefCounted, request: float=1.0) -> float:
 sim.advance(STEP,30)
 return sim.travel_axis(request,STEP)

func test_guided_exhaustion_stops_then_walks_runs_and_rearms_at_full(t: Object) -> void:
 for mode: int in [1,2,3]:
  var sim: RefCounted=Campaign.new(configuration(mode))
  sim.hero.stamina=0
  t.equal(sim.travel_axis(1,STEP),0.0,"empty knight stops in all guided editions")
  var stopped: bool=true
  for frame: int in range(74):
   stopped=stopped and is_zero_approx(tick(sim,-1)) and is_zero_approx(sim.hero.stamina)
  t.truth(stopped,"turning or held sprint cannot bypass 2.5 seconds of breathing; no natural regeneration yet")
  var walk: float=tick(sim,1)
  t.truth(walk>0 and walk<1,"after 75 ticks the knight can slow-walk")
  tick(sim,0.5)
  t.truth(sim.hero.stamina>0,"natural recovery starts after breathing, even while moving")
  sim.hero.stamina=sim.hero.stats.max_stamina/3.0-0.01
  t.truth(sim.travel_axis(1,STEP)<1,"below one third remains walking")
  sim.hero.stamina=sim.hero.stats.max_stamina/3.0
  t.equal(sim.travel_axis(1,STEP),1.0,"exactly one third unlocks ordinary running")
  sim.hero.stamina=sim.hero.stats.max_stamina-0.01
  t.equal(sim.travel_axis(1,STEP),1.0,"sprint stays locked until completely full")
  sim.hero.stamina=sim.hero.stats.max_stamina
  t.truth(sim.travel_axis(1,STEP)>1.5,"full stamina rearms sprint without another stationary rest")

func test_breathing_and_recovery_save_resume_match_continuous_inputs(t: Object) -> void:
 for checkpoint: int in [20,100,220]:
  var config: Dictionary=configuration()
  config.core_sprint_ratio=0.3 # Older guided saves adopt the new movement rules.
  var direct: RefCounted=Campaign.new(config)
  direct.hero.stamina=0;direct.travel_axis(1,STEP)
  for frame: int in range(checkpoint):tick(direct,0.5)
  var codec: RefCounted=Codec.new()
  var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(direct,config,BODY))))
  t.truth(not loaded.is_empty(),"breathing/walking/running recovery survives actual JSON: "+codec.last_error)
  if loaded.is_empty():continue
  var copy: RefCounted=loaded.session
  var identical: bool=true
  for frame: int in range(430):
   identical=identical and is_equal_approx(tick(direct),tick(copy)) and is_equal_approx(direct.hero.stamina,copy.hero.stamina)
  t.truth(identical,"same input keeps the same stamina and stage after save/load")
  t.equal(codec.capture(direct,config,BODY).travel,codec.capture(copy,config,BODY).travel,"travel timer state is deterministic")

func test_breathing_progresses_without_movement_and_pause_preserves_it(t: Object) -> void:
 var sim: RefCounted=Campaign.new(configuration())
 sim.hero.stamina=0;sim.travel_axis(0,STEP)
 t.truth(sim.travel.breath_ticks>0,"zero energy triggers breathing even with no direction held")
 var before: int=sim.travel.breath_ticks
 for frame: int in range(10):sim.advance(0,30);sim.travel_axis(1,0)
 t.equal(sim.travel.breath_ticks,before,"pause never consumes breathing time")
 for frame: int in range(75):sim.advance(STEP,30)
 t.equal(sim.travel.breath_ticks,0,"simulation time releases breathing without polling movement input")
 t.equal(sim.hero.stamina,0.0,"breathing interval does not naturally recharge stamina")
 t.truth(tick(sim,0.5)>0 and sim.hero.stamina>0,"walking and recovery start after breathing")

func forest() -> RefCounted:
 var sim: RefCounted=Campaign.new(configuration())
 sim.interact(sim.world.sites.hall,"hall")
 sim.core_loop.stage=3;sim.core_loop.income=4;sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
 sim.clock.survived=1;sim.clock.day=2;sim.clock.is_night=false;sim.clock.remaining=180
 for person: Dictionary in sim.world.people:person.role="citizen"
 for animal: Dictionary in sim.frontier.animals:animal.alive=false
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 sim.world.people[0].role="hunter";sim.world.people[0].x=sim.world.sites.wall+160
 sim.core_loop.orders.clean(sim)
 return sim

func prey(sim: RefCounted, x: float) -> Dictionary:
 var region: int=0
 for i: int in range(sim.frontier.regions.size()):
  var area: Dictionary=sim.frontier.regions[i]
  if x>=area.x and x<area.x+area.width:region=i;break
 var animal: Dictionary={"x":x,"home_x":x,"region":region,"alive":true}
 for slot: int in range(sim.frontier.animals.size()):
  if not sim.frontier.animals[slot].alive:
   sim.frontier.animals[slot]=animal
   return animal
 return {}

func advance(sim: RefCounted, seconds: float, hero_x: float=-700) -> void:
 for tick: int in range(roundi(seconds/STEP)):sim.advance(STEP,hero_x)

func test_unassigned_hunters_stay_near_walls_instead_of_chasing_far_game(t):
 var sim: RefCounted=forest()
 var near: Dictionary=prey(sim,sim.world.sites.wall+220)
 var far: Dictionary=prey(sim,sim.world.sites.wall+800)
 var furthest: float=0
 for tick: int in range(1800):
  sim.advance(STEP,-700)
  furthest=maxf(furthest,sim.world.people[0].x-sim.world.sites.wall)
 t.truth(not near.alive,"free archer hunts nearby game")
 t.truth(far.alive,"distant game is not pursued beyond the walls")
 t.truth(furthest<=302,"free archer patrol remains within 300 pixels of the wall")

func test_catch_stays_with_the_hunter_until_the_knight_approaches(t):
 var config: Dictionary=configuration()
 var sim: RefCounted=forest()
 prey(sim,sim.world.people[0].x+85)
 var money: int=sim.pouch.amount
 advance(sim,0.1)
 t.equal(sim.world.people[0].get("crystals",0),2,"hunter keeps both crystals from its own catch")
 t.equal(sim.pouch.ground_total(),0,"catch does not scatter unclaimed crystals on the ground")
 t.equal(sim.pouch.amount,money,"distant knight receives no instant income")
 var codec: RefCounted=Codec.new()
 var saved: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(sim,config,BODY))))
 t.truth(not saved.is_empty(),"hunter and its catch survive an actual save: "+codec.last_error)
 if saved.is_empty():return
 var loaded: RefCounted=saved.session
 t.equal(loaded.world.people[0].get("crystals",0),2,"loaded hunter still carries the catch")
 var at: float=loaded.world.people[0].x
 advance(loaded,2,at)
 t.equal(loaded.world.people[0].get("crystals",0),0,"nearby knight receives the hunter's carried crystals")
 t.equal(loaded.pouch.amount,money+2,"delivery conserves the two-crystal reward")

func test_hunters_return_for_night_and_retreat_from_monsters(t):
 var sim: RefCounted=forest()
 var person: Dictionary=sim.world.people[0]
 var edge: float=sim.world.sites.wall
 var outside: Dictionary=prey(sim,edge+220)
 sim.clock.is_night=true;sim.clock.remaining=55
 advance(sim,15)
 t.truth(person.x<edge and outside.alive,"night watch returns inside without pursuing prey")
 sim.clock.is_night=false;sim.clock.remaining=180;person.x=edge+160
 var enemy: Dictionary=sim._spawn_raider();enemy.x=person.x+150;sim.raiders.append(enemy)
 var hp: int=enemy.fighter.hp
 advance(sim,0.1)
 t.truth(person.x<edge+160,"threatened hunter steps back toward town")
 t.truth(enemy.fighter.hp<hp,"retreating archer can shoot the approaching monster")

func test_full_hunting_bag_preserves_live_prey(t):
 var sim: RefCounted=forest()
 sim.world.people[0]["crystals"]=12
 var animal: Dictionary=prey(sim,sim.world.people[0].x+85)
 advance(sim,0.2)
 t.truth(animal.alive,"a full hunter does not kill prey and discard its reward")
 t.equal(sim.world.people[0].crystals,12,"full hunting bag keeps all earned crystals")

func test_resumed_sprint_recovery_matches_uninterrupted_inputs(t):
 var config: Dictionary=configuration()
 var direct: RefCounted=Campaign.new(config)
 direct.hero.stamina=0;direct.travel_axis(1,STEP)
 for tick: int in range(30):
  direct.travel_axis(0.5,STEP);direct.advance(STEP,30)
 var codec: RefCounted=Codec.new()
 var saved: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(direct,config,BODY))))
 t.truth(not saved.is_empty(),"mid-recovery state saves and loads")
 if saved.is_empty():return
 var resumed: RefCounted=saved.session
 var same_motion: bool=true
 for tick: int in range(120):
  same_motion=same_motion and is_equal_approx(direct.travel_axis(1,STEP),resumed.travel_axis(1,STEP))
  direct.advance(STEP,30);resumed.advance(STEP,30)
 t.truth(same_motion,"same continuing input resumes sprint on the same tick after loading")
 t.truth(is_equal_approx(direct.hero.stamina,resumed.hero.stamina) and direct.travel.exhausted==resumed.travel.exhausted,"recovery and expenditure match uninterrupted play")

func test_bad_hunting_limits_are_rejected_before_restoring(t):
 var config: Dictionary=configuration()
 var sim: RefCounted=Campaign.new(config)
 var codec: RefCounted=Codec.new()
 var packet: Dictionary=codec.capture(sim,config,BODY)
 packet.config.hunt_wall_margin="far away"
 t.truth(codec.restore(packet).is_empty(),"nonnumeric hunting radius is rejected safely")
 packet.config.hunt_wall_margin=10000
 t.truth(codec.restore(packet).is_empty(),"out-of-range hunting radius is rejected")

func test_custom_breath_duration_and_corrupt_recovery_settings(t: Object) -> void:
 var config: Dictionary=configuration()
 config.guided_breath_seconds=3.0
 var sim: RefCounted=Campaign.new(config)
 sim.hero.stamina=0;sim.travel_axis(1,STEP)
 for frame: int in range(89):tick(sim)
 t.equal(sim.travel_axis(1,STEP),0.0,"configured three-second breathing still stops before the boundary")
 t.truth(tick(sim)>0,"configured breathing ends on its 90th tick")
 var codec: RefCounted=Codec.new()
 var packet: Dictionary=codec.capture(sim,config,BODY)
 packet.config.guided_breath_seconds=100
 t.truth(codec.restore(packet).is_empty(),"out-of-range breathing settings cannot corrupt a save")
 packet.config.guided_breath_seconds=3.0;packet.travel.breath_ticks=91
 t.truth(codec.restore(packet).is_empty(),"remaining breathing time cannot exceed its configured duration")

func test_exact_last_sprint_cost_enters_breathing_immediately(t: Object) -> void:
 var sim: RefCounted=Campaign.new(configuration())
 sim.hero.stamina=(sim.travel.drain_per_second+sim.hero.stats.stamina_regen)*STEP
 t.equal(sim.travel_axis(1,STEP),0.0,"spending the exact last stamina enters breathing without one extra sprint frame")
 t.truth(sim.travel.breath_ticks>0,"exact depletion receives the full breathing interval")
