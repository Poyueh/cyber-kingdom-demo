extends "res://tests/test_star_voyage_scene.gd"
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";game._map_seed=416;game._seed_initialized=true
 root.add_child(game);await frames(10);game.set_physics_process(false)
 for planet: int in [0,1,3,2,4,5,6]:
  print("WORLD START ",planet)
  if planet>0:
   clear_world(game);game.sim.planet.launch_requested=true;game._star_travel.observe()
   game._star_travel.map.destination_selected.emit(planet);await frames(3)
  game.paused=false;game._arrival_banner.hide();game._star_travel.map.hide()
  game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
  game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
  for region: Dictionary in game.sim.frontier.regions:region.discovered=true
  var at: float=game.sim.frontier.regions[9].x+game.sim.frontier.regions[9].width*0.5
  game.view._reveal=load("res://presentation/exploration_reveal.gd").new()
  game.knight.position=Vector2(at,430);game.knight.velocity=Vector2.ZERO
  print("WORLD RENDER ",planet)
  await capture(game,"v44-ground-"+str(planet))
  print("WORLD DONE ",planet)
  clear_world(game);game.journey.observe(game.sim)
 game.queue_free();await frames(3);quit()
