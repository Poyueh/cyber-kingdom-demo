extends RefCounted
## Every event the v002 set gained a sound for must fire from the real model,
## once per occurrence, and never on a restored run.
const Session=preload("res://application/campaign_session.gd")
const Cues=preload("res://presentation/campaign_audio_cues.gd")

func _primed(sim):
	var cues=Cues.new()
	cues.sample(sim,sim.world.sites.hall,false)
	return cues

func test_world_effects_each_get_their_own_voice(t):
	var sim=Session.new()
	var cues=_primed(sim)
	var at: float=sim.world.sites.hall
	var expected={"portal_spawn":"portal_spawn","dragon_arrival":"dragon_arrival",
		"dragon_fire":"dragon_fire","module_pickup":"module_pickup",
		"module_equipped":"module_equip","module_stored":"module_store",
		"sword_recovered":"sword_recover","bolt":"bow_shot","tower_arrow":"bow_shot",
		"tower_laser":"tower_laser","core_hit":"core_hit"}
	for kind in expected:
		sim.effects.clear()
		sim.effects.append({"kind":kind,"x":at,"life":0.5})
		t.truth(expected[kind] in cues.sample(sim,at,false),
			"%s is heard as %s" % [kind,expected[kind]])

func test_absorbed_damage_and_growth_are_told_apart(t):
	var sim=Session.new()
	var cues=_primed(sim)
	var at: float=sim.world.sites.hall
	sim.hero.invulnerability_remaining=0
	sim.hero.shield=40
	sim.hero.take_damage(10)
	var absorbed: Array=cues.sample(sim,at,false)
	t.truth("shield" in absorbed,"a blow the shield eats sounds like a deflection")
	t.truth(not ("hurt" in absorbed),"a deflected blow is not the wounded sound")
	sim.hero.shield=0
	sim.hero.invulnerability_remaining=0
	sim.hero.take_damage(10)
	t.truth("hurt" in cues.sample(sim,at,false),"a blow that reaches the knight still wounds")
	sim.frontier.city_level=1
	t.truth("build" in cues.sample(sim,at,false),"founding the camp is heard as construction")
	sim.frontier.city_level=2
	var grown: Array=cues.sample(sim,at,false)
	t.truth("upgrade" in grown,"growing past the first level has its own ceremony")
	t.truth(not ("build" in grown),"growth is not confused with finishing a building")

func test_losing_crystals_sword_and_life_are_audible(t):
	var sim=Session.new()
	var cues=_primed(sim)
	var at: float=sim.world.sites.hall
	sim.survival.enabled=true
	sim.survival.armed=true
	sim.pouch.amount=9
	cues.sample(sim,at,false)
	sim.survival.hits+=1
	sim.pouch.amount-=3
	sim.pouch.burst(3,at)
	t.truth("crystal_drop" in cues.sample(sim,at,false),"a hit is heard knocking crystals out of the pouch")
	t.equal(cues.sample(sim,at,false).count("crystal_drop"),0,"the spilled crystals do not keep sounding")
	sim.survival.armed=false
	sim.survival.sword_on_ground=true
	t.truth("sword_drop" in cues.sample(sim,at,false),"losing the sword rings out once")
	t.equal(cues.sample(sim,at,false).count("sword_drop"),0,"the dropped sword does not ring every frame")
	sim.hero.hp=0
	t.truth("death" in cues.sample(sim,at,false),"the knight falling is heard")

func test_dawn_is_marked_once_per_survived_night(t):
	var sim=Session.new()
	var cues=_primed(sim)
	var at: float=sim.world.sites.hall
	sim.clock.survived+=1
	t.truth("dawn" in cues.sample(sim,at,false),"surviving a night greets the sunrise")
	t.equal(cues.sample(sim,at,false).count("dawn"),0,"the sunrise is not repeated all morning")

func test_a_restored_run_stays_silent_about_its_history(t):
	var sim=Session.new()
	sim.frontier.city_level=3
	sim.clock.survived=2
	sim.survival.enabled=true
	sim.survival.sword_on_ground=true
	sim.effects.append({"kind":"portal_spawn","x":sim.world.sites.hall,"life":0.6})
	var cues=Cues.new()
	t.equal(cues.sample(sim,sim.world.sites.hall,false),[],"loading a run replays none of what already happened")
