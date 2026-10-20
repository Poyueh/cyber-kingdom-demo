extends RefCounted
const Fixture=preload("res://tests/test_command_squads.gd")
func fresh() -> RefCounted:
 var sim: RefCounted=Fixture.new().forest()
 sim.world.people.clear();sim.raiders.clear()
 sim._add_person(sim.world.sites.hall,-1);sim.world.people[0].role="hunter"
 sim.core_loop.orders.clean(sim)
 return sim
func test_orders_require_local_payment_and_fail_without_spending(t):
 var sim: RefCounted=fresh();var orders: RefCounted=sim.core_loop.orders
 t.truth(orders.has_method("order"),"paid building command exists")
 if not orders.has_method("order"):return
 var at: float=orders.station_x(sim)
 t.truth(not orders.order(sim,"wall",1,at+500),"remote command is refused")
 t.equal(sim.pouch.amount,30,"remote command spends nothing")
 t.truth(orders.order(sim,"wall",1,at),"one local archer accepts a paid command")
 t.equal(sim.pouch.amount,29,"exactly one crystal is paid")
 t.truth(not orders.order(sim,"wall",1,at),"missing available archer cannot charge again")
 t.equal(sim.pouch.amount,29,"failed assignment preserves the wallet")
 t.truth(orders.order(sim,"wall",-1,at),"release is free")
 sim.pouch.amount=0
 t.truth(not orders.order(sim,"wall_left",1,at),"empty bag cannot assign")
 t.equal(orders.targets[0],"","failed payment never changes the roster")
func test_unfinished_outer_wall_never_pulls_a_live_defense_out(t):
 var sim: RefCounted=fresh()
 var id: String=sim.defenses.plots.keys().filter(func(k: String)->bool:return sim.defenses.plots[k].side==1)[0]
 sim.world.walls[id].level=1;sim.world.walls[id].hp=40;sim.world.walls[id].pending=true
 t.truth(sim.core_loop.orders.assign(sim,"wall",1),"initial defense assigned")
 t.equal(sim.core_loop.orders.position(sim,"wall"),sim.world.sites.wall-90,"unfinished wall is not a new live line")
 sim.world.walls[id].pending=false
 t.equal(sim.core_loop.orders.position(sim,"wall"),sim.world.sites[id]-90,"finished outer wall receives the same defenders")
 sim.world.walls[id].hp=0
 t.equal(sim.core_loop.orders.position(sim,"wall"),sim.world.sites.wall-90,"destroyed outer wall falls back without a new order")
 t.equal(sim.core_loop.orders.targets[0],"wall","logical right-side assignment survives expansion and collapse")
 sim.world.walls.wall.pending=true
 t.equal(sim.defenses.work_bounds().y,sim.world.sites.hall+220,"no operational right wall uses the camp fallback")
func test_shield_blocks_a_front_hit_but_not_a_back_hit(t):
 for front: bool in [true,false]:
  var sim: RefCounted=fresh();var person: Dictionary=sim.world.people[0]
  person.role="guard";person.x=sim.world.sites.hall;person.direction=1.0
  person.cooldown=0.0 if front else 0.95
  var enemy: Dictionary=sim._spawn_raider();enemy.x=person.x+(24 if front else -24)
  enemy.windup=0.01;enemy.cooldown=1.5;enemy.target={"kind":"person","x":person.x,"index":0}
  sim.raiders.append(enemy)
  sim.advance(1.0/30.0,person.x+400)
  t.equal(person.role,"guard" if front else "wanderer","front shield blocks; exposed back still loses the job")
func test_sword_has_a_real_windup_before_damage(t):
 var sim: RefCounted=fresh();var person: Dictionary=sim.world.people[0]
 person.role="guard";person.x=sim.world.sites.hall;person.direction=1.0
 var enemy: Dictionary=sim._spawn_raider();enemy.x=person.x+60;enemy.cooldown=2.0
 sim.raiders.append(enemy)
 var hp: int=enemy.fighter.hp
 sim.advance(1.0/30.0,person.x+400)
 t.equal(enemy.fighter.hp,hp,"raising the sword does not instantly hurt the enemy")
 Fixture.new().ticks(sim,16,person.x+400)
 t.truth(enemy.fighter.hp<hp,"the actual cut deals damage after anticipation")
func test_max_camp_shows_no_false_price(t):
 var sim: RefCounted=fresh()
 var choice: Dictionary=sim.context_for_key(sim.world.sites.hall,"hall:3")
 t.equal(choice.cost,0,"completed camp no longer advertises an impossible upgrade price")
 t.truth(not choice.enabled and choice.reason=="defense.camp_max","maximum is explained directly")

func test_archers_follow_new_outer_tower_and_fall_back_without_payment(t):
 var sim: RefCounted=fresh();var orders: RefCounted=sim.core_loop.orders
 sim.buildings.core_tower_right.level=1
 t.truth(orders.assign(sim,"core_tower_right",1),"tower order starts with a real hunter")
 var outer: String=""
 for id: String in sim.buildings:
  if sim.buildings[id].kind=="tower" and sim.buildings[id].x>sim.world.sites.wall:outer=id;break
 t.truth(not outer.is_empty(),"fixture has an outer tower")
 if outer.is_empty():return
 var wall: String=""
 for id: String in sim.world.walls:
  if sim.world.sites[id]>sim.buildings[outer].x:wall=id;break
 t.truth(not wall.is_empty(),"fixture has an enclosing wall")
 if wall.is_empty():return
 sim.world.walls[wall].level=1;sim.world.walls[wall].hp=40
 sim.buildings[outer].level=1
 t.equal(orders.position(sim,"core_tower_right"),float(sim.buildings[outer].x),"same tower lane moves to the new outer tower")
 sim.buildings[outer].level=0;orders.clean(sim)
 t.equal(orders.position(sim,"core_tower_right"),float(sim.buildings.core_tower_right.x),"destroyed tower falls back to the inner tower")
 sim.buildings.core_tower_right.level=0;orders.clean(sim)
 t.equal(orders.targets[0],"wall","no tower releases the archer to the same side wall")
 t.equal(sim.pouch.amount,30,"automatic defense movement charges nothing")
func test_mid_swing_save_replays_the_same_hit_and_rejects_bad_rules(t):
 var config: Dictionary=preload("res://tests/test_demo_finale_save.gd").new().demo_config()
 var sim: RefCounted=preload("res://application/campaign_session.gd").new(config)
 sim.interact(sim.world.sites.hall,"hall")
 var person: Dictionary=sim.world.people[0];person.role="guard";person.x=sim.world.sites.hall+50;person.direction=1.0
 var enemy: Dictionary=sim._spawn_raider();enemy.x=person.x+60;enemy.cooldown=2;sim.raiders.append(enemy)
 Fixture.new().ticks(sim,5,person.x+400)
 var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
 var packet: Dictionary=codec.capture(sim,config,{"x":person.x+400,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not restored.is_empty(),"mid-swing checkpoint keeps the existing save shape")
 if restored.is_empty():return
 Fixture.new().ticks(sim,12,person.x+400);Fixture.new().ticks(restored.session,12,person.x+400)
 t.equal(restored.session.raiders[0].fighter.hp,sim.raiders[0].fighter.hp,"reload lands the same real sword hit")
 t.truth(is_equal_approx(restored.session.world.people[0].cooldown,sim.world.people[0].cooldown),"reload preserves the combat phase within JSON float precision")
 packet.config.defense_assignment_cost=-1
 t.truth(codec.restore(packet).is_empty(),"invalid assignment cost cannot create crystals")
func test_blocking_a_hit_does_not_dismiss_an_expedition_soldier(t):
 var sim: RefCounted=Fixture.new().forest()
 Fixture.new().people(sim,6)
 var at: float=sim.command.flag_x(1)
 Fixture.new().pay(sim,"rally:1",at,2)
 sim._hero_x=at
 var index: int=sim.command.squads[0].members[0]
 var person: Dictionary=sim.world.people[index];person.direction=1.0;person.cooldown=0
 t.truth(not sim.world.hit_person(index,person.x+20),"expedition shield blocks the frontal strike")
 sim.command.observe(sim)
 t.truth(sim.command.contains(index),"shield impact must not count as losing a soldier")
