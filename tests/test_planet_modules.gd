extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
const Passenger=preload("res://application/planet_passenger.gd")
const BODY={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
func config(planet: int=0) -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var value: Dictionary=tuning.campaign_rules();value.seed=73;value.economy=tuning.economy_rules()
 value.planet_id=planet;value.day_seconds=1000.0
 return value
func fresh(planet: int=0) -> RefCounted:
 var sim: RefCounted=Campaign.new(config(planet));sim.interact(30,"hall");sim.world.people.clear()
 return sim
func available(sim: RefCounted, t: SceneTree) -> bool:
 var result: bool=sim.modules.has_method("spec_for")
 t.truth(result,"planet modules expose typed ability definitions")
 return result
func equip(sim: RefCounted, id: String) -> void:
 sim.modules.found.append(id);sim.modules.stored.append(id);sim.modules.equipped=id
 for site: RefCounted in sim.trials.sites:
  if site.id==id:site.progress=3
func enemy(sim: RefCounted, x: float, kind: String="") -> Dictionary:
 var value: Dictionary=sim._spawn_raider();value.x=x;value.kind=kind;sim.raiders.append(value)
 return value
func person(sim: RefCounted, x: float, role: String) -> Dictionary:
 var value: Dictionary={"x":x,"role":role,"hurt":0.0,"cooldown":0.0,"region":-1}
 sim.world.people.append(value);return value
func test_seven_worlds_reward_eight_non_repeating_playstyles(t: SceneTree) -> void:
 var found: Array[String]=[]
 for planet: int in range(7):
  var a: RefCounted=fresh(planet);var b: RefCounted=fresh(planet)
  t.equal(a.modules.relics.size(),2 if planet==0 else 1,"each destination has its intended unique discoveries")
  for i: int in range(a.modules.relics.size()):
   var relic: RefCounted=a.modules.relics[i]
   t.truth(not found.has(relic.id),"new world never repeats an already granted relic")
   found.append(relic.id)
   t.equal(relic.x,b.modules.relics[i].x,"same seed keeps the reward location")
   t.truth(absf(relic.x)>2000,"new abilities require real exploration")
 t.equal(found.size(),8,"all eight abilities have a reachable world source")
func test_magnet_retrieves_only_existing_eligible_crystals(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"magnet");sim.pouch.amount=20
 sim.pouch.drop(9,200);sim.pouch.toss(30,430,-1)
 var total: int=sim.pouch.amount+sim.pouch.ground_total()
 t.truth(sim.activate_module(30),"magnet activates on a ground pile outside normal pickup radius")
 t.equal(sim.hero.stamina,85.0,"magnet pays its own stamina cost")
 for i: int in range(24):sim.advance(1.0/30,30)
 t.equal(sim.pouch.amount,24,"at most five existing crystals enter the bag; thrown offering remains protected")
 t.equal(sim.pouch.amount+sim.pouch.ground_total(),total,"ability never creates or deletes crystals")
 sim.modules.ready_tick=0;sim.pouch.amount=30
 var stamina: float=sim.hero.stamina
 t.truth(not sim.activate_module(30),"full bag rejects magnetic pulse")
 t.equal(sim.hero.stamina,stamina,"rejected support never consumes stamina")
 t.equal(sim.modules.ready_tick,0,"rejected support never starts cooldown")
func test_frost_slows_movement_but_not_attack_timers(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"frost")
 var target: Dictionary=enemy(sim,180)
 var outside: Dictionary=enemy(sim,250)
 var behind: Dictionary=enemy(sim,-100)
 var hp: int=target.fighter.hp
 t.truth(sim.activate_module(30),"cold cone fires")
 t.equal(target.fighter.hp,hp-12,"cold cone deals configured damage")
 t.equal(outside.fighter.hp,hp,"distant enemy escapes cone")
 t.equal(behind.fighter.hp,hp,"enemy behind knight escapes cone")
 var a: float=target.x;var b: float=outside.x
 sim.advance(1.0/30,30)
 t.truth(absf(target.x-a)<absf(outside.x-b)*0.7,"chilled enemy actually advances more slowly")
 target.x=50;target.windup=0.2;target.target={"kind":"hero","x":30.0}
 sim.advance(0.1,30)
 t.truth(absf(target.windup-0.1)<0.0001,"chill leaves attack windup at normal speed")
func test_gravity_cannot_pull_through_walls_or_move_heavy_enemies(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"gravity");sim.world.sites.wall=150;sim.world.walls.wall.level=1;sim.world.walls.wall.hp=100
 var target: Dictionary=enemy(sim,170)
 var heavy: Dictionary=enemy(sim,160,"warden")
 t.truth(sim.activate_module(30),"gravity fires into cluster")
 t.truth(target.x>=150,"pull stays on original side of operational wall")
 t.equal(heavy.x,160.0,"heavy guardian takes damage without teleporting")
 t.equal(heavy.fighter.hp,heavy.fighter.stats.max_hp-10,"heavy guardian still takes the small impact")
func test_command_marks_three_archers_for_one_real_arrow_each(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"command")
 var archers: Array[Dictionary]=[]
 for i: int in range(4):archers.append(person(sim,30+i*5,"hunter"))
 person(sim,30,"guard")
 t.truth(sim.activate_module(30),"nearby archers receive command pulse")
 var target: Dictionary=enemy(sim,160);target.fighter.stats.hurt_invulnerability=0
 target.fighter.stats.max_hp=500;target.fighter.hp=500
 var before: int=target.fighter.hp
 sim.advance(1.0/30,30)
 t.equal(before-target.fighter.hp,4*sim.archer_damage()+3*8,"only three next arrows gain damage")
 for archer: Dictionary in archers:archer.cooldown=0
 target.fighter.hp=target.fighter.stats.max_hp;before=target.fighter.hp
 sim.advance(1.0/30,30)
 t.equal(before-target.fighter.hp,4*sim.archer_damage(),"mark is consumed by shooting, never a permanent boost")
func test_workshop_advances_paid_building_without_instant_defense(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"workshop")
 var at: float=sim.world.sites.wall
 var worker: Dictionary=person(sim,at-12,"engineer")
 sim.world.walls.wall.pending=true;sim.world.walls.wall.level=1;sim.world.walls.wall.hp=100
 var base: RefCounted=fresh();person(base,at-12,"engineer")
 base.world.walls.wall.pending=true;base.world.walls.wall.level=1;base.world.walls.wall.hp=100
 t.truth(sim.activate_module(at-12),"engineer can receive a work pulse")
 var crystals: int=sim.pouch.amount
 sim.advance(0.1,at-12);base.advance(0.1,at-12)
 t.truth(absf(sim.world.walls.wall.progress-base.world.walls.wall.progress*1.5)<0.00001,"paid construction progresses fifty percent faster")
 t.truth(not sim.world.wall_operational("wall"),"unfinished upgrade remains unable to defend")
 t.equal(sim.pouch.amount,crystals,"support manufactures no currency")
 worker.role="wanderer"
 var progress: float=sim.world.walls.wall.progress
 sim.advance(0.1,at-12)
 t.equal(sim.world.walls.wall.progress,progress,"losing profession prevents ghost construction")
func test_support_without_targets_is_free_and_charge_preserves_exhaustion(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 for id: String in ["command","workshop","magnet"]:
  equip(sim,id)
  t.truth(not sim.activate_module(30),"support without legal targets is refused: "+id)
  t.equal(sim.modules.ready_tick,0,"empty support does not lock other abilities")
  t.equal(sim.hero.stamina,100.0,"empty support preserves stamina")
 equip(sim,"capacitor")
 t.truth(not sim.activate_module(30),"full stamina rejects capacitor")
 sim.hero.stamina=20;sim.hero.stats.stamina_regen=0
 t.truth(sim.activate_module(30),"low stamina begins gradual recharge")
 sim.travel.exhausted=true;sim.travel.winded=true;sim.travel.breath_ticks=60
 sim.advance(1.0,30)
 t.truth(absf(sim.hero.stamina-30.0)<0.001,"charge supplies energy gradually rather than instantly")
 t.truth(sim.travel.exhausted and sim.travel.breath_ticks>0,"energy does not bypass forced breathing")
 sim.modules.equipped="arc"
 t.truth(not sim.activate_module(30),"changing equipment cannot bypass recharge cooldown")
func test_mid_effect_save_and_world_travel_preserve_remaining_charge(t: SceneTree) -> void:
 var sim: RefCounted=fresh()
 if not available(sim,t):return
 equip(sim,"capacitor");sim.hero.stamina=20
 sim.activate_module(30)
 for i: int in range(17):sim.advance(1.0/30,30)
 var codec: RefCounted=Codec.new()
 var saved: Dictionary=codec.capture(sim,config(),BODY)
 var copy: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not copy.is_empty(),"charging knight can save and load")
 if copy.is_empty():return
 for i: int in range(70):sim.advance(1.0/30,30);copy.session.advance(1.0/30,30)
 t.truth(Rules.same(codec.capture(sim,config(),BODY),codec.capture(copy.session,config(),BODY)),"continuous and resumed effects produce the same state")
 var destination: RefCounted=fresh(3)
 Passenger.carry(sim,destination)
 t.equal(destination.modules.equipped,"capacitor","discovered module travels to another planet")
 t.truth(not destination.activate_module(30),"arrival cannot clear the shared cooldown")
 t.truth(not codec.restore(codec.capture(destination,config(3),BODY)).is_empty(),"foreign module ownership is valid on the new planet")
func test_v16_upgrade_retains_inventory_and_rejects_unknown_charge(t: SceneTree) -> void:
 var old_config: Dictionary={"seed":42,"immersive_loop":1}
 var sim: RefCounted=Campaign.new(old_config);sim.interact(30,"hall");equip(sim,"arc")
 var codec: RefCounted=Codec.new();var packet: Dictionary=codec.capture(sim,old_config,BODY)
 packet.version=16;packet.modules.erase("charge_ticks");packet.modules.erase("charge_last_tick")
 var loaded: Dictionary=codec.restore(packet)
 t.truth(not loaded.is_empty(),"genuine v16 module shape upgrades without replacing the journey")
 if loaded.is_empty():return
 t.equal(loaded.session.modules.equipped,"arc","existing knight keeps their selected module")
 t.equal(loaded.session.modules.relics.size(),2,"legacy world retains its original reward layout")
 packet.version=17;packet.modules.charge_ticks=99999;packet.modules.charge_last_tick=0
 t.truth(codec.restore(packet).is_empty(),"impossible charge cannot enter a saved game")
func test_short_effects_survive_loading_expire_and_reject_corruption(t: SceneTree) -> void:
 var codec: RefCounted=Codec.new()
 for id: String in ["frost","command","workshop","magnet"]:
  var sim: RefCounted=fresh();equip(sim,id)
  var at: float=30.0
  if id=="frost":enemy(sim,160)
  elif id=="command":person(sim,35,"hunter")
  elif id=="workshop":
   at=sim.world.sites.wall-12;person(sim,at,"engineer");sim.world.walls.wall.pending=true
  else:sim.pouch.drop(3,200)
  t.truth(sim.activate_module(at),"real short effect activates: "+id)
  sim.advance(0.1,at)
  var body: Dictionary={"x":at,"y":430.0,"vx":0.0,"vy":0.0}
  var saved: Dictionary=codec.capture(sim,config(),body)
  var copy: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
  t.truth(not copy.is_empty(),"mid-effect checkpoint loads: "+id)
  if copy.is_empty():continue
  for i: int in range(130):sim.advance(1.0/30,at);copy.session.advance(1.0/30,at)
  t.truth(Rules.same(codec.capture(sim,config(),body),codec.capture(copy.session,config(),body)),"effect expires identically after resume: "+id)
  if id=="frost":saved.raiders[0].state.module_chill_until=999999
  elif id=="command":saved.world.people[0].module_command_until=999999
  elif id=="workshop":saved.world.people[0].module_workshop_until=999999
  else:saved.pouch.drops[0].pull_until_age=999999
  t.truth(codec.restore(saved).is_empty(),"unbounded effect cannot be loaded: "+id)
func test_charge_travels_mid_pulse_without_refilling_or_disappearing(t: SceneTree) -> void:
 var sim: RefCounted=fresh();equip(sim,"capacitor");sim.hero.stamina=5
 sim.activate_module(30)
 for i: int in range(20):sim.advance(1.0/30,30)
 var destination: RefCounted=fresh(1);destination.workforce.elapsed=800.0
 Passenger.carry(sim,destination)
 t.equal(sim.modules.charge_ticks,destination.modules.charge_ticks,"travel preserves remaining recharge ticks")
 for i: int in range(70):sim.advance(1.0/30,30);destination.advance(1.0/30,30)
 t.truth(absf(sim.hero.stamina-destination.hero.stamina)<0.00001,"different planet clock cannot duplicate or erase energy")
 t.equal(destination.modules.charge_ticks,0,"charge actually finishes after remaining time")
func test_workshop_needs_paid_work_and_refuses_workers_in_danger(t: SceneTree) -> void:
 var sim: RefCounted=fresh();equip(sim,"workshop");person(sim,30,"engineer")
 t.truth(not sim.activate_module(30),"idle workers alone do not waste a construction charge")
 sim.world.walls.wall.pending=true;enemy(sim,60)
 t.truth(not sim.activate_module(30),"worker under immediate threat cannot be forced to build")
 t.equal(sim.hero.stamina,100.0,"rejected unsafe support is free")
func test_catalogue_rewards_remain_accessible_across_seeds(t: SceneTree) -> void:
 for seed_value: int in range(32):
  for planet: int in range(7):
   var rules: Dictionary=config(planet);rules.seed=seed_value
   var sim: RefCounted=Campaign.new(rules)
   t.equal(sim.modules.relics.size(),2 if planet==0 else 1,"seeded geography retains every planet reward")
   for relic: RefCounted in sim.modules.relics:
    var trial: RefCounted=sim.trials.get_site(relic.id)
    t.truth(trial!=null,"reward has a playable free mechanism")
    if trial==null:continue
    if trial.mechanism==null:
     for station: int in trial.order:sim.trials.activate(trial.id,station,0)
    else:preload("res://tests/ruin_solution.gd").solve(sim,planet)
    sim.frontier.regions[relic.region].discovered=true;sim.modules.observe(sim,relic.x,430)
    t.equal(sim.modules.equipped,relic.id,"configured mechanism can unlock and auto-equip this seed's reward")

func test_rocket_construction_can_save_while_support_is_active(t: SceneTree) -> void:
 var rules: Dictionary=config();rules.voyage_enabled=1
 var sim: RefCounted=Campaign.new(rules);sim.interact(30,"hall");sim.world.people.clear();equip(sim,"workshop")
 var at: float=preload("res://application/planet_operations.gd").rocket_x(sim)
 person(sim,at,"engineer");sim.planet.reactor=true;sim.planet.rocket_pending=true
 t.truth(sim.activate_module(at),"paid rocket crew can receive construction support")
 sim.advance(0.1,at)
 t.truth(sim.planet.work>0.1,"actual rocket construction receives the same work modifier")
 var body: Dictionary={"x":at,"y":430.0,"vx":0.0,"vy":0.0}
 var codec: RefCounted=Codec.new()
 t.truth(not codec.restore(codec.capture(sim,rules,body)).is_empty(),"active rocket work remains a valid serializable resident state")
