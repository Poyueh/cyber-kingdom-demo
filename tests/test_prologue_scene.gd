extends "res://tests/test_scene.gd"
## Exercise the actual title, isolated combat world, and both disposal paths.
func run_scene() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",true)
 if has_meta("campaign_prologue_seen"):remove_meta("campaign_prologue_seen")
 var folder: String="user://test_prologue_%d"%Time.get_ticks_usec()
 var menu=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory=folder;menu.legacy_path=""
 root.add_child(menu)
 await frames(4)
 var cinema=menu.get_child(menu.get_child_count()-1)
 check(not menu.view.visible and cinema.stage.game!=null,"title starts with a real campaign performance")
 var stage=cinema.stage
 var game=stage.game
 check(game.progress==null and game.preferences==null,"cinematic cannot read or write a campaign or audio preferences")
 check(game.get_world_2d()!=root.world_2d,"cinematic owns an isolated physics world")
 check(not game.hud.visible and not game.controls.is_processing_unhandled_key_input(),"cinematic hides gameplay UI and rejects live controls")
 stage.elapsed=4.01;await frames(3)
 check(game.sim.frontier.city_level==1 and game.sim.can_wield_sword(),"performance lights camp and equips the knight")
 stage.elapsed=10.01;await frames(3)
 check(game.sim.clock.is_night and not game.sim.raiders.is_empty(),"night shot runs actual approaching enemies")
 stage.elapsed=18.01;await frames(3)
 check(game.sim.mission.dragon_summoned,"sealed gates summon the actual dragon in the final shot")
 stage.elapsed=25.01;await frames(4)
 check(menu.view.visible and not is_instance_valid(cinema) and not is_instance_valid(game),"natural completion reveals title and frees the entire performance")
 check(menu.catalog.entries().is_empty(),"watching the prologue does not create a player journey")
 menu.queue_free();await frames(3)
 for repeat in range(2):
  remove_meta("campaign_prologue_seen")
  menu=load("res://scenes/start_menu.tscn").instantiate()
  menu.campaigns_directory=folder;menu.legacy_path="";root.add_child(menu)
  await frames(3)
  cinema=menu.get_child(menu.get_child_count()-1);game=cinema.stage.game
  cinema._skip.pressed.emit();await frames(4)
  check(menu.view.visible and not is_instance_valid(game),"skip reveals title and releases the performance, repeat %d"%repeat)
  menu.queue_free();await frames(3)
 print("Prologue scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
