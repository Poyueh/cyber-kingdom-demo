extends "res://tests/test_scene.gd"
class LandmarkProbe extends Node2D:
 var sim: RefCounted
 func _on_screen(_x: float, _margin: float) -> bool:return true
 func _region_reveal(_index: int) -> float:return 1.0
 func _draw() -> void:
  preload("res://presentation/exploration_landmarks.gd").draw_on(self,[{"region":0,"x":300.0,"kind":"ruins","node":-1,"module":""}],sim)
func run_scene() -> void:
 if DisplayServer.get_name()=="headless":
  print("Ground contact pixels require native renderer");quit();return
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";root.add_child(game)
 await frames(3);game.set_physics_process(false);game.hide();game.hud.hide()
 var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(600,500);viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var probe: LandmarkProbe=LandmarkProbe.new();probe.sim=game.sim;viewport.add_child(probe)
 for planet: int in range(7):
  game.sim.planet.id=planet;probe.queue_redraw();await frames(4)
  await RenderingServer.frame_post_draw
  var pixels: Image=viewport.get_texture().get_image()
  var bottom: int=pixels.get_used_rect().end.y
  check(absi(bottom-430)<=1,"world %d visible ruin base touches ground (actual %d)"%[planet,bottom])
 viewport.queue_free();game.queue_free();await frames(3)
 print("Ground contact assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
