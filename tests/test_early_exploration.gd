extends RefCounted
const Fixture=preload("res://tests/test_trail_encounters.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Guide=preload("res://application/campaign_guide.gd")
const Codec=preload("res://application/campaign_snapshot.gd")
const Rules=preload("res://application/campaign_checkpoint_rules.gd")
const Audio=preload("res://presentation/campaign_audio_cues.gd")
const BODY={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
func quiet_world() -> RefCounted:
	var sim: RefCounted=Campaign.new(Fixture.new().journey(617).configs[0])
	sim.frontier.city_level=1;sim.survival.armed=true;sim.pouch.amount=0
	sim.merchant.enabled=false;sim.world.people.clear()
	for node: RefCounted in sim.frontier.nodes:node.collected=true
	return sim
func test_supply_advice_includes_only_discovered_available_trail_rewards(t: SceneTree) -> void:
	var sim: RefCounted=quiet_world()
	var quiet: RefCounted=sim.trails.sites[1]
	t.truth(Guide.funding_hint(sim,quiet.x).get("key","")!="trail:1","unknown roadside reward is not revealed by advice")
	sim.advance(1.0/30,quiet.x)
	var before: Dictionary=sim.trails.capture()
	var hint: Dictionary=Guide.funding_hint(sim,quiet.x)
	t.equal(hint.get("key"),"trail:1","empty pouch points to the real available free discovery")
	t.equal(hint.get("action"),"open","free cache is opened, never paid for")
	t.truth(Rules.same(before,sim.trails.capture()),"reading guidance cannot claim or reveal rewards")
	t.truth(sim.interact(quiet.x,"trail:1"),"guided identity is accepted by ordinary interaction")
	sim.pouch.drops.clear()
	t.truth(Guide.funding_hint(sim,quiet.x).get("key","")!="trail:1","claimed find is never promised twice")
	var nest: RefCounted=sim.trails.sites[0]
	sim.advance(1.0/30,nest.x)
	t.truth(Guide.funding_hint(sim,nest.x).get("key","")!="trail:0","empty bag is not directed to a guarded reward")
	for enemy: Dictionary in sim.raiders:enemy.fighter.hp=0
	sim.advance(1.0/30,nest.x)
	t.equal(Guide.funding_hint(sim,nest.x).get("key"),"trail:0","a cleared nest becomes a known supply option")
func test_forest_first_fight_allows_read_evade_and_counter(t: SceneTree) -> void:
	var sim: RefCounted=quiet_world();sim.pouch.amount=6
	t.equal(sim.raiders.size(),1,"forest introduces one beast before later paired encounters")
	var home: float=sim.trails.sites[0].x
	var unit: RefCounted=sim.trails.units[0]
	for tick: int in range(90):
		sim.advance(1.0/30,home-45)
		if unit.phase==1:break
	t.equal(unit.phase,1,"approaching the optional nest starts a visible tell")
	for tick: int in range(30):sim.advance(1.0/30,home-45)
	t.equal(unit.phase,1,"first attack stays readable for a full second")
	var bag: int=sim.pouch.amount
	for tick: int in range(40):
		sim.advance(1.0/30,home-250)
		if unit.phase==3:break
	t.equal(unit.phase,3,"committed attack resolves into recovery")
	t.equal(sim.pouch.amount,bag,"walking out of the locked strike preserves crystals")
	for tick: int in range(60):sim.advance(1.0/30,home-250)
	t.equal(unit.phase,3,"a new player still has a counterattack window after two seconds")
	var enemy: Dictionary=sim.raiders[0]
	for cut: int in range(2):
		sim.hero.facing=1;sim.hero.start_attack()
		for tick: int in range(28):
			sim.advance(1.0/30,enemy.x-24);sim.strike_from(enemy.x-24,430)
	t.truth(not enemy.fighter.is_alive(),"two ordinary opening sword cuts clear the lone introductory beast")
	t.truth(sim.trails.available(0),"winning opens the existing finite reward")
func test_first_three_dusks_warn_explorers_without_recalling_the_ghost(t: SceneTree) -> void:
	var config: Dictionary=Fixture.new().journey(617).configs[0]
	var sim: RefCounted=Campaign.new(config)
	sim.frontier.city_level=1;sim.survival.armed=true
	sim.spirit.opening_finished=true;sim.spirit.expires_tick=0
	for day: int in [1,2,3]:
		sim.clock.day=day;sim.clock.survived=day-1;sim.clock.remaining=90
		sim.advance(1.0/30,sim.trails.sites[1].x)
		t.equal(sim.night_watch(),{},"no all-day reminder on day "+str(day))
		var cues: RefCounted=Audio.new();cues.sample(sim,sim._hero_x,false)
		sim.clock.remaining=75
		var before: Dictionary=Codec.new().capture(sim,config,BODY)
		var hint: Dictionary=sim.night_watch()
		t.equal(hint.get("key"),"night.return","early explorer gets a brief return cue before the old 30-second alarm")
		t.equal(hint.get("lead"),-1,"eastbound explorer is pointed west toward camp")
		t.truth(cues.sample(sim,sim._hero_x,false).has("raid_warning"),"return cue has one audible warning")
		t.truth(not cues.sample(sim,sim._hero_x,false).has("raid_warning"),"the warning sound does not repeat every frame")
		t.equal(sim.spirit.advice(sim,sim._hero_x),{},"return cue does not bring back dialogue")
		t.truth(Rules.same(before,Codec.new().capture(sim,config,BODY)),"warning does not change timers or save state")
		sim.advance(1.0/30,sim.trails.sites[0].x)
		t.equal(sim.night_watch().get("lead"),1,"westbound explorer is pointed east toward camp")
		sim.advance(1.0/30,sim.world.sites.hall)
		t.equal(sim.night_watch(),{},"returning inside the work area removes the reminder")
	sim.clock.remaining=60;sim.advance(1.0/30,sim.trails.sites[1].x)
	sim.mission.rifts[0].sealed=true;sim.mission.rifts[1].sealed=true
	t.equal(sim.night_watch(),{},"sealed gates do not promise an incoming attack")
func test_old_forest_encounter_stays_a_pair_after_loading(t: SceneTree) -> void:
	var old: Dictionary=Fixture.new().journey(617).configs[0]
	old.trail_guard_count=2;old.trail_windup_seconds=0.85;old.trail_recovery_seconds=1.8
	var sim: RefCounted=Campaign.new(old)
	var saved: Dictionary=Codec.new().capture(sim,old,BODY)
	var loaded: Dictionary=Codec.new().restore(JSON.parse_string(JSON.stringify(saved)))
	t.truth(not loaded.is_empty(),"previous forest tuning remains a valid checkpoint")
	if loaded.is_empty():return
	t.equal(loaded.session.raiders.size(),2,"existing journey retains both original guardians")
	t.truth(Rules.same(old,loaded.config),"loading never overwrites resolved encounter balance")

func test_new_local_day_rearms_warning_after_restart_or_travel(t: SceneTree) -> void:
	var audio: RefCounted=Audio.new()
	for visit: int in range(2):
		var sim: RefCounted=quiet_world()
		sim.clock.remaining=90;sim.advance(1.0/30,sim.trails.sites[1].x)
		audio.sample(sim,sim._hero_x,false)
		sim.clock.remaining=75
		t.truth(audio.sample(sim,sim._hero_x,false).has("raid_warning"),"new session can warn on its own first day, visit "+str(visit))
