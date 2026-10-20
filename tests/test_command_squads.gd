extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Fixture=preload("res://tests/test_sprint_hunting_feedback.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const STEP: float=1.0/30.0
func forest() -> RefCounted:
 var sim: RefCounted=Fixture.new().forest()
 sim.frontier.city_level=3;sim.core_loop.stage=5;sim.clock.survived=2;sim.clock.day=3
 for wall: Dictionary in sim.world.walls.values():wall.hp=0;wall.level=0;wall.pending=false
 for id: String in ["wall","wall_left"]:sim.world.walls[id].level=1;sim.world.walls[id].hp=sim.world.wall_max_hp(1)
 sim.pouch.amount=30
 return sim
func command(sim: RefCounted, t):
 var value: Variant=sim.get("command")
 t.truth(value!=null,"campaign has command and rescue subsystem")
 return value
func people(sim: RefCounted, count: int) -> void:
 while sim.world.people.size()<count:sim._add_person(sim.world.sites.hall,-1)
 for i: int in range(sim.world.people.size()):
  sim.world.people[i].role=["guard","guard","guard","hunter","hunter","engineer"][i%6]
  sim.world.people[i].x=sim.world.sites.wall+80
 sim.core_loop.orders.clean(sim)
func pay(sim: RefCounted, key: String, x: float, count: int) -> void:
 for i: int in range(count):sim.interact(x,key)
func ticks(sim: RefCounted, count: int, x: float) -> void:
 for i: int in range(count):sim.advance(STEP,x)
func test_rally_requires_three_roles_and_spends_only_for_complete_squads(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 var x: float=cmd.flag_x(1)
 sim.frontier.city_level=2
 t.truth(sim.context_for_key(x,"rally:1").id.is_empty(),"flags are locked before camp three")
 sim.frontier.city_level=3
 for person: Dictionary in sim.world.people:person.role="citizen"
 t.truth(not sim.interact(x,"rally:1"),"missing soldiers cannot consume crystals")
 t.equal(sim.pouch.amount,30,"missing roster spends nothing")
 people(sim,24)
 pay(sim,"rally:1",x,1)
 t.equal(cmd.squads.size(),0,"one crystal is only partial investment")
 pay(sim,"rally:1",x,1)
 t.equal(cmd.squads.size(),1,"two crystals rally exactly one company")
 t.equal(cmd.squads[0].members.size(),6,"six existing residents join")
 t.equal(sim.world.people.size(),24,"rally never invents population")
 pay(sim,"rally:1",x,4)
 t.equal(cmd.squads.size(),3,"maximum three companies")
 t.truth(not sim.interact(x,"rally:1"),"fourth company is unavailable")
 t.equal(sim.pouch.amount,24,"three companies cost six")
func test_tower_archers_stay_posted_and_squads_follow_then_disband(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 people(sim,18)
 sim.buildings.beacon.level=1
 sim.core_loop.orders.targets[3]="beacon"
 var x: float=cmd.flag_x(1)
 pay(sim,"rally:1",x,2)
 t.truth(not cmd.contains(3),"tower archer is not pulled off duty")
 var members: Array=cmd.squads[0].members.duplicate()
 ticks(sim,60,x+400)
 t.truth(sim.world.people[members[0]].x>sim.world.sites.wall+100,"swordsmen march after knight outside work bounds")
 ticks(sim,2,sim.world.sites.hall)
 t.equal(cmd.squads.size(),0,"entering the defended town dissolves all companies")
 t.equal(sim.core_loop.orders.targets[3],"beacon","tower assignment remains intact")
 t.equal(sim.world.people[members[0]].role,"guard","dismissed soldiers keep their profession")
func test_outer_flags_and_barracks_relocate_when_walls_fall(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 var old: float=cmd.flag_x(1);var barracks: float=cmd.barracks_x()
 var id: String=""
 for candidate: String in sim.defenses.plots:
  if sim.world.sites[candidate]>sim.world.sites.wall:id=candidate;break
 t.truth(not id.is_empty(),"fixture contains an outer wall")
 if id.is_empty():return
 sim.world.walls[id].level=1;sim.world.walls[id].hp=sim.world.wall_max_hp(1)
 t.truth(cmd.flag_x(1)>old and cmd.barracks_x()>barracks,"completed extension moves both fixtures outward")
 sim.world.walls[id].hp=0
 t.equal(cmd.flag_x(1),old,"destroyed outer wall returns the flag to surviving line")
 t.equal(cmd.barracks_x(),barracks,"barracks also returns to the surviving line")
func test_ship_repairs_for_six_and_produces_one_per_dawn_up_to_three(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 sim.frontier.city_level=2
 t.truth(not sim.interact(cmd.ship_x,"rescue_repair"),"wreck cannot be repaired below camp three")
 sim.frontier.city_level=3
 pay(sim,"rescue_repair",cmd.ship_x,5)
 t.truth(not cmd.repaired,"repair requires all six crystals")
 pay(sim,"rescue_repair",cmd.ship_x,1)
 t.truth(cmd.repaired,"sixth crystal repairs rescue ship")
 t.equal(cmd.waiting,0,"no immediate free resident")
 for day: int in range(4,8):
  sim.clock.day=day;sim.clock.survived=day-1;sim.advance(STEP,sim.world.sites.hall)
 t.equal(cmd.waiting,3,"daily arrivals stop at three")
 var population: int=sim.world.people.size();var money: int=sim.pouch.amount
 pay(sim,"rescue_recruit",cmd.ship_x,4)
 t.equal(cmd.waiting,2,"four crystals recruit one waiting passenger")
 t.equal(sim.world.people.size(),population+1,"one real resident joins")
 t.equal(sim.pouch.amount,money-4,"recruitment costs four crystals")
 t.equal(sim.world.people.back().role,"citizen","passenger joins without paying wanderer fee again")
 sim.advance(STEP,cmd.ship_x)
 t.equal(cmd.waiting,2,"same dawn cannot refill repeatedly")
func test_squad_and_ship_progress_survive_json_and_corruption_is_refused(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 people(sim,18);pay(sim,"rally:1",cmd.flag_x(1),2)
 pay(sim,"rescue_repair",cmd.ship_x,3)
 ticks(sim,30,cmd.flag_x(1)+300)
 var body: Dictionary={"x":cmd.flag_x(1)+300,"y":430.0,"vx":0.0,"vy":0.0}
 var codec: RefCounted=Codec.new()
 var packet: Dictionary=codec.capture(sim,Fixture.new().configuration(),body)
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not restored.is_empty(),"active company and partial repair restore: "+codec.last_error)
 if restored.is_empty():return
 var loaded: RefCounted=restored.session
 t.equal(loaded.command.squads.size(),1,"company membership is restored")
 t.equal(loaded.context_for_key(cmd.ship_x,"rescue_repair").paid,3,"half-funded repair is restored")
 ticks(sim,90,body.x+200);ticks(loaded,90,body.x+200)
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(codec.capture(loaded,restored.config,body),codec.capture(sim,restored.config,body)),"resumed company matches uninterrupted simulation")
 var broken: Dictionary=packet.duplicate(true);broken.command.squads[0].members[0]=999
 t.truth(codec.restore(broken).is_empty(),"invalid member reference rejected")
 broken=packet.duplicate(true);broken.command.waiting=4
 t.truth(codec.restore(broken).is_empty(),"overfilled ship rejected")
func test_legacy_v23_keeps_world_and_unlocks_unused_lessons(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 var codec: RefCounted=Codec.new();var config: Dictionary=Fixture.new().configuration()
 var packet: Dictionary=codec.capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
 packet.version=23;packet.erase("command")
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not restored.is_empty(),"old version 23 migrates safely")
 if restored.is_empty():return
 t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(restored.session.world.people,sim.world.people),"migration preserves residents")
 t.truth(not restored.session.command.repaired,"old saves do not receive free repairs or people")
func test_new_function_lessons_stop_after_actual_use(t):
 var sim: RefCounted=forest();var cmd=command(sim,t)
 if cmd==null:return
 var x: float=cmd.barracks_x()
 t.truth(not cmd.guidance(x).is_empty(),"camp three offers contextual guidance")
 pay(sim,"command_armory",x,sim.prices.armory)
 t.truth("barracks" in cmd.used,"buying sword-and-shield gear completes its lesson")
 t.truth(cmd.guidance(x).get("goal","")!="command.guide.barracks","used feature no longer repeats its tutorial")

func test_company_fights_and_worker_builds_near_knight(t):
 var sim: RefCounted=forest();var cmd: RefCounted=sim.command
 people(sim,6);pay(sim,"rally:1",cmd.flag_x(1),2)
 var x: float=cmd.flag_x(1)+550
 for index: int in cmd.squads[0].members:sim.world.people[index].x=x
 var enemy: Dictionary=sim._spawn_raider();enemy.x=x+65;sim.raiders.append(enemy)
 var hp: int=enemy.fighter.hp
 ticks(sim,1,x)
 t.truth(enemy.fighter.hp<hp,"company melee and bow attacks damage a real monster")
 var killed: Array=sim.raiders.filter(func(e: Dictionary)->bool:return not e.has("trail_slot"))
 for e: Dictionary in killed:e.fighter.hp=0
 var id: String=""
 for candidate: String in sim.world.walls:
  if sim.world.sites[candidate]>sim.world.sites.wall+300:id=candidate;break
 t.truth(not id.is_empty(),"an outer building site exists")
 if id.is_empty():return
 var at: float=sim.world.sites[id]
 sim.world.walls[id].pending=true
 sim.world.people[5].x=at-12
 ticks(sim,360,at-90)
 t.truth(sim.world.walls[id].level>0 and not sim.world.walls[id].pending,"the accompanying worker finishes nearby paid construction")
func test_squad_losses_do_not_duplicate_members_or_steal_archers(t):
 var sim: RefCounted=forest();var cmd: RefCounted=sim.command
 people(sim,6);pay(sim,"rally:1",cmd.flag_x(1),2)
 var victim: int=cmd.squads[0].members[0]
 sim.world.hit_person(victim);ticks(sim,1,cmd.flag_x(1)+200)
 t.truth(not cmd.contains(victim),"a demoted soldier leaves the company")
 t.equal(cmd.squads[0].members.size(),5,"loss does not silently create a replacement")
 t.truth(not sim.core_loop.orders.assign(sim,"wall",1),"squad archers cannot also be assigned to a wall")
func test_repair_and_recruit_tutorials_persist_across_worlds(t):
 var source: RefCounted=forest();var destination: RefCounted=forest()
 source.command.learn("rescue_repair");source.command.learn("rally")
 destination.command.learn("barracks")
 preload("res://application/planet_passenger.gd").carry(source,destination)
 t.truth("rescue_repair" in destination.command.used and "rally" in destination.command.used,"learned features travel with the knight")
 t.truth("barracks" in destination.command.used,"returning colony keeps its previous learned features")
 t.truth(not destination.command.repaired and destination.command.waiting==0,"tutorial knowledge does not transfer repairs or passengers")
func test_ship_remains_usable_after_ordinary_wild_population_cap(t):
 var sim: RefCounted=forest();var cmd: RefCounted=sim.command
 people(sim,24);pay(sim,"rescue_repair",cmd.ship_x,6)
 sim.clock.day+=1;sim.clock.survived+=1;ticks(sim,1,cmd.ship_x)
 pay(sim,"rescue_recruit",cmd.ship_x,4)
 t.equal(sim.world.people.size(),25,"ordinary ecology cap does not permanently disable ship recruitment")
 while sim.world.people.size()<40:sim._add_person(cmd.ship_x,-1)
 sim.clock.day+=1;sim.clock.survived+=1;ticks(sim,1,cmd.ship_x)
 var money: int=sim.pouch.amount
 t.truth(not sim.interact(cmd.ship_x,"rescue_recruit"),"hard population safety cap rejects new passengers")
 t.equal(sim.pouch.amount,money,"full town spends no crystals")
 t.equal(cmd.waiting,1,"full town preserves the waiting passenger")

func test_new_lessons_preserve_the_first_night_handover_and_read_actual_relics(t):
 var sim: RefCounted=forest()
 sim.core_loop.stage=3;sim.clock.remaining=sim.clock.day_seconds-2.0
 t.equal(sim.spirit.advice(sim,sim.command.barracks_x()).get("kind"),"rest","first-night preparation message completes before new features")
 sim.clock.remaining=sim.clock.day_seconds-30.0
 t.equal(sim.spirit.advice(sim,sim.command.barracks_x()).get("goal"),"command.guide.barracks","after handover the unlocked barracks is taught")
 for feature: String in preload("res://application/feature_lessons.gd").IDS:sim.command.learn(feature)
 sim.command.used.erase("ruin")
 var relic: RefCounted=sim.modules.relics[0]
 var hint: Dictionary=preload("res://application/feature_lessons.gd").next(sim,relic.x)
 t.equal(hint.get("goal"),"command.guide.ruin","a discovered untried relic offers a real object-backed lesson")

func test_missing_rally_is_not_masked_by_a_wandering_recruit(t):
 var sim: RefCounted=forest()
 var x: float=sim.command.flag_x(1)
 for person: Dictionary in sim.world.people:person.role="citizen"
 sim._add_person(x,-1)
 t.equal(sim.context(x).id,"rally","standing on the flag shows its actual missing roster")
 var money: int=sim.pouch.amount
 t.truth(not sim.interact(x),"generic interaction cannot spend on a hidden overlapping recruit")
 t.equal(sim.pouch.amount,money,"blocked rally preserves all crystals")

func test_new_barracks_equips_a_real_resident_and_rescue_survives_reload(t):
 var sim: RefCounted=forest()
 for person: Dictionary in sim.world.people:person.role="citizen"
 sim.world.people[0].x=sim.command.barracks_x()
 pay(sim,"command_armory",sim.command.barracks_x(),3)
 ticks(sim,1,sim.world.sites.hall)
 t.equal(sim.world.people[0].role,"guard","a citizen actually takes gear at the relocated barracks")
 t.equal(sim.world.tools.blade,0,"equipping consumes one real tool")
 pay(sim,"rescue_repair",sim.command.ship_x,6)
 sim.clock.day+=1;sim.clock.survived+=1;ticks(sim,1,sim.command.ship_x)
 var codec: RefCounted=Codec.new()
 var packet: Dictionary=codec.capture(sim,Fixture.new().configuration(),{"x":sim.command.ship_x,"y":430.0,"vx":0.0,"vy":0.0})
 var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not restored.is_empty(),"repaired ship and passenger restore from real JSON")
 if restored.is_empty():return
 var loaded: RefCounted=restored.session
 ticks(loaded,1,loaded.command.ship_x)
 t.equal(loaded.command.waiting,1,"reload cannot produce a duplicate passenger on the same day")
 loaded.clock.day+=1;loaded.clock.survived+=1;ticks(loaded,1,loaded.command.ship_x)
 t.equal(loaded.command.waiting,2,"the next true day adds exactly one after reload")
