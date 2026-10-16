extends RefCounted
const LevelFixture=preload("res://tests/test_planet_level_design.gd")
const Campaign=preload("res://application/campaign_session.gd")
func journey(seed_value: int) -> RefCounted:
	var fixture: RefCounted=preload("res://tests/test_ruin_variation.gd").new()
	var base: Dictionary=fixture.base(seed_value)
	base.level_design=load("res://data/planet_levels.tres").rules()
	# Public creation boundary; resources are added with implementation.
	if ResourceLoader.exists("res://data/trail_encounters.tres"):
		base.trail_design=load("res://data/trail_encounters.tres").rules()
	return preload("res://application/journey_setup.gd").create(base,fixture.profiles(),load("res://data/journey_paces/expedition.tres").rules())
func test_new_journey_has_two_sparse_roadside_moments(t: SceneTree) -> void:
	var trip: RefCounted=journey(617)
	for planet: int in range(7):
		var sim: RefCounted=Campaign.new(trip.configs[planet])
		t.equal(trip.configs[planet].get("trail_version",0),1,"authored journey resolves local encounter rules on planet "+str(planet))
		var trails: RefCounted=sim.get("trails")
		t.truth(trails!=null,"roadside progress has a persistent bounded subsystem")
		if trails==null:continue
		t.equal(trails.sites.size(),2,"only two moments: one guarded nest and one quiet discovery")
		t.truth(trails.sites[0].x*trails.sites[1].x<0,"outbound directions offer different moments")
		t.truth(sim.raiders.size()>=1 and sim.raiders.size()<=2,"at most two local monsters per whole planet")
		for site: RefCounted in trails.sites:
			t.equal(sim.frontier.regions[site.region].level_role,1,"new moments occupy selected wilderness, never sanctuary or gate arena")
			t.truth(absf(site.x-sim.world.sites.hall)>1800,"leave camp and opening recruits safe")
func test_existing_v36_journeys_do_not_gain_new_monsters(t: SceneTree) -> void:
	var trip: RefCounted=LevelFixture.new().journey(617)
	var sim: RefCounted=Campaign.new(trip.configs[0])
	t.equal(sim.raiders.size(),0,"previous routes retain their original encounters")
func test_local_monsters_stay_out_of_camp_and_do_not_hold_the_calendar(t: SceneTree) -> void:
	for planet: int in range(7):
		var sim: RefCounted=Campaign.new(journey(701).configs[planet])
		var home: float=sim.trails.sites[0].x
		for tick: int in range(120):sim.advance(1.0/30,sim.world.sites.hall)
		t.truth(sim.raiders.all(func(e: Dictionary)->bool:return absf(e.x-home)<=float(sim.trails.rules.territory)),"local wildlife stays within its authored territory")
		sim.clock.is_night=true;sim.clock.remaining=1.0/30;sim.wave=1
		sim.advance(1.0/30,sim.world.sites.hall)
		t.equal(sim.clock.day,2,"unvisited optional monsters never postpone dawn")
func test_quiet_find_and_cleared_nest_reward_once_through_normal_interaction(t: SceneTree) -> void:
	var sim: RefCounted=Campaign.new(journey(701).configs[0])
	var at: float=sim.trails.sites[1].x
	sim.advance(1.0/30,at)
	t.equal(sim.context(at).id,"trail_cache","quiet destination is discoverable without an extra puzzle")
	t.truth(sim.interact(at),"ordinary interaction claims the small find")
	t.truth(sim.trails.sites[1].claimed,"discovery is permanently consumed")
	t.truth(not sim.interact(at),"return visits cannot farm free crystals")
	at=sim.trails.sites[0].x
	sim.advance(1.0/30,at)
	t.truth(not sim.interact(at),"nest reward remains sealed while its creatures live")
	for enemy: Dictionary in sim.raiders:enemy.fighter.hp=0
	sim.advance(1.0/30,at)
	t.truth(sim.interact(at),"clearing local creatures opens the guarded reward")
	t.truth(sim.trails.sites[0].claimed,"cleared reward is persisted")
	t.truth(not sim.interact(at),"nest also pays only once")
func test_telegraph_escape_and_shelter_are_safe(t: SceneTree) -> void:
	var sim: RefCounted=Campaign.new(journey(101).configs[1])
	sim.frontier.city_level=1;sim.survival.armed=true;sim.pouch.amount=10
	var enemy: Dictionary=sim.raiders[0]
	var home: float=sim.trails.sites[0].x
	var at: float=home-100
	for tick: int in range(5):sim.advance(1.0/30,at)
	t.truth(enemy.windup>0,"sand prowler visibly telegraphs before its rush")
	var amount: int=sim.pouch.amount
	at=home-700
	for tick: int in range(90):sim.advance(1.0/30,at)
	t.equal(sim.pouch.amount,amount,"leaving the territory evades the attack")
	t.truth(absf(enemy.x-home)<=sim.trails.rules.territory,"a fleeing player is not chased into the supply clearing")
func test_active_roadside_state_survives_checkpoint(t: SceneTree) -> void:
	var config: Dictionary=journey(543).configs[2]
	var sim: RefCounted=Campaign.new(config)
	sim.frontier.city_level=1;sim.survival.armed=true
	var at: float=sim.trails.sites[0].x-80
	for tick: int in range(10):sim.advance(1.0/30,at)
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	var body: Dictionary={"x":at,"y":430.0,"vx":0.0,"vy":0.0}
	var packet: Dictionary=codec.capture(sim,config,body)
	t.truth(packet.has("trails"),"checkpoint explicitly stores finite roadside and attack progress")
	var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
	t.truth(not restored.is_empty(),"checkpoint supports local monster identity")
func test_mid_attack_save_replay_and_rewards_remain_finite(t: SceneTree) -> void:
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	var rules: Script=preload("res://application/campaign_checkpoint_rules.gd")
	for planet: int in range(7):
		var config: Dictionary=journey(231).configs[planet]
		var a: RefCounted=Campaign.new(config)
		a.frontier.city_level=1;a.survival.armed=true;a.pouch.amount=20;a.world.people.clear()
		var at: float=a.trails.sites[0].x-40
		for tick: int in range(12):a.advance(1.0/30,at)
		var body: Dictionary={"x":at,"y":430.0,"vx":0.0,"vy":0.0}
		var packet: Dictionary=codec.capture(a,config,body)
		var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
		t.truth(not restored.is_empty(),"in-progress local combat restores on world "+str(planet))
		if restored.is_empty():continue
		for tick: int in range(70):
			a.advance(1.0/30,at);restored.session.advance(1.0/30,at)
		t.truth(rules.same(codec.capture(a,config,body),codec.capture(restored.session,config,body)),"attack timers, hits and positions continue identically after JSON")
		for enemy: Dictionary in a.raiders:enemy.fighter.hp=0
		a.advance(1.0/30,at)
		t.truth(a.interact(a.trails.sites[0].x),"each defeated planet guardian opens a reward")
		packet=codec.capture(a,config,body)
		restored=codec.restore(JSON.parse_string(JSON.stringify(packet)))
		t.truth(not restored.is_empty(),"defeated creatures stay absent in a valid checkpoint")
		if not restored.is_empty():
			t.truth(not restored.session.interact(a.trails.sites[0].x),"reload never duplicates a claimed reward")
			t.equal(restored.session.raiders.size(),0,"return does not repopulate defeated creatures")
func test_corrupt_or_cross_world_trails_are_rejected(t: SceneTree) -> void:
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	var trip: RefCounted=journey(981)
	var config: Dictionary=trip.configs[0]
	var sim: RefCounted=Campaign.new(config)
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var saved: Dictionary=codec.capture(sim,config,body)
	var cases: Array[Dictionary]=[]
	var bad: Dictionary=saved.duplicate(true);bad.config.trail_version=88;cases.append(bad)
	bad=saved.duplicate(true);bad.config.trail_combat_x=30;cases.append(bad)
	bad=saved.duplicate(true);bad.config.erase("trail_version");cases.append(bad)
	bad=saved.duplicate(true);bad.trails.sites[0].claimed=true;cases.append(bad)
	bad=saved.duplicate(true);bad.trails.units[0].phase=99;cases.append(bad)
	bad=saved.duplicate(true);bad.trails.units[0].remaining=-1;cases.append(bad)
	bad=saved.duplicate(true);bad.trails.units[0].last_tick=100;cases.append(bad)
	bad=saved.duplicate(true);bad.raiders[0].state.trail_slot=99;cases.append(bad)
	bad=saved.duplicate(true);bad.raiders.append(bad.raiders[0].duplicate(true));cases.append(bad)
	bad=saved.duplicate(true);bad.raiders.clear();cases.append(bad)
	bad=saved.duplicate(true);bad.raiders[0].state.erase("trail_slot");cases.append(bad)
	for malformed: Dictionary in cases:t.truth(codec.restore(malformed).is_empty(),"malformed encounter state is refused without changing source")
	var voyage: Dictionary=trip.capture(sim,body)
	voyage.configs[1].trail_version=2
	t.truth(preload("res://application/star_voyage.gd").restore(voyage).is_empty(),"all worlds must keep a consistent supported encounter version")
func test_v19_route_save_upgrades_without_added_wildlife(t: SceneTree) -> void:
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	var config: Dictionary=LevelFixture.new().journey(453).configs[0]
	var sim: RefCounted=Campaign.new(config)
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var packet: Dictionary=codec.capture(sim,config,body)
	packet.erase("trails");packet.version=19;packet.merchant.erase("trip_end_x")
	var restored: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(packet)))
	t.truth(not restored.is_empty(),"v19 authored maps upgrade to v20 without a new event layer")
	if not restored.is_empty():
		t.equal(restored.session.trails.sites.size(),0,"old trip never acquires new destinations")
		t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(restored.config,config),"old resolved numeric rules are retained across JSON precision")
func test_sparse_sites_are_separated_and_repeatable_across_seeds(t: SceneTree) -> void:
	var errors: Array[String]=[]
	for seed_value: int in range(32):
		var trip: RefCounted=journey(seed_value)
		for config: Dictionary in trip.configs:
			var sim: RefCounted=Campaign.new(config)
			for site: RefCounted in sim.trails.sites:
				var room: Dictionary=sim.frontier.regions[site.region]
				if room.level_role!=1 or absf(site.x-room.x-room.width*0.5)>0.01:errors.append("outside designated quiet room")
				for relic: RefCounted in sim.modules.relics:
					if absf(relic.x-site.x)<500:errors.append("reward crowded against a main shrine")
				for person: Dictionary in sim.world.people:
					if absf(person.x-site.x)<250:errors.append("creature territory overlaps recruitment")
			if sim.trails.sites.size()!=2 or sim.trials.sites.size()!=1:errors.append("budget exceeded")
	t.equal(errors,[],"224 generated worlds preserve sparse encounters and authored destinations")
	t.equal(journey(76).configs,journey(76).configs,"same seed resolves identical roadside geometry and rules")

func test_half_tick_json_checkpoint_preserves_real_elapsed_state(t: SceneTree) -> void:
	var config: Dictionary=journey(472665975).configs[0]
	var sim: RefCounted=Campaign.new(config)
	var codec: RefCounted=preload("res://application/campaign_snapshot.gd").new()
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	for frame: int in range(45):
		sim.advance(1.0/60.0,30)
		var saved: Dictionary=JSON.parse_string(JSON.stringify(codec.capture(sim,config,body)))
		var restored: Dictionary=codec.restore(saved)
		t.truth(not restored.is_empty(),"60Hz save restores after JSON precision at frame "+str(frame+1))
		if not restored.is_empty():
			t.equal(restored.session.trails.units[0].last_tick,sim.trails.units[0].last_tick,"restore retains the actual creature clock")
	var invalid: Dictionary=JSON.parse_string(JSON.stringify(codec.capture(sim,config,body)))
	invalid.trails.units[0].last_tick=roundi(sim.workforce.elapsed*30)+1
	t.truth(codec.restore(invalid).is_empty(),"serialization tolerance does not admit a whole future creature tick")
