extends RefCounted
const Campaign = preload("res://application/campaign_session.gd")
const Codec = preload("res://application/campaign_snapshot.gd")
const BODY: Dictionary = {"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}

func rules(planet: int = 0) -> Dictionary:
	var tuning: Resource = load("res://data/campaign.tres")
	var config: Dictionary = tuning.campaign_rules()
	config.merge({"seed":103,"economy":tuning.economy_rules(),"planet_id":planet,"night_seconds":10000.0},true)
	return config

func dusk(config: Dictionary, day: int) -> RefCounted:
	var sim: RefCounted = Campaign.new(config)
	sim.world.people.clear()
	sim.clock.day = day
	sim.clock.survived = day - 1
	sim.clock.remaining = 0.01
	return sim

func arrivals(sim: RefCounted, duration: int = 650) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tick: int in range(duration):
		sim.advance(0.1,30.0)
		for enemy: Dictionary in sim.raiders:
			if not enemy.fighter.is_alive(): continue
			result.append({"side":enemy.side,"time":tick*0.1,"x":enemy.x})
			enemy.fighter.hp = 0
	return result

func test_fourth_night_concentrates_pressure_without_creating_more_enemies(t: SceneTree) -> void:
	var sim: RefCounted = dusk(rules(),4)
	t.equal(sim.raid_pressure(),{"left":7,"right":2},"dusk reveals a western main force and an eastern probing force")
	var force: Array[Dictionary] = arrivals(sim)
	t.equal(force.size(),9,"tactics use the existing nine-enemy budget")
	t.equal(force.filter(func(e: Dictionary)->bool:return e.side==-1).size(),7,"the forecast becomes real attackers from the west gate")
	for enemy: Dictionary in force:
		t.truth(absf(enemy.x-sim.mission.entry_x(enemy.side))<15,"enemies still arrive at their actual portal")

func test_pincer_waits_before_sending_the_opposite_gate(t: SceneTree) -> void:
	var sim: RefCounted = dusk(rules(),5)
	var force: Array[Dictionary] = arrivals(sim)
	t.equal(force.size(),11,"pincer redistributes the existing eleven attackers")
	if force.size()!=11:return
	t.truth(force.slice(0,6).all(func(e: Dictionary)->bool:return e.side==-1),"first wave approaches only from the western gate")
	t.truth(force.slice(6).all(func(e: Dictionary)->bool:return e.side==1),"second wave approaches from the opposite gate")
	t.truth(force[6].time-force[5].time>=17.9,"there is a real eighteen-second regroup interval")

func test_opening_nights_and_sealed_portals_keep_fair_boundaries(t: SceneTree) -> void:
	for day: int in [1,2,3]:
		var sim: RefCounted=dusk(rules(),day)
		var force: Array[Dictionary]=arrivals(sim,250)
		t.equal(force.size(),1+day*2,"opening three nights retain their force size")
		t.equal(force[0].side,1,"onboarding keeps its original approach")
	var sealed: RefCounted=dusk(rules(),4)
	sealed.mission.rifts[0].sealed=true
	t.equal(sealed.raid_pressure(),{"left":0,"right":2},"sealed main gate cancels seven attackers without moving them east")
	t.equal(arrivals(sealed).size(),2,"only the eastern probe actually arrives")
	sealed.mission.rifts[1].sealed=true
	t.equal(sealed.night_watch(),{},"both sealed gates stop promising a nightly attack")

func test_mid_pincer_save_preserves_regroup_and_capacity(t: SceneTree) -> void:
	var config: Dictionary=rules()
	var sim: RefCounted=dusk(config,11)
	for tick: int in range(330):sim.advance(0.1,30.0)
	t.equal(sim.raiders.size(),12,"first wave fills the existing battlefield limit")
	t.truth(sim._spawn_timer>10,"save is taken during the actual regroup interval")
	var codec: RefCounted=Codec.new()
	var saved: Dictionary=codec.capture(sim,config,BODY)
	var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not loaded.is_empty(),"in-flight pincer is a valid resumable checkpoint")
	if loaded.is_empty():return
	for tick: int in range(300):
		sim.advance(0.1,30);loaded.session.advance(0.1,30)
	t.equal(sim.raiders.size(),12,"reinforcements still wait when the battlefield is full")
	for session: RefCounted in [sim,loaded.session]:session.raiders[0].fighter.hp=0
	for tick: int in range(30):
		sim.advance(0.1,30);loaded.session.advance(0.1,30)
	t.equal(sim.raiders.size(),12,"a freed slot admits one waiting enemy")
	t.equal(sim.raiders.back().side,1,"the admitted enemy belongs to the opposite wave")
	t.truth(preload("res://tests/test_campaign_snapshot.gd").new().equivalent(codec.capture(sim,config,BODY),codec.capture(loaded.session,config,BODY)),"loading mid-regroup matches uninterrupted play")

func test_forecast_warns_early_without_spending_or_advancing_the_world(t: SceneTree) -> void:
	var sim: RefCounted=dusk(rules(),4)
	sim.clock.remaining=76
	t.equal(sim.night_watch(),{},"no intrusive full-day warning")
	sim.clock.remaining=75
	var codec: RefCounted=Codec.new()
	var before: Dictionary=codec.capture(sim,rules(),BODY)
	var advice: Dictionary=sim.night_watch()
	t.equal(advice.get("key"),"night.pressure.west","western pressure is explained seventy-five seconds before dusk")
	t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(before,codec.capture(sim,rules(),BODY)),"reading tactical advice cannot change gameplay")
	sim.mission.outcome="defeat"
	t.equal(sim.night_watch(),{},"defeated journeys show no tactical prompts")

func test_old_v18_journey_keeps_alternating_gates_and_rejects_future_rules(t: SceneTree) -> void:
	var config: Dictionary=rules()
	for key: String in config.keys():
		if key.begins_with("night_pattern_"):config.erase(key)
	var sim: RefCounted=dusk(config,5)
	var codec: RefCounted=Codec.new()
	var old: Dictionary=codec.capture(sim,config,BODY);old.version=18
	var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(old)))
	t.truth(not loaded.is_empty(),"genuine v18 rule shape remains playable")
	if loaded.is_empty():return
	var force: Array[Dictionary]=arrivals(loaded.session)
	t.equal(force.size(),11,"legacy total remains eleven")
	t.equal(force[1].side,-1,"legacy still alternates instead of adopting a new first wave")
	t.truth(force[6].time-force[5].time<3,"legacy has no new regroup pause")
	t.equal(codec.capture(loaded.session,loaded.config,BODY).version,19,"legacy resaves in the guarded current schema")
	var future: Dictionary=codec.capture(dusk(rules(),5),rules(),BODY);future.version=18
	t.truth(codec.restore(future).is_empty(),"new tactics cannot masquerade as old data")
	for missing: String in ["night_pattern_warning","night_pattern_gap"]:
		var corrupt: Dictionary=codec.capture(dusk(rules(),5),rules(),BODY);corrupt.config.erase(missing)
		t.truth(codec.restore(corrupt).is_empty(),"partial tactics cannot silently load a different invasion")

func test_each_planet_forecast_matches_its_own_arrivals(t: SceneTree) -> void:
	var profiles: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]
	for planet: int in range(7):
		var config: Dictionary=rules(planet)
		config.merge(load("res://data/planets/%s.tres"%profiles[planet]).rules(),true)
		var sim: RefCounted=dusk(config,4)
		var expected: Dictionary=sim.raid_pressure()
		var force: Array[Dictionary]=arrivals(sim,800)
		t.equal(force.filter(func(e: Dictionary)->bool:return e.side==-1).size(),expected.left,"planet western forecast matches actual gate arrivals")
		t.equal(force.filter(func(e: Dictionary)->bool:return e.side==1).size(),expected.right,"planet eastern forecast matches actual gate arrivals")
		var repeat: RefCounted=dusk(config,4)
		t.equal(arrivals(repeat,800),force,"same seed and inputs produce identical timing and positions")
