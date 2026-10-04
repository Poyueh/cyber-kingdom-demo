extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(8)
 game.set_physics_process(false);game.paused=true
 game.hud.present_world(game.sim,true,game.knight.position.x,true)
 var button=game.hud.options_menu.find_child("ExplorationMap",true,false)
 check(button!=null,"pause menu exposes the exploration map on native platforms")
 button.pressed.emit()
 check(game.hud.exploration_map.visible and not game.hud.options_menu.visible,"map opens above the paused game without stacked menus")
 var elapsed: float=game.sim.workforce.elapsed
 for i in range(10):game._physics_process(1.0/30)
 check(game.paused and game.sim.workforce.elapsed==elapsed,"reading the map leaves the world clock paused")
 check(game.hud.exploration_map.get_rect().size.x<=game.hud._last_safe_rect.size.x,"map width fits the viewport")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  game.hud.exploration_map.present(game.sim,game.knight.position.x)
  game.hud.exploration_map.fit(game.hud._last_safe_rect)
  await frames(2)
  check(not game.hud.exploration_map._title.text.is_empty(),"map has a title in "+locale)
  check(game.hud._last_safe_rect.encloses(game.hud.exploration_map.get_rect()),"map including close button fits the safe viewport in "+locale)
 game.hud.exploration_map._close.pressed.emit();game._physics_process(0)
 check(game.paused and game.hud.options_menu.visible,"closing map returns to pause options")
 game.hud.control_mode=1
 button.pressed.emit();game._physics_process(0)
 check(game.hud.exploration_map.visible and not game.hud.get_node("attack").visible,"touch map keeps combat buttons disabled")
 game.paused=false;game._physics_process(0)
 check(not game.hud.exploration_map.visible,"resuming dismisses the map")
 game.paused=true;button.pressed.emit();game.restart()
 check(not game.hud.exploration_map.visible,"new journey clears the old map overlay")
 game.queue_free();await process_frame
 print("Exploration scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
