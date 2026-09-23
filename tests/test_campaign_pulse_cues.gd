extends RefCounted
## Sounds that repeat while something keeps happening: work strikes, footsteps,
## and the loops that hold under a gallop, a dragon and a charging seal.
const Session=preload("res://application/campaign_session.gd")
const PulsePath="res://presentation/campaign_pulse_cues.gd"
const LoopPath="res://presentation/campaign_loop_cues.gd"

func _working_person(sim, kind: String, at: float) -> void:
	sim.world.people.append({"x":at,"role":"engineer","hurt":0.0,"cooldown":0.0,"work_state":"work"})
	var index: int=sim.world.people.size()-1
	for node in sim.frontier.nodes:
		if node.kind==kind:
			node.worker=index
			node.x=at
			return
	var node=preload("res://domain/harvest_node.gd").new()
	node.kind=kind;node.x=at;node.worker=index;node.region=0
	sim.frontier.nodes.append(node)

func test_work_strikes_repeat_only_while_someone_works(t):
	t.truth(ResourceLoader.exists(PulsePath),"pulse cue chooser exists")
	if not ResourceLoader.exists(PulsePath):return
	var cues=load(PulsePath).new()
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	t.equal(cues.sample(sim,at,0.0,false).get("work_chop",0.0),0.0,"an idle camp makes no chopping")
	_working_person(sim,"tree",at)
	t.truth(cues.sample(sim,at,0.0,false).get("work_chop",0.0)>0.0,"a worker at a tree keeps chopping")
	sim.world.people[sim.world.people.size()-1].work_state="haul"
	t.equal(cues.sample(sim,at,0.0,false).get("work_chop",0.0),0.0,"carrying the load stops the chopping")

func test_each_trade_has_its_own_strike(t):
	var cues=load(PulsePath).new()
	for pair in [["tree","work_chop"],["stone","work_mine"],["herbs","work_harvest"]]:
		var sim=Session.new()
		var at: float=sim.world.sites.hall
		_working_person(sim,pair[0],at)
		t.truth(cues.sample(sim,at,0.0,false).get(pair[1],0.0)>0.0,"%s is worked as %s" % [pair[0],pair[1]])

func test_distant_work_stays_quiet(t):
	var cues=load(PulsePath).new()
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	_working_person(sim,"tree",at)
	t.equal(cues.sample(sim,at+5000.0,0.0,false).get("work_chop",0.0),0.0,"work far across the map is not heard")

func test_footsteps_follow_actual_travel_speed(t):
	var cues=load(PulsePath).new()
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	cues.sample(sim,at,0.016,false)
	var running: Dictionary=cues.sample(sim,at+4.0,0.016,false)
	t.truth(running.get("footstep",0.0)>0.0,"running lays down a fast step")
	t.equal(running.get("footstep_slow",0.0),0.0,"running is not also a careful step")
	var walking: Dictionary=cues.sample(sim,at+4.6,0.016,false)
	t.truth(walking.get("footstep_slow",0.0)>0.0,"a slow pace steps carefully")
	t.equal(walking.get("footstep",0.0),0.0,"a slow pace is not a run")
	var still: Dictionary=cues.sample(sim,at+4.6,0.016,false)
	t.equal(still.get("footstep",0.0),0.0,"standing still makes no steps")
	t.equal(still.get("footstep_slow",0.0),0.0,"standing still makes no careful steps either")

func test_pause_stops_every_pulse(t):
	var cues=load(PulsePath).new()
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	_working_person(sim,"tree",at)
	var paused: Dictionary=cues.sample(sim,at,0.016,true)
	for kind in paused:
		t.equal(paused[kind],0.0,"pause silences %s" % kind)

func test_loops_hold_under_a_gallop_a_dragon_and_a_seal(t):
	t.truth(ResourceLoader.exists(LoopPath),"loop cue chooser exists")
	if not ResourceLoader.exists(LoopPath):return
	var cues=load(LoopPath).new()
	var sim=Session.new()
	sim.life.enabled=true
	var at: float=sim.world.sites.hall
	t.equal(cues.sample(sim,at,0.016,false).get("horse_gallop",0.0),0.0,"walking on foot is not a gallop")
	sim.frontier.drill_level=3
	cues.sample(sim,at,0.016,false)
	t.truth(cues.sample(sim,at+5.0,0.016,false).get("horse_gallop",0.0)>0.0,"a moving rider gallops")
	t.equal(cues.sample(sim,at+5.0,0.016,false).get("horse_gallop",0.0),0.0,"a halted rider stops galloping")
	var dragon=sim._spawn_raider()
	dragon.kind="dragon";dragon.x=at
	sim.raiders.append(dragon)
	t.truth(cues.sample(sim,at,0.016,false).get("dragon_wing",0.0)>0.0,"a living dragon beats its wings")
	dragon.fighter.hp=0
	t.equal(cues.sample(sim,at,0.016,false).get("dragon_wing",0.0),0.0,"a fallen dragon stops beating")
	if sim.mission.rifts.is_empty():sim.mission.add_rift(1,at+400)
	var rift: Dictionary=sim.mission.rifts[0]
	rift.progress=2.0
	t.truth(cues.sample(sim,rift.x,0.016,false).get("seal_progress",0.0)>0.0,"a charging seal hums")
	rift.sealed=true
	t.equal(cues.sample(sim,rift.x,0.016,false).get("seal_progress",0.0),0.0,"a closed seal stops humming")
	rift.sealed=false
	t.equal(cues.sample(sim,rift.x+4000.0,0.016,false).get("seal_progress",0.0),0.0,"a seal charging far away is not heard")
