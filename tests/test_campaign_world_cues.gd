extends RefCounted
## The remaining campaign events: enemies, residents, milestones and spending.
const Session=preload("res://application/campaign_session.gd")
const Cues=preload("res://presentation/campaign_audio_cues.gd")

func _primed(sim):
	var cues=Cues.new()
	cues.sample(sim,sim.world.sites.hall,false)
	return cues

func test_enemies_warn_strike_and_steal(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	var raider=sim._spawn_raider()
	raider.x=at
	sim.raiders.append(raider)
	var cues=_primed(sim)
	raider.windup=0.6
	t.truth("enemy_telegraph" in cues.sample(sim,at,false),"a raider winding up warns the player")
	t.equal(cues.sample(sim,at,false).count("enemy_telegraph"),0,"the warning does not repeat every frame")
	raider.windup=0.0
	t.truth("enemy_attack" in cues.sample(sim,at,false),"the blow that follows is heard")
	raider["carried_crystals"]=1
	t.truth("enemy_grab" in cues.sample(sim,at,false),"a raider snatching a crystal is heard")
	t.equal(cues.sample(sim,at,false).count("enemy_grab"),0,"carrying it away does not keep sounding")

func test_gatekeepers_and_the_seal_are_announced(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	if sim.mission.rifts.is_empty():sim.mission.add_rift(1,at+400)
	var cues=_primed(sim)
	sim.mission.rifts[0].wardens_spawned=true
	t.truth("gatekeeper_appear" in cues.sample(sim,at,false),"the guardians arriving is heard once")
	t.equal(cues.sample(sim,at,false).count("gatekeeper_appear"),0,"standing guardians do not keep arriving")

func test_residents_taking_tools_and_blows(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	if sim.world.people.is_empty():sim.world.people.append({"x":at,"role":"wanderer","hurt":0.0,"cooldown":0.0})
	var person: Dictionary=sim.world.people[0]
	person.x=at
	var cues=_primed(sim)
	person.role="engineer"
	t.truth("tool_pickup" in cues.sample(sim,at,false),"a resident taking up work is heard")
	person.hurt=1.0
	t.truth("resident_hit" in cues.sample(sim,at,false),"a resident being struck is heard")
	t.equal(cues.sample(sim,at,false).count("resident_hit"),0,"a hurt resident is not struck every frame")

func test_milestones_and_riding(t):
	var sim=Session.new()
	sim.life.enabled=true
	var at: float=sim.world.sites.hall
	var cues=_primed(sim)
	sim.frontier.drill_level=3
	t.truth(sim.mounted(),"the riding rule agrees the knight may ride")
	t.truth("mount" in cues.sample(sim,at,false),"climbing onto the warhorse is heard")
	t.equal(cues.sample(sim,at,false).count("mount"),0,"riding on does not remount every frame")

func test_investment_completion_is_told_from_a_refund(t):
	var sim=Session.new()
	sim.life.enabled=true
	var at: float=sim.world.sites.hall
	var cues=_primed(sim)
	sim.investments["hall"]=1
	cues.sample(sim,at,false)
	sim.investments.erase("hall")
	t.truth("slot_complete" in cues.sample(sim,at,false),"filling the last slot completes audibly")
	sim.investments["hall"]=2
	cues.sample(sim,at,false)
	sim.cancel_investment("hall",at)
	var refunded: Array=cues.sample(sim,at,false)
	t.truth("slot_refund" in refunded,"crystals handed back are heard returning")
	t.truth(not ("slot_complete" in refunded),"a refund is never mistaken for a completion")

func test_a_restored_world_states_none_of_it(t):
	var sim=Session.new()
	var at: float=sim.world.sites.hall
	sim.life.enabled=true
	sim.frontier.drill_level=3
	if sim.mission.rifts.is_empty():sim.mission.add_rift(1,at+400)
	sim.mission.rifts[0].wardens_spawned=true
	if sim.world.people.is_empty():sim.world.people.append({"x":at,"role":"engineer","hurt":1.0,"cooldown":0.0})
	var cues=Cues.new()
	t.equal(cues.sample(sim,at,false),[],"loading a run announces none of its standing state")
