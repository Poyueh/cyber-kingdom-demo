extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";root.add_child(game)
 await frames(5);game.set_physics_process(false)
 game.sim.interact(30,"hall")
 game.sim.mission.outcome="defeat";game.sim.mission.defeat_reason="core"
 game.sim.mission.core_hp=0
 var restored: Dictionary={"session":game.sim,"config":game._campaign_config,"body":{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0},"journey":game.journey}
 game._apply_restored(restored)
 await frames(3)
 game.hud.present_world(game.sim,game.paused,30,true)
 check(game.paused and game.hud.options_menu.visible,"loading a fallen camp opens its menu")
 check(game.hud.get_node("pause").visible,"restored defeat never hides the only menu exit")
 game.set_physics_process(true)
 key(KEY_ESCAPE,true);await frames(3);key(KEY_ESCAPE,false);await frames(2)
 check(not game.paused and not game.hud.options_menu.visible,"Escape closes a loaded terminal menu")
 game.queue_free();await process_frame
 print("Restore menu assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
