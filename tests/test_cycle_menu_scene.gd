extends "res://tests/test_scene.gd"
func run_scene() -> void:
	var game=load("res://scenes/frontier.tscn").instantiate();game.tuning=game.tuning.duplicate();game.tuning.immersive_loop=false
	check(game.has_method("save_manual_campaign"),"pause menu supports an independent manual checkpoint")
	if failures>0:game.free();quit(1);return
	ProjectSettings.set_setting("campaign/persistence_enabled",true)
	var path="user://test_cycle_menu_%d.json" % Time.get_ticks_usec()
	game.campaign_save_path=path
	game.audio_preferences_path=path+".cfg"
	root.add_child(game)
	await frames(12)
	game.set_physics_process(false)
	game.paused=true
	game.hud.present_world(game.sim,true,game.knight.position.x,true)
	check(game.hud.options_menu.visible,"pause exposes audio and save controls")
	check(game.hud.options_menu.find_child("PlayerGuide",true,false)==null,"native desktop menu does not expose the Web-only iframe reader")
	check(game.hud.options_menu.load_button.disabled,"empty manual slot cannot load")
	game.sim.interact(30)
	game.hud.options_menu.save_button.pressed.emit()
	var wallet=game.sim.pouch.amount
	check(game.manual_progress.status=="saved","save icon writes the manual slot")
	game.sim.throw_crystal(30,430,1)
	game.save_campaign()
	game.hud.interact_held=true
	game.hud.options_menu.load_button.pressed.emit()
	check(game.sim.pouch.amount==wallet,"manual load restores checkpoint independently of newer autosave")
	check(game.paused and not game.hud.interact_held,"load stays paused and clears held payment")
	game.hud.options_menu.music.value=23
	game.hud.options_menu.effects.value=67
	check(is_equal_approx(game.audio.music_volume,0.23) and is_equal_approx(game.audio.effects_volume,0.67),"both sliders reach the actual audio player")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.audio.suspended,"background suspends soundtrack")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not game.audio.suspended,"foreground restores soundtrack eligibility")
	game.hud.control_mode=2
	game.hud.present_world(game.sim,false,0,true)
	check(not game.hud.get_node("attack").visible and not game.hud.get_node("jump").visible,"desktop hides touch action buttons")
	game.hud.control_mode=1
	game.hud.present_world(game.sim,false,0,true)
	check(game.hud.get_node("attack").visible and not game.hud.get_node("jump").visible and not game.hud.get_node("dash").visible,"mobile exposes only the sword action")
	game.sim.frontier.drill_level=2;game.sim.growth.capacitor_level=1
	game._physics_process(0)
	check(game.knight.visual.weapon_tier==2 and game.knight.visual.armor_tier==1,"equipment visuals follow actual upgrade state")
	game.queue_free();await process_frame
	game=load("res://scenes/frontier.tscn").instantiate();game.tuning=game.tuning.duplicate();game.tuning.immersive_loop=false
	game.campaign_save_path=path;game.audio_preferences_path=path+".cfg"
	root.add_child(game);await frames(2);game.set_physics_process(false)
	check(is_equal_approx(game.audio.music_volume,0.23) and is_equal_approx(game.audio.effects_volume,0.67),"volume preferences survive reopening")
	check(game.load_manual_campaign() and game.sim.pouch.amount==wallet,"manual checkpoint survives reopening")
	game.queue_free();await process_frame
	for suffix in ["",".manual",".cfg"]:DirAccess.remove_absolute(path+suffix)
	print("Cycle menu assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
