extends RefCounted
const Fixture=preload("res://tests/test_resident_revert.gd")
func fresh() -> RefCounted:
 var sim: RefCounted=Fixture.new().guided()
 sim.interact(sim.world.sites.hall,"hall")
 sim.core_loop.stage=3;sim.core_loop.income=4;sim.clock.survived=1;sim.clock.day=2
 sim.world.people.clear();sim.raiders.clear();sim.frontier.animals.clear()
 for i: int in range(4):
  sim._add_person(sim.world.sites.hall,-1);sim.world.people[i].role="hunter"
 sim.core_loop.orders.clean(sim)
 return sim
func advance(sim: RefCounted, seconds: float) -> void:
 Fixture.new().advance(sim,seconds,sim.world.sites.hall)
func test_tower_archer_fires_from_the_platform(t):
 var sim: RefCounted=fresh()
 sim.buildings.beacon.level=1
 var person: Dictionary=sim.world.people[0];person.x=sim.buildings.beacon.x
 t.truth(sim.core_loop.orders.assign(sim,"beacon",1),"hunter accepts tower post")
 var enemy: Dictionary=sim._spawn_raider()
 enemy.x=person.x-300;sim.raiders.append(enemy)
 var health: int=enemy.fighter.hp
 advance(sim,0.1)
 t.truth(person.y<400,"archer reached the elevated platform")
 t.truth(enemy.fighter.hp<health,"archer on a tower hits an enemy below")
 var arrows: Array=sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="bolt")
 t.truth(not arrows.is_empty() and arrows[0].get("y",396)<380,"arrow starts at the tower bow, not ground level")
func test_upgrades_add_real_archer_slots_and_survive_a_downgrade(t):
 var sim: RefCounted=fresh()
 for tier: int in range(1,4):
  sim.buildings.beacon.level=tier
  t.truth(sim.core_loop.orders.assign(sim,"beacon",1),"upgrade admits one extra archer")
  t.truth(not sim.core_loop.orders.assign(sim,"beacon",1),"tower refuses archers beyond its level")
 t.equal(sim.core_loop.orders.targets.count("beacon"),3,"three distinct archers occupy the highest tower")
 sim.buildings.beacon.level=1;sim.core_loop.orders.clean(sim)
 t.equal(sim.core_loop.orders.targets.count("beacon"),1,"lost slots release their archers")
func test_unposted_hunters_patrol_outside_then_return_before_night(t):
 var sim: RefCounted=fresh()
 advance(sim,22)
 var outside: int=0
 for person: Dictionary in sim.world.people:
  if person.x<sim.world.sites.wall_left or person.x>sim.world.sites.wall:outside+=1
 t.truth(outside>=2,"without prey unposted hunters still patrol outside both walls")
 sim.clock.remaining=sim.return_margin
 advance(sim,sim.return_margin-1)
 for person: Dictionary in sim.world.people:
  t.truth(person.x>sim.world.sites.wall_left and person.x<sim.world.sites.wall,"hunter is already inside before night begins")
 sim.clock.is_night=true;sim.clock.remaining=50
 sim.frontier.animals.append({"x":sim.world.sites.wall+200,"region":0,"alive":true})
 advance(sim,5)
 t.truth(sim.frontier.animals[0].alive,"night watch does not chase prey back out")
func test_patrolling_hunters_kill_outside_prey(t):
 var sim: RefCounted=fresh()
 sim.frontier.animals.append({"x":sim.world.sites.wall+220,"region":0,"alive":true})
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 advance(sim,25)
 t.truth(not sim.frontier.animals[0].alive,"unposted hunter brings down outside game by day")
func test_three_archers_round_trip_and_overfilled_tower_is_rejected(t):
 var config: Dictionary=preload("res://tests/test_demo_finale_save.gd").new().demo_config()
 var sim: RefCounted=preload("res://application/campaign_session.gd").new(config)
 sim.interact(sim.world.sites.hall,"hall")
 sim.core_loop.income=4;sim.core_loop.stage=1;sim.core_loop.checkpoint_pending=0
 for person: Dictionary in sim.world.people:person.role="hunter"
 sim.buildings.beacon.level=3
 for i: int in range(3):sim.core_loop.orders.assign(sim,"beacon",1)
 var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
 var packet: Dictionary=codec.capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not loaded.is_empty(),"three tower archers restore through actual JSON checkpoint")
 if not loaded.is_empty():t.equal(loaded.session.core_loop.orders.targets.count("beacon"),3,"all three tower orders survive")
 packet.session.buildings.beacon.level=1
 t.truth(codec.restore(packet).is_empty(),"tampered tower capacity is rejected on loading")
