extends RefCounted
## The last stragglers: arrows landing, crystals settling, deliveries, the dusk
## warning and the guide's farewell.
const Session=preload("res://application/campaign_session.gd")
const Cues=preload("res://presentation/campaign_audio_cues.gd")

func _primed(sim):
	var cues=Cues.new()
	cues.sample(sim,sim.world.sites.hall,false)
	return cues

func test_a_shot_that_lands_is_heard_hitting(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	var raider=sim._spawn_raider()
	raider.x=at
	sim.raiders.append(raider)
	var cues=_primed(sim)
	sim.effects.append({"kind":"bolt","x":at,"to":at,"life":0.18})
	raider.fighter.hp-=12
	var shot: Array=cues.sample(sim,at,false)
	t.truth("bow_shot" in shot,"the bow is heard releasing")
	t.truth("arrow_hit" in shot,"the arrow is heard landing")
	sim.effects.clear()
	raider.fighter.hp-=12
	t.truth(not ("arrow_hit" in cues.sample(sim,at,false)),"a sword blow is not an arrow landing")

func test_crystals_settle_and_are_handed_over(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.pouch.burst(3,at)
	var cues=_primed(sim)
	for gem in sim.pouch.drops:
		gem.vx=0.0;gem.vy=0.0;gem.grace=0.0
	t.truth("crystal_land" in cues.sample(sim,at,false),"crystals coming to rest are heard landing")
	t.equal(cues.sample(sim,at,false).count("crystal_land"),0,"resting crystals do not keep landing")
	sim.world.people.append({"x":at,"role":"engineer","hurt":0.0,"cooldown":0.0,"crystals":4})
	cues.sample(sim,at,false)
	sim.world.people[sim.world.people.size()-1].crystals=0
	sim.pouch.amount+=4
	t.truth("handoff" in cues.sample(sim,at,false),"a worker handing crystals over is heard")

func test_dusk_warns_once_a_day(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.clock.remaining=40.0
	var cues=_primed(sim)
	sim.clock.remaining=25.0
	t.truth("raid_warning" in cues.sample(sim,at,false),"the watchtower warns before dusk")
	sim.clock.remaining=12.0
	t.equal(cues.sample(sim,at,false).count("raid_warning"),0,"the horn does not sound every frame")
	sim.clock.is_night=true
	sim.clock.is_night=false
	sim.clock.day+=1
	sim.clock.remaining=25.0
	t.truth("raid_warning" in cues.sample(sim,at,false),"the next day warns again")

func test_the_guide_says_goodbye_once(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	var cues=_primed(sim)
	sim.spirit.opening_finished=true
	t.truth("farewell" in cues.sample(sim,at,false),"the guide leaving is heard once")
	t.equal(cues.sample(sim,at,false).count("farewell"),0,"a departed guide does not keep leaving")

func test_a_restored_run_states_none_of_these(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.spirit.opening_finished=true
	sim.clock.remaining=20.0
	sim.world.people.append({"x":at,"role":"engineer","hurt":0.0,"cooldown":0.0,"crystals":0})
	var cues=Cues.new()
	t.equal(cues.sample(sim,at,false),[],"opening a saved run announces nothing")
