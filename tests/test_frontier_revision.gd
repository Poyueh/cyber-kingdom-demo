extends RefCounted
const Fixture=preload("res://tests/test_command_squads.gd")
const Sites=preload("res://domain/building_sites.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
func fresh() -> RefCounted:
 var sim: RefCounted=Fixture.new().forest()
 sim.command.used.assign(preload("res://application/feature_lessons.gd").IDS)
 return sim
func test_occupied_or_funded_plots_cannot_take_a_second_building(t: Object) -> void:
 var sim: RefCounted=fresh()
 sim.buildings["overlap"]=Sites._site("tower",sim.world.sites.workshop,-1,-1)
 var choice: Dictionary=sim.building_context("overlap")
 var money: int=sim.pouch.amount
 t.truth(not choice.enabled,"an existing workshop reserves its ground against a new tower")
 t.truth(not sim.interact(choice.x,choice.key),"overlapping construction cannot accept payment")
 t.equal(sim.pouch.amount,money,"blocked construction preserves the wallet")
 var at: float=sim.world.sites.wall+460
 sim.buildings["first"]=Sites._site("tower",at,-1,-1)
 sim.buildings["second"]=Sites._site("farm",at,-1,-1)
 var first: Dictionary=sim.building_context("first")
 t.truth(sim.interact(at,first.key),"a clear plot accepts the first crystal")
 var second: Dictionary=sim.building_context("second")
 money=sim.pouch.amount
 t.truth(not sim.interact(at,second.key),"partially funded construction also reserves its footprint")
 t.equal(sim.pouch.amount,money,"reservation conflict never consumes another crystal")
 sim.investments.clear();sim.buildings.first.pending=true
 t.truth(not sim.building_context("second").enabled,"unfinished construction occupies its land")
 sim.buildings.first.pending=false;sim.buildings.first.level=1
 t.truth(not sim.building_context("second").enabled,"completed construction retains its land")
func test_squad_members_and_pending_rally_do_not_take_ground_crystals(t: Object) -> void:
 for partial: bool in [true,false]:
  var sim: RefCounted=fresh();Fixture.new().people(sim,6)
  var at: float=sim.command.flag_x(1)
  Fixture.new().pay(sim,"rally:1",at,1 if partial else 2)
  for person: Dictionary in sim.world.people:person.x=at+300
  sim.pouch.burst(3,at+300)
  for drop: Dictionary in sim.pouch.drops:drop.y=430;drop.vx=0;drop.vy=0;drop.grace=0;drop.age=1
  var total: int=sim.pouch.ground_total()
  sim.advance(1.0/30.0,at)
  t.equal(sim.pouch.ground_total(),total,"funded and assembled soldiers leave ground crystals for the knight")
  t.truth(sim.world.people.all(func(p: Dictionary)->bool:return int(p.get("crystals",0))==0),"company members cannot silently pocket crystal drops")
func test_both_barracks_are_distinct_inside_live_walls_and_clear_of_structures(t: Object) -> void:
 var sim: RefCounted=fresh()
 var posts: Array[Dictionary]=[]
 for x: int in range(-1000,1061,10):
  for c: Dictionary in sim.command.candidates(sim,x,430):
   if c.id=="sword_station" and not posts.any(func(p: Dictionary)->bool:return is_equal_approx(p.x,c.x)):posts.append(c)
 t.equal(posts.size(),2,"level three reveals one sword barracks on each side")
 for post: Dictionary in posts:
  t.truth(post.x>sim.command.edge(-1) and post.x<sim.command.edge(1),"each barracks stays inside the live city")
  for id: String in ["workshop","hunt_tools","farm_tools","farm","hall","beacon"]:
   t.truth(absf(post.x-sim.world.sites[id])>=100,"barracks do not overlap "+id)
func test_swordsmen_can_be_posted_at_barracks_but_never_on_towers(t: Object) -> void:
 var sim: RefCounted=fresh();Fixture.new().people(sim,6)
 var orders: RefCounted=sim.core_loop.orders
 t.truth(orders.has_method("guard_order"),"barracks exposes paid sword-defense commands")
 if not orders.has_method("guard_order"):return
 var at: float=sim.command.barracks_x(-1)
 t.truth(not orders.guard_order(sim,"sword_left",1,sim.world.sites.hall),"remote sword orders are refused")
 t.truth(orders.guard_order(sim,"sword_left",1,at),"local barracks posts a swordsman")
 t.equal(sim.pouch.amount,29,"sword posting follows the one-crystal rule")
 t.truth(not orders.guard_order(sim,"beacon",1,at),"a swordsman can never be ordered up a tower")
 var index: int=orders.targets.find("sword_left")
 t.truth(index>=0 and sim.world.people[index].role=="guard","the order selects a real swordsman")
 var post: float=orders.destination(sim,index)
 t.truth(post>sim.command.edge(-1) and post<sim.command.edge(-1)+100,"sword post is immediately inside the left wall")
 Fixture.new().ticks(sim,30,sim.world.sites.hall)
 t.equal(orders.targets[index],"sword_left","automatic side balancing does not erase the manual order")
 t.truth(not sim.command.roster(sim).has(index),"rally never steals a posted swordsman")
 t.truth(orders.guard_order(sim,"sword_left",-1,at),"releasing a sword post is free")
 t.equal(sim.pouch.amount,29,"free release preserves crystals")
func test_sword_orders_reload_and_stop_a_breach_without_retreating_first(t: Object) -> void:
 var sim: RefCounted=fresh();Fixture.new().people(sim,6)
 var orders: RefCounted=sim.core_loop.orders
 if not orders.has_method("guard_order"):t.truth(false,"guard orders required");return
 var at: float=sim.command.barracks_x(1)
 orders.guard_order(sim,"sword_right",1,at)
 var index: int=orders.targets.find("sword_right")
 sim.world.people[index].x=sim.command.edge(1)-28
 var enemy: Dictionary=sim._spawn_raider();enemy.x=sim.command.edge(1)+20;enemy.cooldown=10;enemy.fighter.hp=200;enemy.fighter.stats.max_hp=200;sim.raiders.append(enemy)
 var before: float=sim.world.people[index].x
 sim.world.walls.wall.hp=0
 Fixture.new().ticks(sim,18,sim.world.sites.hall)
 t.truth(enemy.fighter.hp<200,"the nearest shield soldier attacks the enemy at a broken wall")
 t.truth(sim.world.people[index].x>=before-5,"soldier blocks at the breach instead of retreating to the camp first")
 t.equal(float(sim.world.people[index].get("y",430)),430.0,"shield soldiers remain on the ground")
 var codec: RefCounted=Codec.new();var config: Dictionary=preload("res://tests/test_sprint_hunting_feedback.gd").new().configuration()
 var packet: Dictionary=codec.capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not loaded.is_empty(),"sword assignments restore from real JSON: "+codec.last_error)
 if loaded.is_empty():return
 t.equal(loaded.session.core_loop.orders.targets[index],"sword_right","saved side order survives reload")
 Fixture.new().ticks(sim,12,30);Fixture.new().ticks(loaded.session,12,30)
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(sim,config,packet.body),codec.capture(loaded.session,loaded.config,packet.body)),"continued sword defense matches the uninterrupted run")

func test_new_wall_cannot_replace_a_workshop_and_own_upgrade_is_allowed(t: Object) -> void:
 var sim: RefCounted=fresh()
 var plot: String=""
 for id: String in sim.world.walls:
  if id not in ["wall","wall_left"]:plot=id;break
 t.truth(not plot.is_empty(),"fixture contains an expansion wall")
 if plot.is_empty():return
 var other: String="blocked-wall-tower"
 sim.buildings[other]=Sites._site("tower",sim.world.sites[plot],-1,-1);sim.buildings[other].level=1
 var choice: Dictionary=sim.context_for_key(sim.world.sites[plot],sim._campaign_site(plot).key)
 var before: int=sim.pouch.amount
 t.truth(not choice.enabled,"a wall blueprint cannot be built into an existing tower")
 t.truth(not sim.interact(choice.x,choice.key),"blocked wall takes no crystal")
 t.equal(sim.pouch.amount,before,"blocked wall payment leaves the bag unchanged")
 sim.buildings.beacon.level=1
 t.truth(sim.building_context("beacon").enabled,"a tower can still upgrade on its own existing footprint")
func test_both_sword_lines_follow_expansion_and_hold_ground_level(t: Object) -> void:
 for side: int in [-1,1]:
  var sim: RefCounted=fresh();Fixture.new().people(sim,6)
  var target: String="sword_left" if side<0 else "sword_right"
  var orders: RefCounted=sim.core_loop.orders
  var initial: float=sim.command.barracks_x(side)
  t.truth(orders.guard_order(sim,target,1,initial),"either barracks accepts a real guard")
  var index: int=orders.targets.find(target)
  var old: float=orders.destination(sim,index)
  var outer: String=""
  for id: String in sim.defenses.plots:
   if sim.defenses.plots[id].side==side and side*(sim.world.sites[id]-sim.command.edge(side))>0:outer=id;break
  if outer.is_empty():t.truth(false,"outer wall exists on either side");continue
  sim.world.walls[outer].level=1;sim.world.walls[outer].hp=40
  t.truth(side*(orders.destination(sim,index)-old)>0,"the sword line advances with the finished wall")
  t.truth(side*(sim.command.barracks_x(side)-initial)>0,"the same-side barracks also moves to clear outer ground")
  sim.world.walls[outer].hp=0
  t.equal(orders.destination(sim,index),old,"without nearby foes the sword line falls back to the surviving wall")
  t.equal(orders.targets[index],target,"wall loss never drops the actual assignment")
  t.equal(sim.pouch.amount,29,"wall movement never charges a second command fee")
func test_ordinary_residents_still_collect_and_sword_tower_corruption_is_rejected(t: Object) -> void:
 var sim: RefCounted=fresh()
 for person: Dictionary in sim.world.people:person.role="citizen";person.x=sim.world.sites.hall+300
 sim.pouch.burst(2,sim.world.sites.hall+300)
 for drop: Dictionary in sim.pouch.drops:drop.y=430;drop.vx=0;drop.vy=0;drop.age=1;drop.grace=0
 sim.advance(1.0/30.0,sim.world.sites.hall)
 t.truth(sim.world.people.any(func(p: Dictionary)->bool:return p.get("crystals",0)>0),"ordinary residents retain the original crystal collection behavior")
 Fixture.new().people(sim,6)
 var config: Dictionary=preload("res://tests/test_sprint_hunting_feedback.gd").new().configuration()
 var codec: RefCounted=Codec.new();var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
 var packet: Dictionary=codec.capture(sim,config,body)
 packet.core_loop.orders[0]="beacon"
 t.truth(codec.restore(packet).is_empty(),"a forged tower assignment for a swordsman cannot load")
func test_old_guided_v24_saves_keep_their_world_and_both_barracks(t: Object) -> void:
 for edition: String in ["main","demo"]:
  var packet: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/guided-forest-v24-"+edition+".json"))
  if packet==null:continue
  var codec: RefCounted=Codec.new();var loaded: Dictionary=codec.restore(packet)
  t.truth(not loaded.is_empty(),"previous guided save restores: "+codec.last_error)
  if loaded.is_empty():continue
  t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(loaded.session.world.sites,packet.world.sites),"old building identities and coordinates remain unchanged")

func test_barracks_stock_button_is_atomic_when_the_game_is_paused(t: Object) -> void:
 var sim: RefCounted=fresh()
 var at: float=sim.command.barracks_x(-1)
 sim.pouch.amount=sim.prices.armory-1
 t.truth(not sim.command.stock_gear(sim,at),"insufficient crystals never start a partial panel purchase")
 t.equal(sim.pouch.amount,sim.prices.armory-1,"failed equipment purchase spends nothing")
 sim.pouch.amount=sim.prices.armory
 t.truth(sim.command.stock_gear(sim,at),"either barracks can stock its shared equipment rack")
 t.equal(sim.world.tools.blade,1,"one actual sword-and-shield tool is created")
 t.equal(sim.pouch.amount,0,"one equipment purchase uses its exact displayed cost")
 t.truth(sim.investments.is_empty(),"no loose payment is left for pause cancellation")

func test_legacy_unguided_campaign_keeps_usable_direct_barracks(t: Object) -> void:
 var sim: RefCounted=preload("res://application/campaign_session.gd").new({"immersive_loop":1})
 sim.frontier.city_level=3
 var at: float=sim.command.barracks_x(1)
 t.truth(not sim.core_loop.enabled,"fixture is an older unguided campaign")
 t.equal(sim.context(at).id,"command_armory","older campaigns never open a hidden core-only panel")
