extends SceneTree
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func run() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game)
 for i in range(8):await physics_frame
 game.set_physics_process(false)
 assert(game.journey.configs.size()==3)
 assert(not FileAccess.file_exists("res://art/concepts/three-planets-v001/sources/sand-dragon.png"))
 for target: int in [1,2]:
  for rift in game.sim.mission.rifts:rift.sealed=true
  game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
  game.sim.frontier.city_level=1;game.sim.survival.armed=true
  game.sim.advance(0.1,-730)
  assert(game.sim.planet.claim_core())
  game.sim.planet.rocket_ready=true
  game.knight.position=Vector2(-730,430)
  assert(game.sim.interact(-730,"star_map"))
  game._star_travel.observe()
  assert(game._star_travel.active())
  game._star_travel.map._buttons[target].pressed.emit()
  assert(game.journey.current==target and game.sim.planet.wrecked)
  assert(game.view.art.woodland.resource_path.ends_with("frost-sky.png" if target==2 else "desert-sky.png"))
  for i in range(3):await physics_frame
 for rift in game.sim.mission.rifts:rift.sealed=true
 game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
 game.sim.advance(0.1,game.knight.position.x);assert(game.sim.planet.claim_core());game.journey.observe(game.sim)
 assert(game.sim.mission.outcome=="victory")
 game._arrival_banner.hide();game.sim.clock.remaining=90
 game.view.present(game.sim,game.knight.position.x)
 game._water.present(game.sim)
 for i in range(4):await physics_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/planets-packaged-native.png")
 game.audio.enabled=false;game.audio.stop()
 await create_timer(0.3).timeout
 game.queue_free()
 for i in range(3):await physics_frame
 print("PASS: exported three-world resources, live rocket/star-chart buttons, travel and three-core victory; source artwork excluded")
 quit(0)
