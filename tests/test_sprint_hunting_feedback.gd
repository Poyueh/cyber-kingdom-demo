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

func test_main_and_demo_resume_at_one_third_while_moving(t):
 for mode: int in [2,3]:
  for old_default: bool in [false,true]:
   var config: Dictionary=configuration(mode)
   if old_default:config.core_sprint_ratio=0.3
   var sim: RefCounted=Campaign.new(config)
   sim.hero.stamina=0
   t.equal(sim.travel_axis(1,STEP),1.0,"empty guided knight keeps running, mode %d"%mode)
   sim.hero.stamina=sim.hero.stats.max_stamina/3.0-0.01
   t.equal(sim.travel_axis(1,STEP),1.0,"sprint remains locked immediately below one third")
   sim.hero.stamina=sim.hero.stats.max_stamina/3.0
   t.truth(sim.travel_axis(1,STEP)>1.5,"exactly one third rearms sprint without stopping")

func test_exhausted_demo_save_recovers_without_compulsory_rest(t):
 var config: Dictionary=configuration()
 config.core_sprint_ratio=0.3
 var sim: RefCounted=Campaign.new(config)
 sim.hero.stamina=0;sim.travel_axis(1,STEP)
 var codec: RefCounted=Codec.new()
 var saved: Dictionary=codec.capture(sim,config,BODY)
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not loaded.is_empty(),"exhausted Demo round-trips through actual JSON")
 if loaded.is_empty():return
 var copy: RefCounted=loaded.session
 var kept_moving: bool=true
 for tick: int in range(102):
  kept_moving=kept_moving and copy.travel_axis(0.5,STEP)>=1.0
  copy.advance(STEP,30)
 t.truth(kept_moving,"recovering knight can keep moving")
 t.truth(copy.travel_axis(1,STEP)>1.5,"loaded knight can sprint again after recovering one third on the move")

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
