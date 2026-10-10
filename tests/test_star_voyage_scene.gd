extends "res://tests/test_scene.gd"
const Voyage=preload("res://application/star_voyage.gd")
const NAMES: Array[String]=["forest","desert","frost","swamp","volcanic","storm","void"]
func click(button: Button) -> void:
 await frames(2)
 var at: Vector2=root.get_final_transform()*button.get_global_rect().get_center()
 for down: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
  Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
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
 DirAccess.make_dir_recursive_absolute("res://test-results/seven-planets")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/seven-planets/"+name+".png")
func clear_world(game: Node) -> void:
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim.raiders.clear();game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
 game.sim.frontier.city_level=1;game.sim.survival.armed=true;game.sim.advance(0.1,30)
 game.sim.planet.claim_core();game.sim.planet.rocket_ready=true;game.knight.position.x=-730
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10);game.set_physics_process(false)
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 game.knight.position=Vector2(30,430);game.paused=false
 check(game.journey!=null and game.journey.configs.size()==7,"real scene creates all seven planet definitions")
 await capture(game,"forest")
 game.paused=true;game._star_travel.open_chart(true)
 game._star_travel.map.select_planet(6)
 check(game._star_travel.map._launch.disabled,"pause-menu chart inspects locked worlds without allowing launch")
 await capture(game,"locked-chart")
 game._star_travel.close();check(game.paused,"closing preview returns to paused menu")
 clear_world(game);game.paused=false
 for id: int in [1,3,2,4,5,6]:
  game.sim.planet.launch_requested=true;game._star_travel.observe()
  check(game._star_travel.active(),"completed rocket opens star chart")
  await click(game._star_travel.map._buttons[id])
  check(not game._star_travel.map._launch.disabled,"available destination enables launch confirmation")
  check(game.journey.current!=id,"inspecting a planet does not launch immediately")
  await capture(game,"chart-"+NAMES[id])
  await click(game._star_travel.map._launch);await frames(3)
  check(game.journey.current==id and game.sim.planet.wrecked,"confirmed route reaches "+NAMES[id])
  game._arrival_banner.hide();game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
  game.knight.position=Vector2(30,430);await capture(game,NAMES[id])
  for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
  game.sim._summon_dragon(game.knight.position.x)
  var dragon: Dictionary=game.sim.raiders[0];dragon.x=game.knight.position.x+250;dragon.direction=-1.0;dragon.windup=1.4;dragon.target={"kind":"hero","x":game.knight.position.x}
  await capture(game,NAMES[id]+"-dragon")
  clear_world(game);game.journey.observe(game.sim)
  check(game.sim.mission.outcome==("victory" if id==6 else "active"),"win requires all seven cores")
 var packet: Dictionary=game.journey.capture(game.sim,{"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0})
 check(not Voyage.restore(packet).is_empty(),"complete seven-world save restores through actual scene")
 print("Seven-world checkpoint bytes: ",JSON.stringify(packet).to_utf8_buffer().size())
 # Check all language layouts through the same real chart.
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  game._star_travel.open_chart(true);game._star_travel.map.select_planet(5)
  await capture(game,"chart-"+locale)
  check(game._star_travel.map._panel.size.x<=960 and game._star_travel.map._panel.size.y<=540,"chart fits "+locale)
 game.audio.enabled=false;game.audio.stop()
 await create_timer(0.25).timeout
 game.queue_free();await frames(2)
 print("Seven-planet scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
