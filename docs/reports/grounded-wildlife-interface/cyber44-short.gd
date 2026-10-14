extends "res://tests/test_scene.gd"
func shot(name: String) -> void:
 await frames(4)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/cyber44-"+name+".png")
func run_scene() -> void:
 var menu: Control=load("res://presentation/start_menu.gd").new()
 root.content_scale_size=Vector2i(960,450)
 root.size=Vector2i(1152,540)
 root.add_child(menu)
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  root.get_node("GameLanguage").changed.emit()
  menu.show_home();await shot("menu-"+locale)
  menu.show_paces();await shot("short-pace-"+locale)
  check(menu.pace_picker.confirm.get_global_rect().size.x<=350,"short menu action stays within card")
 menu.queue_free();await frames(2)
 quit(1 if failures else 0)
 return
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 game.view._reveal=load("res://presentation/exploration_reveal.gd").new()
 game.sim.spirit.expires_tick=0;game.sim.spirit.opening_finished=true
 var animal: Dictionary=game.sim.frontier.animals[0]
 game.knight.position=Vector2(animal.x-90,430)
 game.get_node("Knight/Camera2D").reset_smoothing()
 game.get_node("Knight/Camera2D").force_update_scroll()
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 for step: int in range(3):
  game.paused=false;game.hud.options_menu.hide()
  game.sim.workforce.elapsed+=0.1
  animal.x+=2.0 if step<2 else -2.0
  game.view.present(game.sim,game.knight.position.x)
  await shot("deer-%d"%step)
  if step>0:check(game.view._wildlife._directions[0]==(1.0 if step==1 else -1.0),"visible deer faces actual travel direction")
 game.hud.options_menu.show();await shot("options")
 game.hud.options_menu.hide();game._star_travel.open_chart(true)
 await shot("star-map")
 game.queue_free();await frames(2)
 print("Native finish proof: ",assertions," checks, ",failures," failures")
 quit(1 if failures else 0)
