extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const BODY: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func rules() -> Dictionary:
	var tuning: Resource = load("res://data/campaign.tres")
	var config: Dictionary = tuning.campaign_rules()
	config.merge({"seed":742601,"economy":tuning.economy_rules(),"day_seconds":1000.0,"starting_crystals":0},true)
	return config

func advance(sim: RefCounted, ticks: int, x: float) -> void:
	for tick: int in range(ticks):sim.advance(0.1,x)

func test_new_chests_are_sparse_distant_and_seeded(t: SceneTree) -> void:
	for seed_value: int in range(40):
		var config: Dictionary = rules()
		config.seed=seed_value
		var sim: RefCounted = Campaign.new(config)
		var chests: Array = sim.frontier.nodes.filter(func(n: RefCounted) -> bool: return n.kind=="cache")
		t.truth(chests.size()>=2 and chests.size()<=3,"large map has only two or three finite treasures")
		for i: int in range(chests.size()):
			t.truth(absf(chests[i].x-sim.world.sites.hall)>=2400,"treasure requires a real expedition away from camp")
			for j: int in range(i):t.truth(absf(chests[i].x-chests[j].x)>=2600,"treasures never appear as neighboring pairs")
		var twin: RefCounted = Campaign.new(config)
		t.equal(twin.frontier.layout_signature(),sim.frontier.layout_signature(),"same seed keeps the same scarce treasure layout")

func test_empty_knight_gets_one_visible_gift_then_must_fund_next_trip(t: SceneTree) -> void:
	var sim: RefCounted = Campaign.new(rules())
	sim.world.people.clear()
	advance(sim,100,30)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),6,"merchant approaches an empty knight and physically hands over six crystals")
	var merchant: RefCounted = sim.get("merchant")
	t.truth(merchant!=null,"journey owns a persistent merchant")
	if merchant==null:return
	advance(sim,100,merchant.home_x)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),6,"standing beside merchant cannot repeatedly claim the gift")
	t.truth(sim.interact(merchant.x,"merchant"),"one paid crystal commissions a trip")
	t.equal(sim.pouch.amount,5,"trip costs exactly one crystal")
	t.truth(not sim.interact(merchant.x,"merchant"),"departing trader cannot accept duplicate payments")
	advance(sim,150,merchant.home_x)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),5,"no immediate or same-day profit")
	sim.clock.is_night=true;sim.clock.remaining=0.01
	sim.advance(0.1,merchant.home_x)
	advance(sim,150,merchant.home_x)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),11,"trader returns on next dawn and hands over six once")
	advance(sim,50,merchant.home_x)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),11,"returned reward does not repeat while nearby")

func test_merchant_waits_for_proximity_and_free_gift_is_not_repeatable(t: SceneTree) -> void:
	var sim: RefCounted = Campaign.new(rules())
	sim.world.people.clear()
	sim.pouch.amount=1
	advance(sim,20,30)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),1,"funded knight is not given extra starting money")
	sim.pouch.amount=0
	sim.advance(0.1,30)
	t.equal(sim.pouch.ground_total(),0,"trader walks over instead of instantly filling the bag")
	advance(sim,100,30)
	var merchant: RefCounted = sim.get("merchant")
	if merchant==null:t.truth(false,"merchant should exist");return
	advance(sim,100,merchant.home_x)
	sim.pouch.amount=0;sim.pouch.drops.clear()
	advance(sim,100,merchant.home_x)
	t.equal(sim.pouch.ground_total(),0,"emptying the pouch again does not regenerate the free gift")
	t.truth(not sim.interact(merchant.home_x,"merchant"),"empty pouch cannot commission another trip")

func test_trader_travel_save_resume_and_corruption_admission(t: SceneTree) -> void:
	var config: Dictionary = rules()
	var sim: RefCounted = Campaign.new(config)
	sim.world.people.clear()
	advance(sim,100,30)
	var merchant: RefCounted = sim.get("merchant")
	if merchant==null:t.truth(false,"merchant should exist");return
	advance(sim,100,merchant.home_x)
	sim.interact(merchant.x,"merchant")
	advance(sim,12,merchant.home_x)
	var codec: RefCounted = Codec.new()
	var saved: Dictionary = codec.capture(sim,config,BODY)
	var loaded: Dictionary = codec.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not loaded.is_empty(),"outbound merchant and payment survive JSON save")
	if loaded.is_empty():return
	advance(sim,100,merchant.home_x);advance(loaded.session,100,merchant.home_x)
	var comparison: RefCounted = preload("res://tests/test_campaign_snapshot.gd").new()
	t.truth(comparison.equivalent(codec.capture(sim,config,BODY),codec.capture(loaded.session,config,BODY)),"travel resumes with exactly the same state and money")
	var broken: Dictionary=saved.duplicate(true)
	broken.merchant.phase=999
	t.truth(codec.restore(broken).is_empty(),"unknown merchant states are rejected without resetting rewards")

func test_v13_journeys_keep_original_treasure_and_gain_no_duplicate_gift(t: SceneTree) -> void:
	var config: Dictionary = {"seed":742601}
	var sim: RefCounted = Campaign.new(config)
	var codec: RefCounted = Codec.new()
	var saved: Dictionary = codec.capture(sim,config,BODY)
	saved.version=13;preload("res://tests/legacy_checkpoint.gd").before_mount(saved);saved.erase("merchant");saved.erase("trials")
	var restored: Dictionary = codec.restore(saved)
	t.truth(not restored.is_empty(),"previous save version upgrades without rerolling geography")
	if restored.is_empty():return
	t.equal(restored.session.frontier.layout_signature(),sim.frontier.layout_signature(),"legacy chest locations stay intact")
	t.equal(restored.session.pouch.amount,sim.pouch.amount,"legacy wallet unchanged by migration")

func test_delivery_is_a_physical_burst_and_return_waits_for_knight(t: SceneTree) -> void:
	var config: Dictionary=rules()
	var sim: RefCounted=Campaign.new(config)
	sim.world.people.clear()
	for tick: int in range(100):
		sim.advance(0.1,30)
		if sim.pouch.ground_total()>0:break
	t.equal(sim.pouch.amount,0,"first gift appears in the world before entering the pouch")
	t.equal(sim.pouch.drops.size(),6,"six independent moving crystals visibly burst from trader")
	t.truth(sim.pouch.drops.all(func(gem: Dictionary) -> bool: return gem.grace>0 and gem.vy<0),"gift has upward motion and collection grace")
	var merchant: RefCounted=sim.merchant
	advance(sim,30,30)
	advance(sim,60,merchant.home_x)
	sim.interact(merchant.x,"merchant")
	advance(sim,150,1500)
	sim.clock.is_night=true;sim.clock.remaining=0.01
	sim.advance(0.1,1500)
	advance(sim,150,1500)
	t.equal(sim.pouch.amount+sim.pouch.ground_total(),5,"returned trader waits at camp and cannot credit a distant knight")
	var codec: RefCounted=Codec.new()
	var ready: Dictionary=codec.capture(sim,config,BODY)
	var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(ready)))
	t.truth(not restored.is_empty(),"waiting delivery survives a save")
	if restored.is_empty():return
	restored.session.advance(0.1,merchant.home_x)
	t.equal(restored.session.pouch.ground_total(),6,"approaching after reload releases the delivery exactly once")
	var after: Dictionary=codec.restore(codec.capture(restored.session,config,BODY))
	t.truth(not after.is_empty(),"already delivered state saves")
	if after.is_empty():return
	advance(after.session,30,merchant.home_x)
	t.equal(after.session.pouch.amount+after.session.pouch.ground_total(),11,"reload after delivery never duplicates crystals")
	var invalid: Dictionary=ready.duplicate(true)
	invalid.merchant.return_day=sim.clock.day+1
	t.truth(codec.restore(invalid).is_empty(),"a next-day reward cannot be marked ready today")

func test_paused_and_ended_sessions_do_not_advance_trader(t: SceneTree) -> void:
	var sim: RefCounted=Campaign.new(rules())
	sim.advance(0.1,30)
	var before: Dictionary=sim.merchant.capture()
	sim.advance(0,30)
	t.equal(sim.merchant.capture(),before,"zero-time updates do not move the merchant")
	sim.hero.hp=0
	sim.advance(3,30)
	t.equal(sim.merchant.capture(),before,"a dead knight cannot receive post-game income")

func test_empty_knight_at_world_edge_is_approached_from_inside(t: SceneTree) -> void:
	var sim: RefCounted=Campaign.new(rules())
	sim.advance(0.1,sim.frontier.left_boundary)
	t.truth(sim.merchant.x>sim.frontier.left_boundary+300,"merchant enters from inside the map instead of appearing on top of a knight at the edge")
	t.equal(sim.pouch.ground_total(),0,"edge arrival still waits for a visible approach")

func test_subtick_update_preserves_visible_walking_state(t: SceneTree) -> void:
	var sim: RefCounted=Campaign.new(rules())
	var trader: RefCounted=sim.merchant
	trader.phase=trader.Phase.WAITING_PAYMENT;trader.x=-3000
	trader.advance(1,1,-3000,430,false)
	var before: Dictionary=trader.capture()
	trader.advance(1,1,-3000,430,false)
	t.equal(trader.capture(),before,"same tick preserves walking pose instead of flashing idle")

func test_remote_dispatch_walks_from_payment_location_and_survives_reload(t: SceneTree) -> void:
	var config: Dictionary=rules()
	var codec: RefCounted=Codec.new()
	for location: float in [-3000.0,3000.0]:
		var sim: RefCounted=Campaign.new(config)
		sim.world.people.clear();sim.pouch.amount=6
		sim.merchant.phase=sim.merchant.Phase.WAITING_PAYMENT
		sim.merchant.x=location
		t.truth(sim.interact(location,"merchant"),"moving merchant accepts one funded dispatch in wilderness")
		var end_x: float=sim.merchant.trip_end_x
		t.truth(absf(end_x-location)>=config.merchant_trip,"departure has a full visible route from payment position")
		sim.advance(0.1,location)
		t.truth(sim.merchant.visible() and absf(sim.merchant.x-location)<10,"paid merchant stays visible and moves normally")
		var saved: Dictionary=codec.capture(sim,config,BODY)
		var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
		t.truth(not loaded.is_empty(),"remote departure survives JSON save")
		if loaded.is_empty():continue
		advance(sim,30,location);advance(loaded.session,30,location)
		t.equal(loaded.session.merchant.capture(),sim.merchant.capture(),"saved departure continues the same route")
		t.equal(sim.pouch.amount,5,"departure charges once")

func test_v20_merchant_upgrade_preserves_existing_journey(t: SceneTree) -> void:
	var config: Dictionary=rules()
	var sim: RefCounted=Campaign.new(config)
	var codec: RefCounted=Codec.new()
	var saved: Dictionary=codec.capture(sim,config,BODY)
	saved.version=20;saved.erase("core_loop");saved.erase("planet");saved.merchant.erase("trip_end_x")
	var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not loaded.is_empty(),"v20 merchant checkpoint migrates without discarding journey")
	if loaded.is_empty():return
	t.equal(loaded.session.pouch.amount,sim.pouch.amount,"migration grants no duplicate crystals")
	t.equal(loaded.session.frontier.layout_signature(),sim.frontier.layout_signature(),"migration preserves geography")
	var invalid: Dictionary=codec.capture(sim,config,BODY)
	invalid.merchant.trip_end_x=sim.frontier.right_boundary+1
	t.truth(codec.restore(invalid).is_empty(),"out-of-map route is rejected")

func test_edge_dispatch_uses_inward_route(t: SceneTree) -> void:
	var config: Dictionary=rules()
	var sim: RefCounted=Campaign.new(config)
	sim.world.people.clear();sim.pouch.amount=6
	var start: float=sim.frontier.right_boundary-5
	sim.merchant.phase=sim.merchant.Phase.WAITING_PAYMENT
	sim.merchant.x=start
	t.truth(sim.interact(start,"merchant"),"edge trader accepts payment")
	t.truth(sim.merchant.trip_end_x<start-config.merchant_trip+1,"edge departure turns inward for a full trip")
	sim.advance(0.1,start)
	t.truth(sim.merchant.visible() and sim.merchant.x<start,"edge trader stays visible while departing inward")
