extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")

func fresh() -> RefCounted:
	var sim: RefCounted=Campaign.new({"seed":42,"immersive_loop":1,"day_seconds":1000.0,"work_margin":1300.0})
	sim.world.people.clear()
	sim.interact(sim.world.sites.hall,"hall")
	for region: Dictionary in sim.frontier.regions:region.discovered=true
	return sim

func test_work_orders_follow_walls_but_treasure_stays_explorable(t) -> void:
	var sim: RefCounted=fresh()
	var far: RefCounted=null
	for node: RefCounted in sim.frontier.nodes:
		if node.kind!="cache" and node.x>sim.world.sites.wall+1300:far=node;break
	t.truth(far!=null,"map contains resources beyond local work range")
	if far==null:return
	var key: String="node:%d"%sim.frontier.nodes.find(far)
	t.truth(sim.context_for_key(far.x,key).id.is_empty(),"distant resources cannot take investment")
	var money: int=sim.pouch.amount
	t.truth(not sim.interact(far.x,key),"direct far work order is rejected")
	t.equal(sim.pouch.amount,money,"rejected work consumes no crystals")
	for node: RefCounted in sim.frontier.nodes:
		if node.kind=="cache":
			t.truth(sim.interact(node.x,"node:%d"%sim.frontier.nodes.find(node)),"remote chest remains openable")
			break
	for id: String in sim.world.walls:
		if sim.world.sites[id]>far.x-1300 and sim.world.sites[id]<far.x:
			sim.world.walls[id].level=1;sim.world.walls[id].hp=40;break
	t.truth(sim.context_for_key(far.x,key).enabled,"building an outer wall extends work range")

func test_worker_keeps_harvest_and_can_continue_without_delivery(t) -> void:
	var sim: RefCounted=fresh()
	var tree: RefCounted=null
	for node: RefCounted in sim.frontier.nodes:
		if node.kind=="tree" and absf(node.x)<2350:tree=node;break
	t.truth(tree!=null,"nearby harvest exists")
	if tree==null:return
	sim.world.people.append({"x":tree.x-22,"role":"engineer","hurt":0.0,"cooldown":0.0,"region":-1})
	t.truth(sim.interact(tree.x,"node:%d"%sim.frontier.nodes.find(tree)),"pay nearby harvest")
	for tick: int in range(250):
		sim.advance(1.0/30,5000)
		if tree.delivered:break
	t.truth(tree.delivered,"harvest finishes locally without a delivery trip")
	t.equal(sim.world.people[0].get("crystals",0),tree.crystals,"worker carries exact harvest in own wallet")
	t.truth(absf(sim.world.people[0].x-tree.x)<40,"completion happens beside the tree")
	t.equal(sim.pouch.ground_total(),0,"harvest is not dropped at camp")
	var held: int=sim.world.people[0].get("crystals",0)
	sim.advance(0.01,sim.world.people[0].x)
	t.equal(sim.world.people[0].get("crystals",0),0,"worker offers harvest when knight approaches")
	t.equal(sim.pouch.ground_total(),held,"offering conserves harvest")

func test_hunter_stays_near_walls_even_with_only_distant_prey(t) -> void:
	var sim: RefCounted=fresh()
	sim.frontier.animals.clear()
	sim.frontier.animals.append({"x":sim.world.sites.wall+2000,"region":0,"alive":true})
	sim.world.people.append({"x":sim.world.sites.wall+1250,"role":"hunter","hurt":0.0,"cooldown":0.0,"region":-1})
	for tick: int in range(300):sim.advance(1.0/30,5000)
	t.truth(sim.world.people[0].x<=sim.world.sites.wall+1300,"hunter cannot chase prey across map")
	t.truth(sim.frontier.animals[0].alive,"distant prey remains for later expansion")

func test_local_work_save_resume_and_legacy_station_migration(t) -> void:
	var config: Dictionary={"seed":42,"immersive_loop":1,"day_seconds":1000.0,"work_margin":1300.0}
	var sim: RefCounted=fresh()
	t.truth(absf(sim.world.sites.drill-sim.world.sites.hall)<=210,"upgrade station is beside camp")
	var codec: RefCounted=Codec.new()
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var packet: Dictionary=codec.capture(sim,config,body)
	packet.version=12;packet.world.sites.drill=1230.0
	var old: Dictionary=codec.restore(packet)
	t.truth(not old.is_empty(),"v12 checkpoint upgrades without losing player data")
	if old.is_empty():return
	t.truth(absf(old.session.world.sites.drill-30)<210,"old station moves beside camp on migration")
	for tick: int in range(60):sim.advance(1.0/30,30);old.session.advance(1.0/30,30)
	t.truth(Rules.same(codec.capture(sim,config,body),codec.capture(old.session,config,body)),"restored simulation matches uninterrupted play")

func test_partly_harvested_job_resumes_and_preserves_wallet_overflow(t) -> void:
	var config: Dictionary={"seed":42,"immersive_loop":1,"day_seconds":1000.0,"work_margin":1300.0}
	var sim: RefCounted=fresh()
	var tree: RefCounted=null
	for node: RefCounted in sim.frontier.nodes:
		if node.kind=="tree" and absf(node.x)<2350:tree=node;break
	sim.world.people.append({"x":tree.x-22,"role":"engineer","hurt":0.0,"cooldown":0.0,"region":-1,"crystals":10})
	sim.interact(tree.x,"node:%d"%sim.frontier.nodes.find(tree))
	for tick: int in range(30):sim.advance(1.0/30,5000)
	var codec: RefCounted=Codec.new()
	var body: Dictionary={"x":5000.0,"y":430.0,"vx":0.0,"vy":0.0}
	# Default test map is shorter than the shipping map: the knight must remain inside its bounds.
	body.x=sim.frontier.right_boundary-20
	var copy: Dictionary=codec.restore(codec.capture(sim,config,body))
	t.truth(not copy.is_empty(),"partly chopped tree and resident wallet restore")
	if copy.is_empty():return
	for tick: int in range(220):
		sim.advance(1.0/30,body.x);copy.session.advance(1.0/30,body.x)
	t.equal(sim.world.people[0].crystals,12,"worker wallet stops at capacity")
	t.equal(sim.pouch.ground_total(),tree.crystals-2,"excess harvest drops locally without losing crystals")
	t.truth(Rules.same(codec.capture(sim,config,body),codec.capture(copy.session,config,body)),"saved work continues exactly like uninterrupted harvesting")
