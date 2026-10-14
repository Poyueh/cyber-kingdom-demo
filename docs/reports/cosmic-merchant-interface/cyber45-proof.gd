extends "res://tests/test_scene.gd"
func shot(name: String) -> void:
 await frames(4)
 RenderingServer.force_draw()
 root.get_texture().get_image().save_png("/tmp/cyber45-"+name+".png")
func run_scene() -> void:
 var menu: Control=load("res://presentation/start_menu.gd").new();root.add_child(menu)
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);root.get_node("GameLanguage").changed.emit()
  menu.show_home();await shot("menu-"+locale)
  menu.show_paces();await shot("pace-"+locale)
 menu.queue_free();await frames(2)
 TranslationServer.set_locale("zh_TW");root.get_node("GameLanguage").changed.emit()
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 game.view._reveal=load("res://presentation/exploration_reveal.gd").new()
 game.sim.spirit.expires_tick=0;game.sim.spirit.opening_finished=true
 game.sim.merchant.phase=2;game.sim.merchant.x=820
 game.knight.position=Vector2(730,430)
 game.get_node("Knight/Camera2D").reset_smoothing();game.get_node("Knight/Camera2D").force_update_scroll()
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 TranslationServer.set_locale("zh_TW");root.get_node("GameLanguage").changed.emit()
 for tier: int in [1,2,3]:
  game.sim.frontier.city_level=tier
  game.sim.merchant.moving=false;game.view.present(game.sim,game.knight.position.x)
  game.hud.present_world(game.sim,false,game.knight.position.x,true)
  await shot("merchant-%d"%tier)
  game.sim.merchant.moving=true
  for frame: int in range(6):
   game.sim.merchant.walk_distance=frame*32.0/6.0
   game.view.present(game.sim,game.knight.position.x);await shot("merchant-%d-walk-%d"%[tier,frame])
 game.paused=true;game.hud.present_world(game.sim,true,game.knight.position.x,true)
 check(not game.hud.audio_button.visible and not game.hud.new_map_button.visible and not game.hud.get_node("restart").visible,"redundant shortcuts stay hidden in native pause")
 await shot("options")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);root.get_node("GameLanguage").changed.emit()
  game._star_travel.open_chart(true);game._star_travel.map.select_planet(6)
  await shot("star-map-"+locale)
  var map: Node=game._star_travel.map
  check(map._panel.size.x<=960 and map._panel.size.y<=540,"cosmic map fits "+locale)
  check(map._launch.disabled,"locked/read-only destination cannot launch")
  check(map._buttons.all(func(b: Button)->bool:return map._chart.get_global_rect().encloses(b.get_global_rect())),"all seven planet touch targets stay on map")
  game._star_travel.close()
 TranslationServer.set_locale("zh_TW");root.get_node("GameLanguage").changed.emit()
 game._star_travel.open_chart(true)
 var chart: Control=game._star_travel.map._chart
 chart._time=24;await shot("star-map-motion")
 root.content_scale_size=Vector2i(960,450);root.size=Vector2i(960,450)
 game._star_travel.map.present(game.journey,game.sim,true)
 await shot("star-map-short")
 check(game._star_travel.map._panel.size.y<=450,"cosmic map fits short 960 by 450 viewport")
 game.queue_free();await frames(2)
 print("Cosmic interface native proof: %d checks, %d failures"%[assertions,failures]);quit(1 if failures else 0)
