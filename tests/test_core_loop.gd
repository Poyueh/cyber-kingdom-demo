extends SceneTree
const Campaign=preload("res://application/campaign_session.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
var failures: int=0
var assertions: int=0
func check(value: bool, message: String) -> void:
 assertions+=1
 if not value:failures+=1;print("FAIL: "+message)
 else:print("PASS: "+message)
func configuration() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var config: Dictionary=tuning.campaign_rules()
 config.merge({"seed":1054,"economy":tuning.economy_rules()},true)
 return load("res://data/core_loop.tres").resolve(config)
func _initialize() -> void:
 var config: Dictionary=configuration()
 var bad: Dictionary=config.duplicate(true);bad.core_loop_version=99
 check(not Rules.config_valid(bad),"unknown core mode cannot be loaded as an ordinary journey")
 var sim: RefCounted=Campaign.new(config)
 sim.advance(310.0,sim.world.sites.hall)
 check(not sim.clock.is_night and sim.clock.day==1,"first preparation has no deadline before actual readiness")
 sim.hero.stamina=0
 check(sim.hero.stats.attack_cost==0,"core knight can attack at zero stamina")
 var axis: float=sim.travel_axis(1.0,1.0/30)
 check(axis>=1.0,"exhausted core knight keeps normal running instead of compulsory stop")
 check(Rules.config_valid(config),"resolved core trial configuration is save-admissible")
 var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
 var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
 var packet: Dictionary=codec.capture(sim,config,body)
 var copy: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 check(not copy.is_empty(),"core mode and state survive actual JSON save/load")
 var legacy: Dictionary=config.duplicate(true)
 for key: String in legacy.keys():
  if key.begins_with("core_") and key not in ["core_max_hp","core_recharge"]:legacy.erase(key)
 var old: RefCounted=Campaign.new(legacy)
 var old_packet: Dictionary=codec.capture(old,legacy,body)
 old_packet.erase("core_loop");old_packet.version=21
 check(not codec.restore(old_packet).is_empty(),"v21 journey migrates without adopting core trial rules")
 run_flow()
 print("Core loop: %d assertions, %d failures"%[assertions,failures])
 quit(1 if failures else 0)

func ticks(sim: RefCounted, count: int, at: float) -> void:
 for i: int in range(count):sim.advance(1.0/30.0,at)
func pay(sim: RefCounted, at: float, key: String, count: int) -> void:
 for i: int in range(count):check(sim.interact(at,key),"valid paid action: "+key)
func run_flow() -> void:
 var config: Dictionary=configuration()
 var sim: RefCounted=Campaign.new(config)
 var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
 var points: Script=load("res://application/core_checkpoints.gd")
 var body: Dictionary={"x":420.0,"y":430.0,"vx":0.0,"vy":0.0}
 pay(sim,sim.world.sites.hall,"hall",1)
 pay(sim,sim.world.people[0].x,"recruit:0",1)
 pay(sim,sim.world.sites.workshop,"workshop",2)
 ticks(sim,450,sim.world.sites.workshop)
 check(sim.world.people.any(func(p: Dictionary)->bool:return p.role=="engineer"),"recruited resident actually equips the hammer")
 check(not sim.site_visible("hunt_tools"),"defence service stays closed before real harvest income")
 var tree: RefCounted=sim.frontier.nodes[3]
 pay(sim,tree.x,"node:3",1)
 ticks(sim,700,tree.x)
 check(sim.core_loop.income>0 and sim.core_loop.stage==1,"real harvested crystals reach wallet and unlock preparation")
 check(points.capture_pending(sim,config,body,codec),"CP1 captures before major defence investment")
 var saved_money: int=sim.pouch.amount
 var next_tree: RefCounted=sim.frontier.nodes[2]
 pay(sim,next_tree.x,"node:2",1)
 ticks(sim,1200,next_tree.x)
 pay(sim,sim.world.people[1].x,"recruit:1",1)
 pay(sim,sim.world.sites.hunt_tools,"hunt_tools",3)
 var wall_choice: Dictionary=sim.context_for_key(sim.world.sites.wall,"wall:0:false")
 pay(sim,sim.world.sites.wall,wall_choice.key,3)
 ticks(sim,1200,sim.world.sites.hall)
 check(sim.world.walls.wall.hp>0 and not sim.world.walls.wall.pending,"paid wall is actually constructed")
 check(not sim.clock.is_night,"unassigned guards cannot prematurely start first night")
 var before: int=sim.pouch.amount
 check(sim.core_loop.orders.assign(sim,"wall",1),"an available archer accepts right-side assignment")
 check(sim.pouch.amount==before,"assignment costs no crystals")
 ticks(sim,900,sim.world.sites.hall)
 check(sim.core_loop.stage==2,"arrival of real defender opens first dusk once")
 for i: int in range(6000):
  ticks(sim,1,sim.world.sites.hall)
  if sim.core_loop.stage==3:break
 check(sim.clock.survived==1 and sim.mission.outcome=="active","baseline guard and wall survive first night without knight attacks")
 check(sim.core_loop.stage==3 and sim.core_loop.checkpoint_pending==2,"first wave finishes before autonomous phase and CP2")
 var rewind: Dictionary=points.retry(sim,codec)
 check(not rewind.is_empty(),"CP1 can be restored after actual combat")
 if not rewind.is_empty():
  check(rewind.session.pouch.amount==saved_money,"retry restores original funds without retaining later harvests")
  check(rewind.session.world.walls.wall.level==0,"retry restores investment choices instead of spent night-start state")
 check(points.capture_pending(sim,config,body,codec),"CP2 captures autonomous preparation")
 var packet: Dictionary=codec.capture(sim,config,body)
 var corrupt: Dictionary=packet.duplicate(true)
 corrupt.core_loop.checkpoint.core_loop.stage=5
 check(codec.restore(corrupt).is_empty(),"corrupt preparation stage is rejected without replacing the run")
 corrupt=packet.duplicate(true);corrupt.core_loop.orders=["beacon","beacon"]
 check(codec.restore(corrupt).is_empty(),"duplicated tower assignments are rejected")
 second_route(packet,true)
 second_route(packet,false)
 var resumed: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 check(not resumed.is_empty(),"world and embedded preparation point survive JSON restart")
 if not resumed.is_empty():
  ticks(sim,30,sim.world.sites.hall);ticks(resumed.session,30,sim.world.sites.hall)
  check(Rules.same(codec.capture(sim,config,body),codec.capture(resumed.session,resumed.config,body)),"saved continuation matches uninterrupted core simulation")

func second_route(source: Dictionary, explore: bool) -> void:
 var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
 var restored: Dictionary=codec.restore(source)
 check(not restored.is_empty(),"autonomous route restores preparation")
 if restored.is_empty():return
 var sim: RefCounted=restored.session
 sim.core_loop.skipped=true
 if explore:
  var quiet: RefCounted=sim.trails.sites[1]
  ticks(sim,30,quiet.x)
  var choice: Dictionary=sim.context(quiet.x)
  check(choice.id=="trail_cache" and sim.interact(quiet.x,choice.key),"quiet landmark gives a real exploration reward")
  ticks(sim,90,quiet.x)
 else:
  for index: int in [1,4]:
   var node: RefCounted=sim.frontier.nodes[index]
   pay(sim,node.x,"node:%d"%index,1)
   var before: int=sim.pouch.amount
   var recruited: int=sim.world.people.filter(func(p: Dictionary)->bool:return p.role!="wanderer").size()
   var income: int=0
   for tick: int in range(2400):
    ticks(sim,1,node.x)
    var newcomers: int=sim.world.people.filter(func(p: Dictionary)->bool:return p.role!="wanderer").size()-recruited
    income=sim.pouch.amount-before+newcomers*sim.prices.recruit
    if income>=node.crystals:break
   check(income>=node.crystals,"harvest arrives as crystals or a nearby recruited resident")
 var recruit: int=-1
 for i: int in range(sim.world.people.size()):
  if sim.world.people[i].role=="wanderer":recruit=i;break
 check(recruit>=0,"autonomous route still has a recruit")
 if recruit<0:return
 pay(sim,sim.world.people[recruit].x,"recruit:%d"%recruit,1)
 pay(sim,sim.world.sites.hunt_tools,"hunt_tools",3)
 var wall: Dictionary=sim.context(sim.world.sites.wall_left)
 check(wall.id=="wall_left","opposite front has a usable wall site")
 pay(sim,sim.world.sites.wall_left,wall.key,3)
 ticks(sim,1000,sim.world.sites.hall)
 check(sim.core_loop.orders.assign(sim,"wall_left",1),"second guard can defend opposite side")
 for tick: int in range(12000):
  ticks(sim,1,sim.world.sites.hall)
  if sim.core_loop.stage==5:break
 check(sim.core_loop.stage==5 and sim.mission.outcome=="active","two-sided second night completes through "+("exploration" if explore else "additional harvests"))
 verify_completion(sim,restored.config,codec)

func verify_completion(sim: RefCounted, _config: Dictionary, codec: RefCounted) -> void:
 check(sim.finished() and not sim.is_running(),"core completion stops simulation without seven-world victory")
 var retry: Dictionary=load("res://application/core_checkpoints.gd").retry(sim,codec)
 check(not retry.is_empty() and retry.session.core_loop.stage==3,"completed run retries from second preparation")
