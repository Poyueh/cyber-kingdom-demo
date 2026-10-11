extends RefCounted
const Fixture=preload("res://tests/test_ruin_variation.gd")
const Setup=preload("res://application/journey_setup.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
func journey(seed_value: int) -> RefCounted:
	var f: RefCounted=Fixture.new()
	var config: Dictionary=f.base(seed_value)
	config.level_design=load("res://data/planet_levels.tres").rules()
	return Setup.create(config,f.profiles(),load("res://data/journey_paces/expedition.tres").rules())
func test_routes_have_one_primary_ruin_and_meaningful_quiet_ground(t: SceneTree) -> void:
	var trip: RefCounted=journey(742601)
	for planet: int in range(7):
		var sim: RefCounted=Campaign.new(trip.configs[planet])
		t.equal(sim.trials.sites.size(),1,"one primary puzzle per world, no repeated forest relay")
		var quiet: float=0
		for region: Dictionary in sim.frontier.regions:
			if region.get("level_role",-1) in [1,4]:quiet+=region.width
		t.truth(quiet/(sim.frontier.right_boundary-sim.frontier.left_boundary)>0.25,"walking routes reserve at least a quarter of their length for breathing room")
		t.truth(preload("res://presentation/exploration_landmarks.gd").layout(sim).size()<=4,"a few meaningful landmarks replace a reward-like monument in every room")
		var local: int=0
		for spec: RefCounted in sim.modules.specs:
			if spec.planet==planet:local+=1
		t.equal(sim.modules.relics.size(),local,"lower puzzle density never deletes a collectible")

func test_frontier_expansion_can_cross_quiet_land_without_remote_work(t: SceneTree) -> void:
	var trip: RefCounted=journey(42)
	var unreachable: Array[String]=[]
	for planet: int in range(7):
		var sim: RefCounted=Campaign.new(trip.configs[planet])
		for side: int in [-1,1]:
			var previous: String="wall_left" if side<0 else "wall"
			for index: int in range(sim.frontier.regions.size()):
				var region: Dictionary=sim.frontier.regions[index]
				if region.level_role!=0 or signf(region.x)!=side:continue
				var id: String="frontier_wall:%d"%index
				var nearest: float=INF
				for node: RefCounted in sim.frontier.nodes:
					if node.region==index:nearest=minf(nearest,absf(node.x-sim.world.sites[previous]))
				var first: float=sim.world.sites[previous]+side*nearest
				if not sim.work_area.contains(first):unreachable.append("%d/%s"%[planet,id])
				sim.world.walls[id].level=1;sim.world.walls[id].hp=40
				previous=id
		t.truth(sim.work_area.bounds().x>sim.frontier.left_boundary and sim.work_area.bounds().y<sim.frontier.right_boundary,"forward work never reaches the dragon gates")
	t.equal(unreachable,[],"sequential outer walls reach the next supply zone across designed gaps")
	var sim: RefCounted=Campaign.new(trip.configs[0])
	var id: String="frontier_wall:0"
	var remote: float=sim.frontier.regions[4].x+sim.frontier.regions[4].width-50
	t.truth(not sim.work_area.contains(remote),"distant supplies require territorial progress")
	sim.world.walls[id].level=1;sim.world.walls[id].hp=40
	t.truth(sim.work_area.contains(remote),"completed frontier edge connects the next supply clearing")
	sim.world.walls[id].hp=0
	t.truth(not sim.work_area.contains(remote),"losing the forward wall closes the distant work route immediately")

func test_seeded_routes_keep_clear_controls_supply_and_gate_arenas(t: SceneTree) -> void:
	var Search=preload("res://tests/ruin_search.gd")
	var Level=preload("res://domain/planet_level_layout.gd")
	var errors: Array[String]=[];var solved: int=0
	var sample: Array=[]
	for seed_value: int in range(64):
		var trip: RefCounted=journey(seed_value)
		for planet: int in range(7):
			var sim: RefCounted=Campaign.new(trip.configs[planet])
			var quiet: float=0.0;var caches: int=0
			for node: RefCounted in sim.frontier.nodes:
				if node.kind=="cache":caches+=1
				elif sim.frontier.regions[node.region].level_role!=0:errors.append("resource outside supply")
			for region: Dictionary in sim.frontier.regions:
				region.discovered=true
				if region.level_role in [1,4]:quiet+=region.width
				if region.level_role==4 and region.width<800:errors.append("short gate approach")
				if region.level_role!=0:
					var index: int=sim.frontier.regions.find(region)
					if sim.world.people.any(func(p: Dictionary)->bool:return p.region==index):errors.append("camp in quiet room")
			if quiet/(sim.frontier.right_boundary-sim.frontier.left_boundary)<0.25:errors.append("not enough quiet ground")
			if caches!=2 or sim.frontier.nodes.size()>38:errors.append("clutter budget exceeded")
			var site: RefCounted=sim.trials.sites[0]
			var room: Dictionary=sim.frontier.regions[site.region]
			var actions: Array[int]=site.order if site.mechanism==null else Search.actions(site.mechanism)
			sim.modules.observe(sim,site.x,430)
			if sim.modules.found.has(site.id):errors.append("sealed reward collected")
			for action: int in actions:
				var at: float=site.positions[action]
				if at<room.x+100 or at>room.x+room.width-100:errors.append("device escaped shrine")
				if site.mechanism!=null:sim.workforce.elapsed=float(Search.next_tick(site.mechanism,action,roundi(sim.workforce.elapsed*30)))/30
				if sim.context(at).id!="trial" or not sim.interact(at):errors.append("ordinary input blocked")
			sim.modules.observe(sim,site.x,430)
			if not sim.modules.found.has(site.id):errors.append("reward missing")
			else:solved+=1
			if seed_value==0:sample.append({"planet":planet,"nodes":sim.frontier.nodes.size(),"landmarks":preload("res://presentation/exploration_landmarks.gd").layout(sim).size(),"width":sim.frontier.right_boundary-sim.frontier.left_boundary,"quiet_percent":snappedf(quiet/(sim.frontier.right_boundary-sim.frontier.left_boundary)*100,0.1)})
	t.equal(solved,448,"64 seeds across all seven authored worlds solve with ordinary interactions")
	t.equal(errors,[],"routes preserve quiet ground, usable supplies and one self-contained shrine")
	print("Authored route sample: ",JSON.stringify(sample))
	t.equal(journey(178).configs,journey(178).configs,"the same seed produces the same complete journey")
	t.truth(journey(178).configs[0].economy!=journey(179).configs[0].economy,"local room lengths still vary between journeys")

func test_resolved_routes_and_partial_puzzles_survive_json_load(t: SceneTree) -> void:
	var trip: RefCounted=journey(416);var codec: RefCounted=Codec.new()
	var Search=preload("res://tests/ruin_search.gd")
	for planet: int in range(7):
		var config: Dictionary=trip.configs[planet];var a: RefCounted=Campaign.new(config)
		for region: Dictionary in a.frontier.regions:region.discovered=true
		var site: RefCounted=a.trials.sites[0]
		var route: Array[int]=site.order if site.mechanism==null else Search.actions(site.mechanism)
		var body: Dictionary={"x":site.positions[route[0]],"y":430.0,"vx":0.0,"vy":0.0}
		if site.mechanism!=null:a.workforce.elapsed=float(Search.next_tick(site.mechanism,route[0],0))/30
		a.interact(body.x)
		var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(codec.capture(a,config,body))))
		t.truth(not loaded.is_empty(),"new route checkpoint restores on planet "+str(planet))
		if loaded.is_empty():continue
		for sim: RefCounted in [a,loaded.session]:
			for action: int in route.slice(1):
				if site.mechanism!=null:sim.workforce.elapsed=float(Search.next_tick(sim.trials.sites[0].mechanism,action,roundi(sim.workforce.elapsed*30)))/30
				sim.interact(site.positions[action])
			sim.modules.observe(sim,site.x,430)
		for tick: int in range(30):a.advance(1.0/30,body.x);loaded.session.advance(1.0/30,body.x)
		t.equal(a.modules.found.count(site.id),1,"opening the sole shrine grants exactly one reward")
		t.truth(Rules.same(codec.capture(a,config,body),codec.capture(loaded.session,loaded.config,body)),"save preserves room geometry and deterministic continuation")
	var forest: RefCounted=Campaign.new(trip.configs[0])
	for relic: RefCounted in forest.modules.relics:
		if relic.id=="lance":
			forest.frontier.regions[relic.region].discovered=true
			forest.modules.observe(forest,relic.x,430);forest.modules.observe(forest,relic.x,430)
	t.equal(forest.modules.found.count("lance"),1,"forest lance becomes an exploration reward without a second puzzle")
	t.truth(forest.mount_quest.enabled,"the unique mechanical mount expedition remains")

func test_bad_route_packets_and_mixed_worlds_are_rejected(t: SceneTree) -> void:
	var trip: RefCounted=journey(31)
	var config: Dictionary=trip.configs[0];var codec: RefCounted=Codec.new()
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var sim: RefCounted=Campaign.new(config)
	var original: Dictionary=codec.capture(sim,config,body)
	for key: String in ["level_design_version","level_trial_module","level_module_arc_region","level_module_arc_x"]:
		var bad: Dictionary=original.duplicate(true);bad.config.erase(key)
		t.truth(codec.restore(bad).is_empty(),"missing resolved layout parameter is protected: "+key)
	for value: Variant in [2,0,1.5,"1",null]:
		var bad: Dictionary=original.duplicate(true);bad.config.level_design_version=value
		t.truth(codec.restore(bad).is_empty(),"unknown or malformed generation version is protected")
	for change: Dictionary in [{"level_0_width":NAN},{"level_0_width":10},{"level_0_role":6},{"level_0_terrain":-1},{"level_surprise":3}]:
		var bad: Dictionary=original.duplicate(true);bad.config.economy.merge(change,true)
		t.truth(codec.restore(bad).is_empty(),"invalid authored route cannot replace a saved world")
	var wrong_region: Dictionary=original.duplicate(true);wrong_region.frontier.regions[0].level_role=1
	t.truth(codec.restore(wrong_region).is_empty(),"saved region purpose must match immutable configuration")
	var voyage: Dictionary=trip.capture(sim,body)
	t.truth(not preload("res://application/star_voyage.gd").restore(JSON.parse_string(JSON.stringify(voyage))).is_empty(),"all seven resolved layouts restore together")
	voyage.configs[3].erase("level_design_version")
	t.truth(preload("res://application/star_voyage.gd").restore(voyage).is_empty(),"inactive planet cannot lose its level layout version")
	t.truth(Rules.same(original,codec.capture(sim,config,body)),"rejected data never mutates the live campaign")

func test_level_layout_randomness_is_isolated(t: SceneTree) -> void:
	var Streams=preload("res://domain/rng/rng_streams.gd")
	var untouched: RefCounted=Streams.new(73);var busy: RefCounted=Streams.new(73)
	for i: int in range(100):busy.of(Streams.Stream.LEVEL_LAYOUT).randi()
	for stream: int in range(Streams.Stream.LEVEL_LAYOUT):
		t.equal(busy.of(stream).randi(),untouched.of(stream).randi(),"route draws do not consume loot, combat or puzzle randomness")
