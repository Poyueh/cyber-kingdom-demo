extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const BODY: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func rules() -> Dictionary:
	var tuning: Resource = load("res://data/campaign.tres")
	var config: Dictionary = tuning.campaign_rules()
	config.merge({"seed":742601,"economy":tuning.economy_rules(),"night_seconds":10000.0},true)
	return config

func at_dusk(config: Dictionary, day: int) -> RefCounted:
	var sim: RefCounted = Campaign.new(config)
	sim.world.people.clear()
	sim.clock.day = day
	sim.clock.survived = day-1
	sim.clock.remaining = 0.01
	return sim

func test_new_journey_night_forecast_matches_real_spawns_beyond_day_ten(t) -> void:
	for pair in [[1,3],[2,5],[3,7],[7,15],[10,21],[11,23],[40,60]]:
		var sim: RefCounted = at_dusk(rules(),pair[0])
		var forecast: Dictionary = sim.raid_pressure()
		t.equal(forecast.left + forecast.right,pair[1],"dusk forecasts the new nightly force")
		var spawned: int = 0
		for tick in range(pair[1]*30):
			sim.advance(0.1,30.0)
			for enemy in sim.raiders:
				if enemy.fighter.is_alive():
					spawned += 1
					enemy.fighter.hp = 0
			if tick == 0:
				t.equal(sim.clock.day,pair[0],"pending invasion cannot skip to tomorrow")
		t.equal(spawned,pair[1],"actual portal arrivals match the forecast")

func test_large_night_waits_for_enemy_slots_and_resumes_after_a_kill(t) -> void:
	var sim: RefCounted = at_dusk(rules(),20)
	for tick in range(80): sim.advance(0.5,30.0)
	t.equal(sim.raiders.size(),12,"late-night reinforcements wait at the portals")
	t.truth(sim._spawn_remaining>0,"queue is retained while the battlefield is full")
	sim.raiders[0].fighter.hp = 0
	sim.advance(0.1,30.0)
	sim.advance(3.0,30.0)
	t.equal(sim.raiders.size(),12,"a casualty frees a slot for the waiting force")

func test_resource_economy_requires_work_instead_of_rapid_farming(t) -> void:
	var sim: RefCounted = Campaign.new(rules())
	sim.world.people.clear()
	for node in sim.frontier.nodes:
		if node.kind != "cache": continue
		sim.advance(0.1,node.x,node.y)
		t.truth(sim.interact(node.x),"knight still opens treasure directly")
		t.equal(sim.pouch.ground_total(),4,"treasure bursts with four finite crystals")
		break
	sim.frontier.farm_active = true
	sim.frontier.advance_farm(12.0,1)
	t.equal(sim.frontier.food,0,"one farmer no longer produces every twelve seconds")
	sim.frontier.advance_farm(12.0,1)
	t.equal(sim.frontier.food,1,"twenty-four seconds of work produces one crystal")

func test_pressure_resume_is_identical_and_legacy_journeys_keep_their_rules(t) -> void:
	var config: Dictionary = rules()
	var sim: RefCounted = at_dusk(config,11)
	for tick in range(63): sim.advance(0.1,30.0)
	var codec: RefCounted = Codec.new()
	var restored: Dictionary = codec.restore(JSON.parse_string(JSON.stringify(codec.capture(sim,config,BODY))))
	t.truth(not restored.is_empty(),"partial nightly invasion can be saved and restored")
	if restored.is_empty(): return
	for tick in range(37):
		sim.advance(0.1,30.0)
		restored.session.advance(0.1,30.0)
	# JSON normalizes numeric representations; use the existing snapshot tolerance.
	var comparison: RefCounted = preload("res://tests/test_campaign_snapshot.gd").new()
	t.truth(comparison.equivalent(codec.capture(restored.session,config,BODY),codec.capture(sim,config,BODY)),"same seed and interrupted timeline produce equivalent state")
	var legacy: RefCounted = at_dusk({},11)
	var forecast: Dictionary = legacy.raid_pressure()
	t.equal(forecast.left+forecast.right,12,"existing journeys retain their original cap")
	var broken: Dictionary = codec.capture(sim,config,BODY)
	broken.config.erase("night_growth")
	t.truth(codec.restore(broken).is_empty(),"incomplete difficulty settings cannot load as a different journey")

func test_sealed_gate_cancels_only_its_own_reinforcements(t) -> void:
	var sim: RefCounted = at_dusk(rules(),3)
	sim.mission.rifts[0].sealed = true
	var forecast: Dictionary = sim.raid_pressure()
	t.equal(forecast.left,0,"sealed left gate has no promised reinforcements")
	t.equal(forecast.right,4,"open right gate keeps its own share")
	var spawned: int = 0
	for tick in range(200):
		sim.advance(0.1,30.0)
		for enemy in sim.raiders:
			if not enemy.fighter.is_alive(): continue
			spawned += 1
			t.equal(enemy.side,1,"only the still-open portal sends enemies")
			enemy.fighter.hp = 0
	t.equal(spawned,4,"sealing a side does not relocate its cancelled attackers")
