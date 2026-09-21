extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Hold=preload("res://application/investment_hold.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")

func config() -> Dictionary:
 var rules: Dictionary=preload("res://data/campaign_tuning.gd").new().campaign_rules()
 rules.seed=741
 return rules

func test_contextual_press_drops_once_and_wanderer_collects_before_owner(t) -> void:
 var sim=Campaign.new(config())
 var hold=Hold.new()
 sim.world.people.resize(1)
 var person: Dictionary=sim.world.people[0]
 var initial: int=sim.pouch.amount
 t.truth(hold.step(0.016,true,true,sim,person.x-20),"E near a wanderer emits one physical crystal")
 t.equal(person.role,"wanderer","press does not instantly purchase the person")
 t.equal(sim.pouch.ground_total(),1,"the offering exists in the scene")
 hold.step(1,true,true,sim,person.x-20)
 t.equal(sim.pouch.amount,initial-1,"holding E cannot dump the whole pouch")
 for i in range(108):sim.advance(1.0/60,160)
 t.equal(person.role,"citizen","wanderer picks up the offered crystal during owner pickup grace")
 t.equal(sim.pouch.amount,initial-1,"the knight does not reclaim the recruitment offering")
 hold.step(0.016,false,true,sim,-450)
 hold.step(0.016,true,true,sim,-450)
 t.equal(sim.pouch.amount,initial-2,"a fresh press in empty land drops another crystal")

func test_offer_from_contextual_press_bribes_enemy_without_double_payment(t) -> void:
 var sim=Campaign.new(config())
 sim.world.people.clear()
 var hold=Hold.new()
 var enemy: Dictionary=sim._spawn_raider()
 enemy.x=-390;enemy.side=-1;enemy.exit_x=sim.mission.entry_x(-1)
 sim.raiders.append(enemy)
 hold.step(0.016,true,true,sim,-450)
 for i in range(90):sim.advance(1.0/60,-450)
 t.equal(enemy.get("carried_crystals",0),1,"enemy takes the physically dropped E offering")
 var before: float=enemy.x
 sim.advance(0.2,-450)
 t.truth(enemy.x < before,"bribed enemy turns toward its own portal")

func guide_of(sim: RefCounted, t: Object) -> RefCounted:
 var guide: Variant=sim.get("spirit")
 t.truth(guide!=null,"campaign owns persisted spirit lifecycle")
 return guide

func test_opening_finishes_after_first_worker_order_and_can_be_recalled(t) -> void:
 var sim=Campaign.new(config())
 var guide=guide_of(sim,t)
 if guide==null:return
 t.truth(not guide.advice(sim,30).is_empty(),"new journey starts with a guide")
 t.truth(not sim.context_for_key(guide.shrine_x(sim.world.sites.hall),"spirit").enabled,"unlit camp has no summoning facility")
 sim.interact(30,"hall")
 sim.world.people[0].role="engineer"
 var node=sim.frontier.nodes.filter(func(n):return n.kind=="tree")[0]
 sim.frontier.regions[node.region].discovered=true
 sim.interact(node.x,"node:%d"%sim.frontier.nodes.find(node))
 sim.advance(0.016,30)
 t.truth(guide.opening_finished,"first actual work order completes automatic guidance")
 for i in range(300):sim.advance(1.0/60,30)
 t.equal(guide.advice(sim,30),{},"ghost leaves after its farewell fade")
 var at: float=guide.shrine_x(sim.world.sites.hall)
 var wallet: int=sim.pouch.amount
 t.truth(sim.interact(at,"spirit"),"camp shrine recalls the guide for free")
 t.equal(sim.pouch.amount,wallet,"help never costs scarce crystals")
 t.truth(not guide.advice(sim,at).is_empty(),"recalled guide gives the next actual objective")
 t.truth(not sim.interact(at,"spirit"),"holding summon cannot extend an active visit")
 for i in range(1200):sim.advance(1.0/60,at)
 t.equal(guide.advice(sim,at),{},"summoned ghost leaves after a short visit")

func test_late_recall_survives_save_and_v8_migrates_safely(t) -> void:
 var rules: Dictionary=config()
 var sim=Campaign.new(rules)
 var guide=guide_of(sim,t)
 if guide==null:return
 sim.interact(30,"hall")
 sim.workforce.elapsed=170
 sim.advance(0.016,30)
 var at: float=guide.shrine_x(sim.world.sites.hall)
 t.truth(sim.interact(at,"spirit"),"help is available beyond the old 150 second limit")
 var codec=Codec.new()
 var body: Dictionary={"x":at,"y":430.0,"vx":0.0,"vy":0.0}
 var saved: Dictionary=codec.capture(sim,rules,body)
 var resumed: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
 t.truth(not resumed.is_empty(),"mid-visit state survives JSON save/load")
 if resumed.is_empty():return
 for i in range(40):
  sim.advance(1.0/60,at);resumed.session.advance(1.0/60,at)
 t.truth(Rules.same(codec.capture(sim,rules,body),codec.capture(resumed.session,rules,body)),"save/resume is identical to uninterrupted guidance")
 var legacy: Dictionary=saved.duplicate(true)
 legacy.version=8;legacy.erase("modules");legacy.erase("spirit")
 var migrated: Dictionary=codec.restore(legacy)
 t.truth(not migrated.is_empty(),"v8 save upgrades without losing progress")
 if not migrated.is_empty():
  t.equal(migrated.session.spirit.advice(migrated.session,at),{},"old completed opening is not replayed after upgrade")
  t.truth(migrated.session.interact(at,"spirit"),"old save can use the new shrine")
 var broken: Dictionary=saved.duplicate(true)
 broken.spirit.expires_tick=-1
 t.truth(codec.restore(broken).is_empty(),"corrupt guidance timer is rejected")
