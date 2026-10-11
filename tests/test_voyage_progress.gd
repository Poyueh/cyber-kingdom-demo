extends RefCounted
const Voyage=preload("res://application/star_voyage.gd")
const Campaign=preload("res://application/campaign_session.gd")
const Report=preload("res://application/voyage_progress.gd")
const NAMES: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]
const BODY={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
func trip() -> RefCounted:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules();config.seed=416;config.economy=tuning.economy_rules()
	var profiles: Array[Dictionary]=[]
	for name: String in NAMES:profiles.append(load("res://data/planets/"+name+".tres").rules())
	return Voyage.new(config,profiles)
func defeat_dragon(sim: RefCounted) -> void:
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim.raiders.clear();sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.frontier.city_level=1;sim.survival.armed=true;sim.advance(0.1,30)
func test_claiming_a_core_has_its_own_once_only_reward_signal(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	defeat_dragon(sim);var crystals: int=sim.pouch.amount
	t.truth(sim.interact(-185,"dragon_core"),"actual free interaction claims the earned core")
	t.equal(sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="planet_core_claimed").size(),1,"core has its own liberation signal rather than an ordinary chest burst")
	t.truth(not sim.interact(-185,"dragon_core"),"claimed core cannot be taken again")
	t.equal(sim.pouch.amount,crystals,"celebration does not create or spend currency")
	t.equal(sim.effects.filter(func(e: Dictionary)->bool:return e.kind=="planet_core_claimed").size(),1,"repeated input cannot replay liberation")
func test_chart_recognizes_partial_colony_and_hides_unvisited_merits(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	sim.interact(30,"hall")
	var report: Dictionary=Report.read(journey,sim,0)
	t.equal(report.get("known"),true,"the present colony has reviewable achievements")
	t.equal(report.get("settlement"),1,"lighting a fire is one real settlement step")
	t.equal(Report.read(journey,sim,1),{"known":false},"unvisited worlds do not reveal exploration or ruin counts")
func test_first_core_identifies_only_newly_opened_routes(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	t.equal(Report.newly_opened(journey,sim,0),[],"there is no route celebration before claiming a core")
	defeat_dragon(sim);sim.interact(-185,"dragon_core")
	t.equal(Report.newly_opened(journey,sim,0),[1,2],"forest core opens the actual desert and frost branches")

func complete_optional_goals(sim: RefCounted) -> void:
	for region: Dictionary in sim.frontier.regions:region.discovered=true
	for site: RefCounted in sim.trials.sites:sim.trials.unlock(site.id)
	if sim.mount_quest.enabled:sim.mount_quest.rotations.assign([1,2]);sim.mount_quest.recover()
	sim.frontier.city_level=3
func test_optional_achievements_use_real_progress_without_granting_rewards(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	var initial: Dictionary=Report.read(journey,sim,0)
	t.equal(initial.goals[1].count,0,"unsolved forest mysteries start empty")
	t.equal(initial.goals[1].total,3,"forest includes its separate mechanical mount circuit")
	t.truth(not initial.goals[2].complete,"unlit wilderness is not a completed settlement")
	complete_optional_goals(sim)
	var before: Dictionary=journey.capture(sim,BODY)
	var complete: Dictionary=Report.read(journey,sim,0)
	t.truth(complete.goals.all(func(goal: Dictionary)->bool:return goal.complete),"survey, ruins and settlement each earn their own seal")
	t.truth(not complete.core and not sim.planet.completed,"optional merit does not award a dragon core or victory")
	for id: int in range(7):Report.read(journey,sim,id)
	t.equal(journey.capture(sim,BODY),before,"reading all planet cards changes no world, currency or timers")
func test_away_colony_and_restored_journey_show_the_same_earned_merits(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	defeat_dragon(sim);complete_optional_goals(sim);sim.interact(-185,"dragon_core");sim.planet.rocket_ready=true
	var before: Dictionary=Report.read(journey,sim,0)
	var moved: Dictionary=journey.prepare(sim,BODY,1)
	t.truth(not moved.is_empty(),"real rocket transaction reaches the next world")
	if moved.is_empty():return
	t.equal(Report.read(moved.journey,moved.session,0),before,"inactive colony keeps its own merits without loading its simulation")
	var current: Dictionary=Report.read(moved.journey,moved.session,1)
	t.equal(current.settlement,0,"new planet does not inherit the old city's achievements")
	t.equal(current.goals[1].total,1,"desert has one local mystery, not the forest's three")
	t.equal(current.goals[1].count,0,"carrying a mount does not solve a desert ruin")
	var restored: Dictionary=Voyage.restore(JSON.parse_string(JSON.stringify(moved.journey.capture(moved.session,moved.body))))
	t.truth(not restored.is_empty(),"existing voyage format still restores normally")
	if restored.is_empty():return
	t.equal(Report.read(restored.journey,restored.session,0),before,"saved inactive achievements remain identical")
	t.equal(Report.read(restored.journey,restored.session,1),current,"saved current achievements remain identical")
	for tick: int in range(60):moved.session.advance(1.0/30,30);restored.session.advance(1.0/30,30)
	t.truth(preload("res://application/campaign_checkpoint_rules.gd").same(moved.journey.capture(moved.session,moved.body),restored.journey.capture(restored.session,moved.body)),"reading medals leaves the sixty-tick continuation unchanged")
func test_branch_order_announces_only_routes_that_really_unlock(t: SceneTree) -> void:
	var journey: RefCounted=trip();var sim: RefCounted=Campaign.new(journey.configs[0])
	var expected: Dictionary={0:[1,2],1:[3],3:[],2:[4],4:[5],5:[6],6:[]}
	for id: int in [0,1,3,2,4,5,6]:
		if id!=0:
			sim.planet.rocket_ready=true
			var moved: Dictionary=journey.prepare(sim,BODY,id)
			t.truth(not moved.is_empty(),"test follows a legal route to world "+str(id))
			if moved.is_empty():return
			journey=moved.journey;sim=moved.session
		defeat_dragon(sim);sim.interact(-185,"dragon_core")
		t.equal(Report.newly_opened(journey,sim,id),expected[id],"route announcement honors all prerequisite cores at world "+str(id))
		t.truth(not Report.read(journey,sim,id).goals[2].complete,"beating a dragon does not pretend the colony is fully built")
	journey.observe(sim)
	t.truth(sim.planet.completed,"seven cores still complete the expedition without optional seals")
