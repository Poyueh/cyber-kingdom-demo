extends "res://tests/test_scene.gd"
func shot(name: String) -> void:
 await frames(4);RenderingServer.force_draw()
 root.get_texture().get_image().save_png("/tmp/cyber46-"+name+".png")
func show_world(game: Node, at: float) -> void:
 game.knight.position=Vector2(at,430)
 game.get_node("Knight/Camera2D").reset_smoothing();game.get_node("Knight/Camera2D").force_update_scroll()
 game.view.present(game.sim,at);game.hud.present_world(game.sim,game.paused,at,true)
 game._water.present(game.sim);game._sunbeams.present(game.sim);game._lantern.present(game.sim,game.knight)
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10);game.set_physics_process(false);game.knight.set_physics_process(false)
 var expected: Array[int]=[2,2,2,3,3,4,4]
 for id: int in range(7):
  var sim: RefCounted=load("res://application/campaign_session.gd").new(game.journey.configs[id])
  check(sim.mission.rifts.size()==expected[id],"new world %d has authored gate allocation"%id)
  check(not load("res://application/campaign_snapshot.gd").new().restore(load("res://application/campaign_snapshot.gd").new().capture(sim,game.journey.configs[id],{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})).is_empty(),"authored world %d saves correctly"%id)
 game.sim.frontier.city_level=3;game.sim.survival.armed=true;game.sim.clock.remaining=game.sim.clock.day_seconds*0.6
 game.sim.spirit.expires_tick=0;game.sim.spirit.opening_finished=true
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 for kind: String in game.sim.world.tools:game.sim.world.tools[kind]=3
 for site: String in ["workshop","armory","farm_tools","hunt_tools"]:game.sim.built[site]=true
 for site: String in ["workshop","armory","farm_tools","hunt_tools"]:
  show_world(game,game.sim.world.sites[site]+100);await shot("gear-"+site)
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);root.get_node("GameLanguage").changed.emit()
  game.paused=true;game._star_travel.open_chart(true);game._star_travel.map.select_planet(6)
  await shot("chart-"+locale)
  var map: Node=game._star_travel.map
  check(map._panel.size.x<=960 and map._panel.size.y<=540,"atlas fits "+locale)
  check(map._buttons.all(func(b: Button)->bool:return map._chart.get_global_rect().encloses(b.get_global_rect())),"planet touch targets stay inside "+locale)
  game._star_travel.close()
 root.content_scale_size=Vector2i(960,450);root.size=Vector2i(960,450)
 game._star_travel.open_chart(true);await shot("chart-short")
 check(game._star_travel.map._panel.size.y<=450,"atlas fits short window")
 game._star_travel.close();root.content_scale_size=Vector2i(960,540);root.size=Vector2i(1440,810)
 TranslationServer.set_locale("zh_TW");root.get_node("GameLanguage").changed.emit()
 game.paused=false;game.sim.mission.damage_core(999);game.sim.mission.resolve(true,false)
 show_world(game,30);await frames(3)
 game.hud.dashboard.set_process(false)
 for age: float in [0.0,0.7,1.65,1.85,2.3,3.4]:
  game.hud.dashboard.outcome_age=age;game.hud.dashboard.queue_redraw();show_world(game,30);await shot("loss-%.2f"%age)
 game.queue_free();await frames(2)
 print("Free voyage native proof: %d checks, %d failures"%[assertions,failures]);quit(1 if failures else 0)
