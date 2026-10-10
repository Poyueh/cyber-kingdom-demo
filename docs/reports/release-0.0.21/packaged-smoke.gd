extends SceneTree
var failures: int=0
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func check(value: bool, description: String) -> void:
 if not value:failures+=1;printerr("FAIL: "+description)
 else:print("PASS: "+description)
func run() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game)
 for i: int in range(8):await physics_frame
 game.set_physics_process(false)
 check(game.journey.configs.size()==7,"export contains seven world definitions")
 check(not FileAccess.file_exists("res://art/concepts/seven-planets-v001/sources/swamp.png"),"high resolution sources excluded")
 for target: int in [1,3,2,4,5,6]:
  for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
  game.sim.raiders.clear();game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
  game.sim.frontier.city_level=1;game.sim.survival.armed=true
  game.sim.advance(0.1,-730)
  check(game.sim.planet.claim_core(),"unique core available")
  game.sim.planet.rocket_ready=true;game.knight.position=Vector2(-730,430)
  check(game.sim.interact(-730,"star_map"),"rocket accepts real interaction")
  game._star_travel.observe()
  check(game._star_travel.active(),"rocket opens route chart")
  game._star_travel.map._buttons[target].pressed.emit()
  check(not game._star_travel.map._launch.disabled,"target selectable after prerequisite")
  game._star_travel.map._launch.pressed.emit()
  check(game.journey.current==target and game.sim.planet.wrecked,"launch arrives with wreckage")
  for i: int in range(3):await physics_frame
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
 game.sim.advance(0.1,game.knight.position.x)
 check(game.sim.planet.claim_core(),"seventh core claim")
 game.journey.observe(game.sim)
 check(game.sim.mission.outcome=="victory","seven-core expedition victory")
 game._arrival_banner.hide();game.paused=true;game._star_travel.open_chart(true)
 for i: int in range(6):await physics_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/seven-packaged-native.png")
 game.audio.enabled=false;game.audio.stop()
 await create_timer(0.3).timeout
 game.queue_free()
 for i: int in range(3):await physics_frame
 print("Exported seven-world failures: ",failures)
 quit(1 if failures else 0)
