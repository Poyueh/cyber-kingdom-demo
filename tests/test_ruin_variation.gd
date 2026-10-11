extends RefCounted
const Setup=preload("res://application/journey_setup.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Mechanism=preload("res://domain/ruin_mechanism.gd")
func options() -> Dictionary:
	return {"version":1,"circuit_minimum":2,"circuit_maximum":3,"balance_minimum":3,"balance_maximum":5,"balance_target_radius":2,"pulse_periods":[6.0,7.0,8.0],"pulse_step":0.5}
func base(seed_value: int) -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var result: Dictionary=tuning.campaign_rules()
	result.merge({"seed":seed_value,"economy":tuning.economy_rules(),"ruin_variation":options()},true)
	return result
func profiles() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:
		result.append(load("res://data/planets/"+name+".tres").rules())
	return result
func journey(seed_value: int) -> RefCounted:
	return Setup.create(base(seed_value),profiles(),load("res://data/journey_paces/expedition.tres").rules())
func signature(config: Dictionary, planet: int) -> Array:
	var result: Array=[]
	for field: String in Mechanism.FIELDS:result.append(config["mechanism_%d_%s"%[planet,field]])
	return result
func test_new_journeys_require_observing_each_ruin_again(t: SceneTree) -> void:
	var unique: Array[Array]=[[],[],[],[],[],[],[]]
	for seed_value: int in range(16):
		var trip: RefCounted=journey(seed_value)
		for planet: int in range(1,7):
			var layout: Array=signature(trip.configs[planet],planet)
			if not unique[planet].has(layout):unique[planet].append(layout)
	var counts: Array[int]=[]
	for planet: int in range(1,7):
		counts.append(unique[planet].size())
		t.truth(unique[planet].size()>=4,"a new journey varies the visible configuration in world "+str(planet))
	print("Layout variants across 16 journeys: ",JSON.stringify(counts))
	var a: RefCounted=journey(813);var b: RefCounted=journey(813)
	t.equal(a.configs,b.configs,"the same seed retains the same authored journey")

func test_five_hundred_seeds_have_solvable_readable_configurations(t: SceneTree) -> void:
	var Search=preload("res://tests/ruin_search.gd")
	var failures: Array[String]=[];var solved: int=0
	var unique: Array[Array]=[[],[],[],[],[],[],[]]
	for seed_value: int in range(500):
		var trip: RefCounted=journey(seed_value)
		for planet: int in range(1,7):
			var config: Dictionary=trip.configs[planet]
			var m: RefCounted=Mechanism.new(config,planet)
			var route: Array[int]=Search.actions(m)
			var before: Dictionary=m.capture()
			if route.is_empty():failures.append("no solution %d/%d"%[seed_value,planet]);continue
			if m.kind==2 and (not route.has(0) or not route.has(1) or route.size()<4 or route.size()>6):failures.append("balance lacks meaningful steps")
			if m.kind==1 and route.size()<2:failures.append("circuit auto-solves or only needs one press")
			if m.kind==3 and (m.window<45 or m.period>360):failures.append("unreadable pulse")
			var now: int=0
			for action: int in route:
				now=Search.next_tick(m,action,now)
				if not m.activate(action,now):failures.append("rejected valid input")
			if m.progress()!=3:failures.append("reward remains sealed")
			else:solved+=1
			if not Mechanism.valid_config(config):failures.append("invalid generated configuration")
			var layout: Array=signature(config,planet)
			if not unique[planet].has(layout):unique[planet].append(layout)
			if before==m.capture():failures.append("started solved")
	t.equal(solved,3000,"500 seeds across six worlds can be solved by actual mechanism inputs")
	t.equal(failures,[],"every layout preserves readable openings and multi-step reasoning")
	var counts: Array[int]=[]
	for planet: int in range(1,7):counts.append(unique[planet].size())
	print("500-seed solved layouts: ",solved,"; unique per destination: ",JSON.stringify(counts))

func test_configuration_only_draws_cannot_change_loot_or_world(t: SceneTree) -> void:
	var Voyage=preload("res://application/star_voyage.gd")
	var Rules=preload("res://application/campaign_checkpoint_rules.gd")
	var original_base: Dictionary=base(98513);original_base.erase("ruin_variation")
	var before: RefCounted=Voyage.new(original_base,profiles())
	var after: RefCounted=journey(98513)
	for planet: int in range(7):
		var original: Dictionary=before.configs[planet].duplicate(true)
		var changed: Dictionary=after.configs[planet].duplicate(true)
		for key: String in changed.keys():
			if key in ["ruin_layout_version","journey_style"] or key.begins_with("mechanism_"):
				original.erase(key);changed.erase(key)
		t.truth(Rules.same(original,changed),"puzzle variety preserves costs, enemy rules and world seed "+str(planet))
		var a: RefCounted=Campaign.new(before.configs[planet]);var b: RefCounted=Campaign.new(after.configs[planet])
		var treasures_a: Array[float]=[];var treasures_b: Array[float]=[]
		for node: RefCounted in a.frontier.nodes:
			if node.kind=="cache":treasures_a.append(node.x)
		for node: RefCounted in b.frontier.nodes:
			if node.kind=="cache":treasures_b.append(node.x)
		t.equal(treasures_a,treasures_b,"existing scarce treasure is not rerolled by puzzle generation")
		t.equal(a.trials.sites[0].positions,b.trials.sites[0].positions,"puzzles remain on the same reachable ground")
		if planet==0:t.equal(a.trials.capture(),b.trials.capture(),"forest introductory puzzles are unchanged")

func test_partial_puzzles_resume_and_rewards_are_not_duplicated(t: SceneTree) -> void:
	var Search=preload("res://tests/ruin_search.gd")
	var Codec=preload("res://application/campaign_snapshot.gd")
	var Rules=preload("res://application/campaign_checkpoint_rules.gd")
	var trip: RefCounted=journey(416)
	for planet: int in range(1,7):
		var config: Dictionary=trip.configs[planet];var a: RefCounted=Campaign.new(config)
		for region: Dictionary in a.frontier.regions:region.discovered=true
		var site: RefCounted=a.trials.sites[0];var route: Array[int]=Search.actions(site.mechanism)
		var body: Dictionary={"x":site.positions[route[0]],"y":430.0,"vx":0.0,"vy":0.0}
		a.workforce.elapsed=float(Search.next_tick(site.mechanism,route[0],0))/30
		var coins: int=a.pouch.amount
		a.interact(body.x,"trial:%s:%d"%[site.id,route[0]])
		var codec: RefCounted=Codec.new();var packet: Dictionary=codec.capture(a,config,body)
		var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
		t.truth(not loaded.is_empty(),"partial generated puzzle survives a real checkpoint")
		if loaded.is_empty():continue
		for sim: RefCounted in [a,loaded.session]:
			for action: int in route.slice(1):
				sim.workforce.elapsed=float(Search.next_tick(sim.trials.sites[0].mechanism,action,roundi(sim.workforce.elapsed*30)))/30
				sim.interact(site.positions[action],"trial:%s:%d"%[site.id,action])
			sim.modules.observe(sim,site.x,430);sim.modules.observe(sim,site.x,430)
		t.equal(a.modules.found.count(site.id),1,"solving awards only this world's one module: "+str(planet))
		t.equal(a.pouch.amount,coins,"trying a different layout spends no crystals")
		for tick: int in range(30):a.advance(1.0/30,body.x);loaded.session.advance(1.0/30,body.x)
		t.truth(Rules.same(codec.capture(a,config,body),codec.capture(loaded.session,loaded.config,body)),"loading cannot reroll or change continuation")

func test_unknown_layout_versions_and_mixed_voyages_are_protected(t: SceneTree) -> void:
	var Voyage=preload("res://application/star_voyage.gd")
	var Rules=preload("res://application/campaign_checkpoint_rules.gd")
	var trip: RefCounted=journey(100)
	for invalid: Variant in [2,0,1.5,"1",null]:
		var bad: Dictionary=trip.configs[0].duplicate(true);bad.ruin_layout_version=invalid
		t.truth(not Rules.config_valid(bad),"invalid layout rule is not silently remapped")
	var sim: RefCounted=Campaign.new(trip.configs[0])
	var saved: Dictionary=trip.capture(sim,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	t.truth(not Voyage.restore(saved).is_empty(),"new seven-world journey accepts its resolved layouts")
	saved.configs[3].erase("ruin_layout_version")
	t.truth(Voyage.restore(saved).is_empty(),"inactive world cannot silently lose layout version")

func test_generated_stations_are_visible_and_interactable_on_real_maps(t: SceneTree) -> void:
	var Search=preload("res://tests/ruin_search.gd")
	var Known=preload("res://application/ruin_interactions.gd")
	var failures: Array[String]=[];var completed: int=0
	for seed_value: int in range(64):
		var trip: RefCounted=journey(seed_value)
		for planet: int in range(1,7):
			var sim: RefCounted=Campaign.new(trip.configs[planet])
			for region: Dictionary in sim.frontier.regions:region.discovered=true
			var site: RefCounted=sim.trials.sites[0]
			var route: Array[int]=Search.actions(site.mechanism)
			for action: int in route:
				var at: float=site.positions[action]
				if not Known.known(sim,at) or at<sim.frontier.left_boundary or at>sim.frontier.right_boundary:failures.append("unreachable station %d/%d"%[seed_value,planet])
				sim.workforce.elapsed=float(Search.next_tick(site.mechanism,action,roundi(sim.workforce.elapsed*30)))/30
				if sim.context(at).id!="trial" or not sim.interact(at):failures.append("ordinary interaction blocked %d/%d"%[seed_value,planet])
			sim.modules.observe(sim,site.x,430)
			if sim.modules.found.has(site.id):completed+=1
			else:failures.append("missing reward %d/%d"%[seed_value,planet])
	t.equal(completed,384,"64 real seven-world maps allow ordinary E interactions to earn every destination reward")
	t.equal(failures,[],"random layouts cannot hide required controls or overlap a higher priority action")
	print("Real-map puzzles solved through ordinary interaction: ",completed)
	var frost: RefCounted=Campaign.new(journey(416).configs[2])
	var site: RefCounted=frost.trials.sites[0]
	t.truth(Known.known(frost,site.positions[0]),"a device in the always-visible camp clearing is known")
	t.truth(not Known.known(frost,site.positions[2]),"unexplored wilderness is not revealed by the clearing fix")
	t.truth(not Known.known(frost,frost.frontier.right_boundary+1000),"outside the world is never treated as clearing")

func test_partial_ruin_survives_returning_to_another_planet(t: SceneTree) -> void:
	var trip: RefCounted=journey(416)
	var sim: RefCounted=Campaign.new(trip.configs[0])
	for gate: Dictionary in sim.mission.rifts:gate.sealed=true
	sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.frontier.city_level=1;sim.survival.armed=true;sim.advance(0.1,30)
	sim.planet.claim_core();sim.planet.rocket_ready=true
	var body: Dictionary={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
	var arrival: Dictionary=trip.prepare(sim,body,2)
	t.truth(not arrival.is_empty(),"rocket can reach a generated ice-coast puzzle")
	if arrival.is_empty():return
	var ice: RefCounted=arrival.session
	for region: Dictionary in ice.frontier.regions:region.discovered=true
	var site: RefCounted=ice.trials.sites[0]
	ice.interact(site.positions[0]);ice.planet.rocket_ready=true
	var state: Array[Dictionary]=ice.trials.capture()
	var home: Dictionary=arrival.journey.prepare(ice,body,0)
	t.truth(not home.is_empty(),"partially solved expedition can retreat to a visited colony")
	if home.is_empty():return
	home.session.planet.rocket_ready=true
	var revisit: Dictionary=home.journey.prepare(home.session,body,2)
	t.truth(not revisit.is_empty(),"return journey restores the explored planet")
	if revisit.is_empty():return
	t.equal(revisit.session.trials.capture(),state,"returning keeps exactly the partial mechanism state")
	t.equal(signature(revisit.config,2),signature(arrival.config,2),"revisiting never rerolls the marked target or controls")

func test_variation_tuning_and_random_stream_are_bounded(t: SceneTree) -> void:
	var Layout=preload("res://domain/ruin_layout.gd")
	var Streams=preload("res://domain/rng/rng_streams.gd")
	var rules: Dictionary=load("res://data/ruin_variation.tres").rules()
	t.truth(Layout.valid_options(rules),"published Inspector tuning is complete and valid")
	for key: String in rules:
		var missing: Dictionary=rules.duplicate(true);missing.erase(key)
		t.truth(not Layout.valid_options(missing),"missing generation settings have no silent defaults")
	for bad_period: Variant in [0,100,INF,"fast"]:
		var bad: Dictionary=rules.duplicate(true);bad.pulse_periods=[bad_period]
		t.truth(not Layout.valid_options(bad),"invalid pulse period is refused")
	var quiet: RefCounted=Streams.new(73);var busy: RefCounted=Streams.new(73)
	for i: int in range(100):busy.of(Streams.Stream.RUIN_LAYOUT).randi()
	for stream: int in [Streams.Stream.WORLD,Streams.Stream.LOOT,Streams.Stream.EVENT,Streams.Stream.COMBAT]:
		t.equal(busy.of(stream).randi(),quiet.of(stream).randi(),"layout draws never consume existing gameplay dice")
