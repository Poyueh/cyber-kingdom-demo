extends RefCounted
const Setup = preload("res://application/journey_setup.gd")
const Campaign = preload("res://application/campaign_session.gd")
const Voyage = preload("res://application/star_voyage.gd")
const Pressure = preload("res://domain/night_pressure.gd")
const Rules = preload("res://application/campaign_checkpoint_rules.gd")

func base() -> Dictionary:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":10629,"economy":tuning.economy_rules()},true)
	return config

func profiles() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for planet: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:
		result.append(load("res://data/planets/"+planet+".tres").rules())
	return result

func test_explorer_has_time_to_return_before_a_lighter_first_night(t: SceneTree) -> void:
	var selected: Dictionary={"id":1,"day_adjustment":90.0,"first_adjustment":-1,"growth_adjustment":-1,"limit_adjustment":-20}
	var journey: RefCounted=Setup.create(base(),profiles(),selected)
	var sim: RefCounted=Campaign.new(journey.configs[0])
	sim.clock.advance(180.0,true)
	t.truth(not sim.clock.is_night,"explorer can finish a standard-length daylight outing before dark")
	t.equal(sim.night_pressure.count_for(1),2,"explorer faces two enemies on the first night")
	t.equal(sim.night_pressure.count_for(5),6,"explorer still gains nightly pressure, more gradually")
	t.truth(journey.configs.all(func(config: Dictionary)->bool:return config.get("journey_style",-1)==1),"chosen pace follows all seven planets")
	var saved: Dictionary=journey.capture(sim,{"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0})
	var restored: Dictionary=Voyage.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not restored.is_empty(),"chosen journey survives the real checkpoint boundary")
	if not restored.is_empty():t.equal(restored.config.get("journey_style",-1),1,"loaded journey remembers its chosen pace")

func test_pacing_preserves_worlds_and_economy_while_separating_pressure(t: SceneTree) -> void:
	var catalog: Resource=load("res://data/journey_paces.tres")
	t.truth(catalog.valid(),"published pace catalog has complete unique choices")
	var config: Dictionary=base()
	var normal: RefCounted=Voyage.new(config,profiles())
	for option: Resource in catalog.options:
		var journey: RefCounted=Setup.create(config,profiles(),option.rules())
		var same: RefCounted=Setup.create(config,profiles(),option.rules())
		t.equal(journey.configs,same.configs,"same seed and pace resolve deterministically")
		for id: int in range(7):
			var original: Dictionary=normal.configs[id]
			var chosen: Dictionary=journey.configs[id]
			t.truth(Rules.config_valid(chosen),"every paced biome is save-admissible")
			var left: Dictionary=original.duplicate(true)
			var right: Dictionary=chosen.duplicate(true)
			for key: String in ["journey_style","day_seconds","night_first","night_growth","night_limit"]:
				left.erase(key);right.erase(key)
			t.equal(left,right,"pace preserves rewards, routes, costs, bosses and seed")
			var old_pressure: RefCounted=Pressure.new(original)
			var pressure: RefCounted=Pressure.new(chosen)
			if option.pace_id==0:
				t.equal(chosen.day_seconds,original.day_seconds,"recommended pace retains biome daylight")
				t.equal(pressure.count_for(5),old_pressure.count_for(5),"recommended pace retains fifth-night opposition")
			elif option.pace_id==1:
				t.truth(chosen.day_seconds>original.day_seconds and pressure.count_for(5)<old_pressure.count_for(5),"settler gives time and fewer reinforcements in every biome")
			else:
				t.truth(chosen.day_seconds<original.day_seconds and pressure.count_for(5)>old_pressure.count_for(5),"siege reduces preparation and intensifies every biome")
			t.equal(pressure.concurrent_limit,old_pressure.concurrent_limit,"pace cannot increase concurrent enemy or memory limits")
			t.truth(pressure.count_for(1000)<=72,"long journeys retain a bounded nightly wave")

func test_pacing_survives_travel_and_partial_night_continuation(t: SceneTree) -> void:
	var selected: Resource=load("res://data/journey_paces/siege.tres")
	var journey: RefCounted=Setup.create(base(),profiles(),selected.rules())
	var config: Dictionary=journey.configs[0]
	var sim: RefCounted=Campaign.new(config)
	var body: Dictionary={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
	sim.interact(sim.world.sites.hall)
	sim.clock.remaining=0.1
	sim.advance(0.2,-730)
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var saved: Dictionary=codec.capture(sim,config,body)
	var copy: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not copy.is_empty(),"siege first wave can be saved while spawning")
	if copy.is_empty():return
	for tick: int in range(30):
		sim.advance(1.0/30,-730);copy.session.advance(1.0/30,-730)
	t.truth(Rules.same(codec.capture(sim,config,body),codec.capture(copy.session,copy.config,body)),"saving mid-night does not alter following reinforcements")
	sim=Campaign.new(config)
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.frontier.city_level=1;sim.survival.armed=true
	sim.advance(0.1,30);sim.planet.claim_core();sim.planet.rocket_ready=true
	var trip: Dictionary=journey.prepare(sim,body,1)
	t.truth(not trip.is_empty(),"paced journey takes the real rocket route")
	if trip.is_empty():return
	t.equal(trip.config.journey_style,2,"new destination retains siege identity")
	t.equal(trip.session.clock.remaining,journey.configs[1].day_seconds,"arrival uses resolved destination daylight")
	trip.session.planet.rocket_ready=true
	var home: Dictionary=trip.journey.prepare(trip.session,body,0)
	t.truth(not home.is_empty(),"paced colony can be revisited")
	if not home.is_empty():t.truth(Rules.same(home.config,config),"return preserves exact original colony rules")

func test_unknown_pace_is_rejected_and_legacy_rules_are_unchanged(t: SceneTree) -> void:
	var config: Dictionary=base()
	var sim: RefCounted=Campaign.new(config)
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var body: Dictionary={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
	var saved: Dictionary=codec.capture(sim,config,body)
	var restored: Dictionary=codec.restore(saved)
	t.truth(not restored.is_empty(),"unlabelled original journey remains valid")
	if not restored.is_empty():t.truth(Rules.same(restored.config,config),"legacy daylight and enemy counts are not remapped")
	for invalid: Variant in [99,-1,0.5,"siege"]:
		var damaged: Dictionary=saved.duplicate(true)
		damaged.config.journey_style=invalid
		t.truth(codec.restore(damaged).is_empty(),"unknown or malformed pace is rejected")

func test_one_journey_cannot_restore_mixed_pace_labels(t: SceneTree) -> void:
	var journey: RefCounted=Setup.create(base(),profiles(),load("res://data/journey_paces/settler.tres").rules())
	var sim: RefCounted=Campaign.new(journey.configs[0])
	var packet: Dictionary=journey.capture(sim,{"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0})
	packet.configs[1].journey_style=2
	t.truth(Voyage.restore(packet).is_empty(),"inactive planet cannot silently switch the journey pace")
