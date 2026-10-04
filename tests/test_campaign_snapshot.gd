extends RefCounted
const Campaign=preload("res://application/campaign_session.gd")
func test_full_checkpoint_restores_real_payment_cargo_and_world_continuation(t):
	var path: String="res://application/campaign_snapshot.gd"
	t.truth(ResourceLoader.exists(path),"campaign needs a full snapshot codec")
	if not ResourceLoader.exists(path):return
	var codec=load(path).new()
	var config={"seed":7}
	var sim=Campaign.new(config)
	sim.interact(30);sim.interact(30)
	sim.interact(-1100)
	sim.frontier.regions[0].discovered=true
	sim.world.people[0].role="engineer"
	var job=sim.frontier.nodes[0]
	job.marked=true;job.collected=true;job.carried=true;job.worker=0
	sim.world.people[0].x=job.x
	sim.pouch.toss(100,430,-1)
	sim.clock.remaining=41.0
	var bytes: String=JSON.stringify(codec.capture(sim,config,{"x":100.0,"y":430.0,"vx":0.0,"vy":0.0}))
	var resumed: Dictionary=codec.restore(JSON.parse_string(bytes))
	t.truth(not resumed.is_empty(),"saved world decodes after actual JSON serialization")
	if resumed.is_empty():return
	var copy=resumed.session
	t.equal(copy.context(-1100).paid,1,"partial crystal slots survive")
	t.truth(copy.frontier.nodes[0].carried and copy.frontier.nodes[0].worker==0,"same resident keeps hauled goods")
	t.equal(copy.clock.remaining,41.0,"clock does not advance while closed")
	t.equal(copy.pouch.amount+copy.pouch.ground_total(),sim.pouch.amount+sim.pouch.ground_total(),"pouch and ground crystals are conserved")
	t.truth(copy.world.wall==copy.world.walls.wall,"legacy right wall alias points at restored wall")
	for i in range(180):copy.advance(1.0/60,100)
	for i in range(180):sim.advance(1.0/60,100)
	t.truth(equivalent(codec.capture(copy,config,resumed.body),codec.capture(sim,config,resumed.body)),"resumed simulation evolves like uninterrupted play")


func equivalent(a, b) -> bool:
	if (a is float or a is int) and (b is float or b is int):return absf(float(a)-float(b))<0.000001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not equivalent(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not equivalent(a[i],b[i]):return false
		return true
	return a==b

func test_corrupt_checkpoint_is_rejected_before_it_can_run(t):
	var codec=load("res://application/campaign_snapshot.gd").new()
	var base: Dictionary=codec.capture(Campaign.new(),{},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	t.truth(not codec.restore(JSON.parse_string(JSON.stringify(base))).is_empty(),"control checkpoint is valid before corruption")
	var cases: Array=[]
	var bad=base.duplicate(true);bad.version=99;cases.append(bad)
	bad=base.duplicate(true);bad.pouch.amount=-1;cases.append(bad)
	bad=base.duplicate(true);bad.pouch.amount=999;cases.append(bad)
	bad=base.duplicate(true);bad.nodes[0].worker=999;cases.append(bad)
	bad=base.duplicate(true);bad.world.people[0].role="dragon";cases.append(bad)
	bad=base.duplicate(true);bad.clock.day=0;cases.append(bad)
	bad=base.duplicate(true);bad.nodes[0].kind="unknown";cases.append(bad)
	bad=base.duplicate(true);bad.body.x=999999;cases.append(bad)
	bad=base.duplicate(true);bad.world.people=["bad"];cases.append(bad)
	bad=base.duplicate(true);bad.config.prices="bad";cases.append(bad)
	bad=base.duplicate(true);bad.world.walls.wall.hp="bad";cases.append(bad)
	bad=base.duplicate(true);bad.mission.rifts[0].worker=999;cases.append(bad)
	bad=base.duplicate(true);bad.pouch.drops=[{"amount":3}];cases.append(bad)
	bad=base.duplicate(true);bad.hero.state.erase("shield");cases.append(bad)
	bad=base.duplicate(true);bad.hero.stats.erase("combo_enabled");cases.append(bad)
	bad=base.duplicate(true);bad.frontier.farm_cycle=0.0;cases.append(bad)
	bad=base.duplicate(true);bad.opened["1"]={"age":0};cases.append(bad)
	for packet in cases:
		t.truth(codec.restore(JSON.parse_string(JSON.stringify(packet))).is_empty(),"malformed world is refused, not silently repaired")
	t.truth(not codec.last_error.is_empty(),"rejection explains why original should be protected")


func test_resume_preserves_hit_identity_and_drops_buffered_next_cut(t):
	var codec=load("res://application/campaign_snapshot.gd").new()
	var sim=Campaign.new()
	sim.hero.stats.combo_enabled=true
	var enemy=sim._spawn_raider()
	enemy.x=50.0
	sim.raiders.append(enemy)
	sim.hero.start_attack()
	sim.hero.advance(0.15)
	t.truth(sim.hero.strike(enemy.fighter,20),"first cut hits before checkpoint")
	enemy.fighter.advance(0.13)
	sim.hero.start_attack()
	var restored=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(sim,{},{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}))))
	t.truth(not restored.is_empty(),"active sword and enemy survive JSON")
	if restored.is_empty():return
	var copy=restored.session
	t.truth(not copy.hero.strike(copy.raiders[0].fighter,20),"same cut cannot damage restored enemy twice")
	t.equal(copy.raiders[0].fighter.hp,35,"reload cannot duplicate sword damage")
	copy.hero.advance(0.2)
	t.truth(copy.hero.attack_remaining<=0 and copy.hero.combo_step!=2,"load discards buffered followup intent")
	copy.hero.advance(0.3)
	t.truth(copy.hero.start_attack(),"fresh input can attack after recovery")
	copy.hero.advance(0.15)
	t.truth(copy.hero.strike(copy.raiders[0].fighter,20),"new cut can hit same restored enemy")

func test_pending_enemy_windup_survives_and_invalid_target_is_refused(t):
	var codec=load("res://application/campaign_snapshot.gd").new()
	var sim=Campaign.new()
	sim.interact(180.0)
	sim.clock.remaining=0.001
	sim.advance(0.01,1000)
	sim.raiders[0].x=sim.world.people[0].x
	sim.advance(0.01,1000)
	t.truth(sim.raiders[0].windup>0 and sim.raiders[0].target.kind=="person","resident is targeted by real enemy windup")
	var packet=codec.capture(sim,{},{"x":1000.0,"y":430.0,"vx":0.0,"vy":0.0})
	var restored=codec.restore(JSON.parse_string(JSON.stringify(packet)))
	t.truth(not restored.is_empty(),"night invasion and target restore")
	if restored.is_empty():return
	for i in range(45):
		sim.advance(1.0/60,1000)
		restored.session.advance(1.0/60,1000)
	t.truth(equivalent(codec.capture(sim,{},restored.body),codec.capture(restored.session,{},restored.body)),"enemy strike and pending spawns continue identically")
	packet.raiders[0].state.target.index=999
	t.truth(codec.restore(packet).is_empty(),"invalid enemy resident index cannot crash next frame")
	packet.raiders[0].state.erase("target")
	t.truth(codec.restore(packet).is_empty(),"missing enemy target is refused safely")

func test_reused_codec_keeps_snapshots_and_restored_journeys_independent(t):
	var codec=load("res://application/campaign_snapshot.gd").new()
	var config: Dictionary={"seed":17}
	var sim=Campaign.new(config)
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var first: Dictionary=codec.capture(sim,config,body)
	var frozen: Dictionary=first.duplicate(true)
	sim.world.people[0].x+=24
	sim.pouch.toss(30,430,1)
	var second: Dictionary=codec.capture(sim,config,body)
	t.truth(equivalent(first,frozen),"later live changes and captures cannot mutate a previous snapshot")
	t.truth(not equivalent(first,second),"reused codec reads current values rather than cached values")
	var restored: Dictionary=codec.restore(second)
	t.truth(not restored.is_empty(),"reused codec restores a changed journey")
	if restored.is_empty():return
	var frozen_second: Dictionary=second.duplicate(true)
	restored.session.world.people[0].x+=19
	restored.session.pouch.drops.clear()
	t.truth(equivalent(second,frozen_second),"restored collections do not alias the saved packet")
	t.truth(sim.world.people[0].x!=restored.session.world.people[0].x,"restored residents do not alias the source journey")
	var other_config: Dictionary={"seed":29,"economy":{"outer_regions_per_side":4}}
	var other=Campaign.new(other_config)
	var other_packet: Dictionary=codec.capture(other,other_config,body)
	t.truth(not codec.restore(other_packet).is_empty(),"one codec supports a different map configuration")
	var corrupt: Dictionary=other_packet.duplicate(true)
	corrupt.world.people[0]["x"]="invalid"
	t.truth(codec.restore(corrupt).is_empty(),"warm metadata cannot bypass invalid nested field rejection")
	t.truth(not codec.restore(first).is_empty(),"original journey remains loadable after another map and rejected save")
