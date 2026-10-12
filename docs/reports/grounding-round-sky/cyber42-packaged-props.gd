extends SceneTree
## Exercise actual physics, InputMap, scene wiring and persistence together.
var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
 ProjectSettings.set_setting("campaign/control_preview",1)
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run_scene")

func check(value: bool, description: String) -> void:
 assertions += 1
 if not value:
  failures += 1
  printerr("FAIL: " + description)
 else:
  print("PASS: " + description)

func key(code: int, down: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func frames(count: int) -> void:
 for unused in range(count):
  await physics_frame

func wait_for_damage(fighter) -> void:
 var before: int = fighter.hp
 for tick in range(30):
  await physics_frame
  if fighter.hp < before:
   return

func capture(game: Node, name: String) -> void:
 game.get_node("Knight/Camera2D").reset_smoothing()
 game.get_node("Knight/Camera2D").force_update_scroll()
 await frames(3)
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,true)
 await frames(4)
 game._water.present(game.sim);game._sunbeams.present(game.sim);game._lantern.present(game.sim,game.knight)
 if game._star_travel.active():game.hud.options_menu.hide()
 game.view.present(game.sim,game.knight.position.x)
 await frames(2)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("/tmp/cyber42-packaged-props")
 game.get_viewport().get_texture().get_image().save_png("/tmp/cyber42-packaged-props/"+name+".png")
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
 for name: String in ["cradle","stable","rocket-wreck","rocket-building","rocket-ready"]:
  if name=="cradle":game.knight.position=Vector2(game.sim.mount_quest.ruin_x-170,430)
  elif name=="stable":
   game.sim.mount_quest.recovered=true;game.sim.mount_quest.unlocked=true
   game.knight.position=Vector2(game.sim.mount_quest.stable_x-170,430)
  else:
   game.sim.planet.reactor=true;game.sim.planet.rocket_ready=name=="rocket-ready";game.sim.planet.rocket_pending=name=="rocket-building"
   game.knight.position=Vector2(load("res://application/planet_operations.gd").rocket_x(game.sim)-170,430)
  await capture(game,"v42-"+name+"-"+suffix)
 game.queue_free();await frames(3);quit()
