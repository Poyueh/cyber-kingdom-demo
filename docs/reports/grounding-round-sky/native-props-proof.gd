extends "res://tests/test_star_voyage_scene.gd"
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=416;game._seed_initialized=true
 root.add_child(game);await frames(10);game.set_physics_process(false);game.knight.set_physics_process(false)
 game.sim.clock.remaining=100;game.sim.spirit.expires_tick=0;game.sim.spirit.opening_finished=true
 game.sim.frontier.city_level=1;game.sim.survival.armed=true
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 game.view._reveal=load("res://presentation/exploration_reveal.gd").new()
 var suffix: String="before"
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--proof="):suffix=arg.trim_prefix("--proof=")
 for name: String in ["cradle","stable","rocket"]:
  if name=="cradle":game.knight.position=Vector2(game.sim.mount_quest.ruin_x-170,430)
  elif name=="stable":
   game.sim.mount_quest.recovered=true;game.sim.mount_quest.unlocked=true
   game.knight.position=Vector2(game.sim.mount_quest.stable_x-170,430)
  else:
   game.sim.planet.reactor=true;game.sim.planet.rocket_ready=true
   game.knight.position=Vector2(load("res://application/planet_operations.gd").rocket_x(game.sim)-170,430)
  await capture(game,"v42-"+name+"-"+suffix)
 game.queue_free();await frames(3);quit()
