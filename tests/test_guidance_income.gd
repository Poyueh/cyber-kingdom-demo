extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Guide=preload("res://application/campaign_guide.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")

func config() -> Dictionary:
 var tuning: Resource=load("res://data/campaign.tres")
 var result: Dictionary=tuning.campaign_rules()
 result.merge({"seed":42,"economy":tuning.economy_rules(),"day_seconds":1000.0},true)
 return result

func test_guidance_leads_to_actual_worker_income_and_nearby_delivery(t: SceneTree) -> void:
 var rules: Dictionary=config()
 var sim: RefCounted=Campaign.new(rules)
 sim.interact(sim.world.sites.hall,"hall")
 sim.world.people.resize(1)
 var worker: Dictionary=sim.world.people[0]
 worker.role="engineer"
 var tree: RefCounted=null
 for node: RefCounted in sim.frontier.nodes:
  if node.kind=="tree" and sim.work_area.contains(node.x):tree=node;break
 t.truth(tree!=null,"fixture has a commissionable tree")
 if tree==null:return
 sim.frontier.regions[tree.region].discovered=true
 worker.x=tree.x-22
 t.truth(sim.interact(tree.x,"node:%d"%sim.frontier.nodes.find(tree)),"actual harvest order is funded")
 for tick: int in range(300):
  sim.advance(1.0/30,sim.world.sites.hall)
  if tree.delivered:break
 t.equal(worker.get("crystals",0),tree.crystals,"completed harvest remains with the worker")
 sim.pouch.amount=0
 var codec: RefCounted=Codec.new()
 var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
 var before: Dictionary=codec.capture(sim,rules,body)
 var hint: Dictionary=Guide.funding_hint(sim,sim.world.sites.hall)
 t.equal(hint.get("kind"),"resident_income","empty knight is directed to earned income before unknown territory")
 t.equal(hint.get("x"),worker.x,"advice follows the real carrier")
 t.truth(Rules.same(before,codec.capture(sim,rules,body)),"query never changes money, discovery, timers or RNG")
 sim.advance(1.0/30,worker.x)
 t.equal(worker.get("crystals",0),0,"approaching causes the real resident offering")
 t.equal(sim.pouch.ground_total(),tree.crystals,"harvest leaves resident as physical crystals")

func test_advice_uses_remaining_price_instead_of_repeated_unaffordable_orders(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config())
 sim.interact(sim.world.sites.hall,"hall")
 sim.world.people[0].role="engineer";sim.world.people[0]["crystals"]=4
 sim.world.people[1].role="citizen"
 sim.frontier.nodes.filter(func(n: RefCounted) -> bool:return n.kind=="tree")[0].marked=true
 sim.pouch.amount=1
 t.equal(Guide.next(sim,30).get("kind"),"resident_income","one crystal cannot finish a three-crystal bow; first collect known income")
 sim.pouch.amount=3
 var at: float=sim.world.sites.hunt_tools
 t.truth(sim.interact(at,"hunt_tools") and sim.interact(at,"hunt_tools"),"two real crystals fill two bow slots")
 t.equal(sim.pouch.amount,1,"only the final bow crystal remains in pouch")
 t.equal(Guide.next(sim,at).get("key"),"hunt_tools","already filled slots count toward affordability")
 sim.clock.survived=1
 sim.investments.clear()
 var expedition: Script=preload("res://application/expedition_guide.gd")
 t.equal(expedition.next(sim,30).get("kind"),"resident_income","later camp upgrades use the same supply advice")

func test_free_unlit_camp_is_still_the_priority_without_crystals(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config())
 sim.pouch.amount=0
 t.equal(Guide.next(sim,-1020).get("kind"),"camp","free sword and fire do not require searching for money")
 sim.clock.is_night=true
 t.equal(Guide.next(sim,-1020).get("kind"),"camp","unarmed knight is guided to the unlit fire even after dusk")
 sim.clock.survived=1
 t.equal(preload("res://application/expedition_guide.gd").next(sim,-1020).get("kind"),"camp","late arrival still knows the free first step")

func test_funded_work_and_trader_return_are_distinguished_from_ready_income(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config())
 sim.interact(30,"hall")
 var worker: Dictionary=sim.world.people[0];worker.role="engineer"
 var tree: RefCounted=null
 for node: RefCounted in sim.frontier.nodes:
  if node.kind=="tree" and sim.work_area.contains(node.x):tree=node;break
 if tree==null:t.truth(false,"known payable tree required");return
 sim.frontier.regions[tree.region].discovered=true
 sim.interact(tree.x,"node:%d"%sim.frontier.nodes.find(tree))
 sim.advance(1.0/30,30)
 sim.pouch.amount=0
 t.equal(Guide.funding_hint(sim,30).get("kind"),"work_income","already paid harvest is a source before blind exploration")
 tree.marked=false;tree.worker=-1
 sim.merchant.phase=sim.merchant.Phase.RETURNING
 sim.merchant.return_day=sim.clock.day
 sim.merchant.x=sim.merchant.home_x+500
 var hint: Dictionary=Guide.funding_hint(sim,30)
 t.equal(hint.get("kind"),"merchant_return","returning trader is not described as ready to hand over money")
 t.equal(hint.get("x"),sim.merchant.home_x,"wait at the known camp delivery point instead of chasing the caravan")
 sim.merchant.phase=sim.merchant.Phase.AWAY
 sim.merchant.return_day=sim.clock.day+1
 t.equal(Guide.funding_hint(sim,30).get("kind"),"merchant_wait","funded next-day delivery is distinguished from immediate cash")

func test_visible_gift_does_not_send_knight_away_during_collection_grace(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config())
 sim.pouch.amount=0
 sim.pouch.burst(2,30)
 var hint: Dictionary=Guide.funding_hint(sim,30)
 t.equal(hint.get("kind"),"collect","visible incoming crystals keep the collection hint while pickup grace is running")
 t.equal(sim.pouch.amount,0,"advice does not bypass physical collection grace")

func test_income_query_excludes_wanderers_threatened_workers_and_unseen_treasure(t: SceneTree) -> void:
 var sim: RefCounted=Campaign.new(config())
 var worker: Dictionary=sim.world.people[0]
 worker["crystals"]=4
 t.truth(Guide.funding_hint(sim,30).get("kind")!="resident_income","unrecruited people are not described as donating income")
 worker.role="engineer"
 var enemy: Dictionary=sim._spawn_raider();enemy.x=worker.x;sim.raiders.append(enemy)
 var hint: Dictionary=Guide.funding_hint(sim,30)
 t.truth(hint.get("kind")!="resident_income","worker under attack cannot offer safe income")
 t.truth(hint.get("kind")!="chest","query never exposes an undiscovered cache")
 sim.raiders.clear();worker.hurt=1
 t.truth(Guide.funding_hint(sim,30).get("kind")!="resident_income","hurt residents are not selected as ready suppliers")

func test_income_query_survives_json_resume_without_new_state(t: SceneTree) -> void:
 var rules: Dictionary=config()
 var sim: RefCounted=Campaign.new(rules)
 sim.interact(30,"hall");sim.pouch.amount=0
 sim.world.people[0].role="engineer";sim.world.people[0]["crystals"]=4
 var codec: RefCounted=Codec.new()
 var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
 var packet: Dictionary=codec.capture(sim,rules,body)
 var resumed: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
 t.truth(not resumed.is_empty(),"existing state schema restores carried income")
 if resumed.is_empty():return
 t.truth(Rules.same(Guide.funding_hint(sim,30),Guide.funding_hint(resumed.session,30)),"continued journey selects identical source")
 for tick: int in range(60):
  Guide.funding_hint(sim,30)
  sim.advance(1.0/30,30);resumed.session.advance(1.0/30,30)
 t.truth(Rules.same(codec.capture(sim,rules,body),codec.capture(resumed.session,rules,body)),"repeated guidance queries do not alter resumed simulation or RNG")

func test_rocket_guidance_uses_same_remaining_cost_and_actual_construction(t: SceneTree) -> void:
 var rules: Dictionary=config();rules.voyage_enabled=1
 var sim: RefCounted=Campaign.new(rules)
 sim.planet.cleared=true;sim.planet.claim_core();sim.frontier.city_level=1
 sim.world.people[0].role="engineer";sim.world.people[0]["crystals"]=4
 sim.pouch.amount=1;sim.spirit.summoned=true
 t.equal(sim.spirit.advice(sim,30).get("kind"),"resident_income","post-dragon rocket construction uses earned income before unaffordable investment")
 sim.pouch.amount=20
 var at: float=preload("res://application/planet_operations.gd").rocket_x(sim)
 for crystal: int in range(19):sim.interact(at,"rocket")
 t.equal(sim.pouch.amount,1,"nineteen real rocket installments leave one crystal")
 t.equal(sim.spirit.advice(sim,at).get("key"),"rocket","rocket guidance counts existing installments")
 sim.interact(at,"rocket")
 var hint: Dictionary=sim.spirit.advice(sim,at)
 t.equal(hint.get("action"),"wait","paid rocket is not bought twice")
 t.equal(hint.get("goal"),"guide.rocket_building","existing engineers are described as constructing, not missing tools")
