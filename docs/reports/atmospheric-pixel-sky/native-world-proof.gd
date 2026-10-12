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
 game.sim.mount_quest.recovered=true;game.sim.mount_quest.unlocked=true
 game.knight.position=Vector2(game.sim.mount_quest.stable_x-170,430)
 var labels: Array[String]=["dawn","noon","sunset","moonrise","midnight","predawn"]
 var phases: Array[float]=[0.09,0.5,0.85,0.1,0.5,0.91]
 for index: int in range(labels.size()):
  game.sim.clock.is_night=index>=3
  game.sim.clock.remaining=(game.sim.clock.night_seconds if index>=3 else game.sim.clock.day_seconds)*(1-phases[index])
  await capture(game,"v43-"+labels[index]+"-"+suffix)
 game.queue_free();await frames(3);quit()
