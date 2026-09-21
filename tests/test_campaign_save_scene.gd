extends "res://tests/test_scene.gd"
func make_scene(location: String):
	var game=load("res://scenes/frontier.tscn").instantiate();game.tuning=game.tuning.duplicate();game.tuning.immersive_loop=false
	game.campaign_save_path=location
	root.add_child(game)
	await frames(3)
	game.set_physics_process(false)
	return game
func run_scene() -> void:
	var prototype=load("res://scenes/frontier.tscn").instantiate();prototype.tuning=prototype.tuning.duplicate();prototype.tuning.immersive_loop=false
	check(prototype.has_method("save_campaign"),"real campaign scene can save and resume")
	prototype.free()
	if failures>0:quit(1);return
	ProjectSettings.set_setting("campaign/persistence_enabled",true)
	var location="user://test_campaign_scene_%d.json" % Time.get_ticks_usec()
	var game=await make_scene(location)
	game.paused=false
	game.sim.interact(30)
	game.sim.throw_crystal(30,430,-1)
	game.knight.position=Vector2(100,400)
	game.knight.velocity=Vector2(0,-150)
	game.hud.interact_held=true
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.paused and not game.hud.interact_held,"background pauses campaign and releases investment")
	check(game.progress.status=="saved","background creates a complete checkpoint")
	var wallet=game.sim.pouch.amount
	var ground=game.sim.pouch.ground_total()
	var remaining=game.sim.clock.remaining
	game.queue_free()
	await process_frame
	game=await make_scene(location)
	check(game.paused,"reopen waits for player to resume")
	check(game.sim.pouch.amount==wallet and game.sim.pouch.ground_total()==ground,"physical crystals and backpack survive scene destruction")
	check(game.sim.context(30).paid==1,"unfinished camp investment survives")
	check(game.knight.position==Vector2(100,400) and game.knight.velocity==Vector2(0,-150),"midair position and velocity survive")
	check(absf(game.sim.clock.remaining-remaining)<0.000001,"loading and paused frames do not advance time")
	check(not game.hud.interact_held,"loading cannot replay held payment")
	game._physics_process(1.0)
	check(game.sim.pouch.amount==wallet and absf(game.sim.clock.remaining-remaining)<0.000001,"paused scene cannot spend or simulate")
	game.paused=false
	game._physics_process(1.0/60)
	check(game.knight.position.y<400,"resuming continues saved jump")
	DirAccess.make_dir_absolute(location+".tmp")
	check(not game.save_campaign(),"storage failure is surfaced by real scene")
	check(game.hud.save_button.visible and not game.hud.save_button.disabled,"retry icon is available after storage failure")
	DirAccess.remove_absolute(location+".tmp")
	game.hud.save_button.pressed.emit()
	check(game.progress.status=="saved","retry icon saves after storage recovers")
	game.restart()
	check(game.sim.pouch.amount==12 and game.sim.frontier.city_level==0,"explicit restart creates fresh campaign")
	var archive=game.progress.last_archive
	check(FileAccess.file_exists(archive),"restart retains old campaign archive")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(location)
	DirAccess.remove_absolute(archive)
	var invalid='{"version":99}'
	var file=FileAccess.open(location,FileAccess.WRITE)
	file.store_string(invalid);file.close()
	game=await make_scene(location)
	check(game.progress.status=="protected" and game.paused,"unknown version starts paused with protected status")
	check(game.hud.save_button.visible,"protected progress has a visible status icon")
	game.paused=false
	game._physics_process(6.0)
	check(FileAccess.get_file_as_string(location)==invalid,"autosave cannot overwrite incompatible file")
	game.restart()
	archive=game.progress.last_archive
	check(game.progress.status=="saved" and FileAccess.get_file_as_string(archive)==invalid,"explicit new run archives incompatible original")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(location)
	DirAccess.remove_absolute(archive)
	print("Campaign save scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
