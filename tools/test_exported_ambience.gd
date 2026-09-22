extends SceneTree
## Run against the exported PCK, never the editor project or its import cache.
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 ProjectSettings.set_setting("campaign/control_preview",2)
 call_deferred("verify")

func verify() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 if game.ambience==null or game.get_node("WorldView").daylight_style==null:
  printerr("FAIL: exported campaign lost its ambient or daylight resource")
  game.free();quit(1);return
 root.add_child(game)
 for i: int in range(6):await process_frame
 var daylight: Node=game.view._daylight
 for night: bool in [false,true]:
  game.sim.clock.is_night=night
  game.sim.clock.remaining=(game.sim.clock.night_seconds if night else game.sim.clock.day_seconds)*0.5
  daylight.present(game.sim.clock,game.view.art.woodland,Rect2(0,0,1280,720))
  if daylight._light.color.get_luminance()<0.3 or daylight._sky.texture==null:
   printerr("FAIL: exported day/night scene lost ambient illumination")
   game.queue_free();await process_frame;quit(1);return
 print("PASS: exported campaign retains world settings and day/night ambient illumination")
 game.queue_free();await process_frame;quit()
