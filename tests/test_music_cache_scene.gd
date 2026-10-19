extends "res://tests/test_scene.gd"
func run_scene() -> void:
	var music: Node=load("res://presentation/campaign_music.gd").new()
	root.add_child(music)
	var sim: RefCounted=load("res://application/campaign_session.gd").new()
	music.observe(0.05,sim,sim.world.sites.hall+2000,false)
	sim.frontier.city_level=1
	music.observe(0.05,sim,sim.world.sites.hall,false)
	# A cue transition can request a sting while both loops, a layer and an old sting are bound.
	sim.clock.is_night=true
	sim.raiders.append(sim._spawn_raider())
	sim.clock.survived=1
	music.observe(0.05,sim,sim.world.sites.hall,false)
	check(music._sting_player.stream!=null,"a newly requested sting cannot evict itself before being bound")
	check(is_same(music._sting_player.stream,music._stream("dawn_sting")),"the bound sting is the shared dawn stream")
	var night: AudioStream=music._players[0].stream
	sim.clock.is_night=false;sim.raiders.clear()
	music.observe(0.05,sim,sim.world.sites.hall,false)
	sim.clock.is_night=true
	music.observe(0.05,sim,sim.world.sites.hall,false)
	check(is_same(music._players[0].stream,night),"night returns on the same stream rather than a new copy")
	music.queue_free();await process_frame
	print("Music cache scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)
