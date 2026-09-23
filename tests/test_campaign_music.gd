extends RefCounted
const Session=preload("res://application/campaign_session.gd")
const Path="res://presentation/campaign_music_cues.gd"

func _cues():
	return load(Path).new()

func test_music_follows_place_and_time_of_day(t):
	t.truth(ResourceLoader.exists(Path),"campaign music cue chooser exists")
	if not ResourceLoader.exists(Path):return
	var cues=_cues()
	t.equal(cues.sample(null,0.0,false).track,"title","no session keeps the title theme")
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	t.equal(cues.sample(sim,hall+2400.0,false).track,"day_explore","daytime away from the refuge explores")
	sim.interact(hall)
	sim.interact(hall)
	t.truth(sim.frontier.city_level>0,"camp is established for the refuge theme")
	t.equal(cues.sample(sim,hall,false).track,"day_refuge","daytime beside a built refuge settles")
	t.equal(cues.sample(sim,hall+2400.0,false).track,"day_explore","walking away returns to the exploring theme")

func test_night_adds_a_raid_layer_only_while_enemies_live(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	sim.clock.is_night=true
	var quiet: Dictionary=cues.sample(sim,hall,false)
	t.equal(quiet.track,"night_watch","night without enemies watches the walls")
	t.equal(quiet.layer,"","a quiet night carries no combat layer")
	sim.raiders.append(sim._spawn_raider())
	var raid: Dictionary=cues.sample(sim,hall,false)
	t.equal(raid.track,"night_watch","the raid keeps the night bed underneath")
	t.equal(raid.layer,"night_raid","a living raider adds the combat layer")
	sim.raiders.clear()
	t.equal(cues.sample(sim,hall,false).layer,"","clearing the raid drops the combat layer")

func test_dragon_and_results_take_over_the_score(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	sim.clock.is_night=true
	sim.raiders.append(sim._spawn_raider())
	sim.mission.dragon_summoned=true
	var boss: Dictionary=cues.sample(sim,hall,false)
	t.equal(boss.track,"dragon_boss","a summoned dragon replaces the night music")
	t.equal(boss.layer,"","the dragon theme carries no raid layer")
	sim.mission.outcome="victory"
	var won: Dictionary=cues.sample(sim,hall,false)
	t.equal(won.sting,"victory_theme","winning plays the victory piece")
	t.equal(won.track,"","a result stops the looping score")
	t.equal(cues.sample(sim,hall,false).sting,"","the result piece never repeats")
	var lost=_cues()
	var other=Session.new()
	lost.sample(other,hall,false)
	other.mission.outcome="defeat"
	t.equal(lost.sample(other,hall,false).sting,"defeat_theme","losing plays the defeat piece")

func test_surviving_a_night_stings_once_without_changing_the_loop(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	cues.sample(sim,hall,false)
	sim.clock.survived+=1
	var dawn: Dictionary=cues.sample(sim,hall,false)
	t.equal(dawn.sting,"dawn_sting","surviving a night marks the dawn")
	t.equal(dawn.track,"day_refuge" if dawn.track=="day_refuge" else dawn.track,"dawn keeps the daytime loop running")
	t.equal(cues.sample(sim,hall,false).sting,"","the dawn mark does not repeat on later frames")

func test_pause_and_restart_do_not_replay_history(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	cues.sample(sim,hall,false)
	sim.clock.survived+=1
	t.equal(cues.sample(sim,hall,true).sting,"","pause swallows a pending mark instead of queueing it")
	t.equal(cues.sample(sim,hall,false).sting,"","resuming never replays the swallowed mark")
	var replacement=Session.new()
	replacement.mission.outcome="victory"
	var fresh=_cues()
	fresh.sample(replacement,hall,false)
	t.equal(fresh.sample(replacement,hall,false).sting,"","a restored run does not restate its result")

func test_founding_the_refuge_gets_its_own_moment(t):
	var cues=_cues()
	var sim=Session.new()
	var hall: float=sim.world.sites.hall
	cues.sample(sim,hall,false)
	sim.interact(hall)
	sim.interact(hall)
	t.truth(sim.frontier.city_level>0,"the camp is founded")
	var founded: Dictionary=cues.sample(sim,hall,false)
	t.equal(founded.sting,"founding_theme","founding the refuge plays its ceremony")
	t.equal(cues.sample(sim,hall,false).sting,"","the ceremony does not repeat")
	sim.frontier.city_level=2
	t.equal(cues.sample(sim,hall,false).sting,"","later growth is not another founding")

func test_a_restored_camp_is_not_founded_again(t):
	var cues=_cues()
	var sim=Session.new()
	sim.frontier.city_level=2
	t.equal(cues.sample(sim,sim.world.sites.hall,false).sting,"","loading a built refuge holds no ceremony")
	t.equal(cues.sample(sim,sim.world.sites.hall,false).sting,"","and none on the frame after")

func test_the_score_does_not_hoard_every_track_it_has_played(t):
	var script=load("res://presentation/campaign_music.gd")
	var player=script.new()
	for name in script.LOOPS:
		t.truth(player._stream(name)!=null,"%s loads" % name)
	t.truth(player._cache.size()<=script.CACHE_LIMIT,
		"playing through the score keeps at most %d tracks resident" % script.CACHE_LIMIT)
	player.free()
