extends "res://tests/test_star_voyage_scene.gd"
func touch(index: int, at: Vector2, down: bool) -> void:
 var event: InputEventScreenTouch=InputEventScreenTouch.new();event.index=index;event.position=at;event.pressed=down
 root.push_input(event,true);Input.flush_buffered_events()
func swipe(index: int, at: Vector2) -> void:
 var event: InputEventScreenDrag=InputEventScreenDrag.new();event.index=index;event.position=at
 root.push_input(event,true);Input.flush_buffered_events()
func capture(game: Node, name: String) -> void:
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 game.view.present(game.sim,game.knight.position.x);game._water.present(game.sim);game._sunbeams.present(game.sim)
 await frames(4)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/planet-ruins")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/planet-ruins/"+name+".png")
func press(game: Node, station: int, mobile: bool) -> void:
 var site: RefCounted=game.sim.trials.sites[0]
 game.knight.position=Vector2(site.positions[station],430);game.knight.velocity=Vector2.ZERO
 game._physics_process(1.0/30)
 if mobile:
  touch(12,Vector2(200,220),true);swipe(12,Vector2(200,280));touch(12,Vector2(200,280),false)
 else:key(KEY_E,true);key(KEY_E,false)
 game._physics_process(1.0/30);await frames(2)
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10);game.set_physics_process(false)
 clear_world(game)
 for planet: int in [1,3,2,4,5,6]:
  game.sim.planet.launch_requested=true;game._star_travel.observe()
  await click(game._star_travel.map._buttons[planet]);await click(game._star_travel.map._launch);await frames(3)
  check(game.journey.current==planet,"actual voyage reaches puzzle world "+str(planet))
  game._arrival_banner.hide();game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
  game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
  for region: Dictionary in game.sim.frontier.regions:region.discovered=true
  var site: RefCounted=game.sim.trials.sites[0];var m: RefCounted=site.mechanism
  game.knight.position=Vector2(site.positions[1],430);game._physics_process(1.0/30)
  game.hud.control_mode=1 if planet%2==0 else 2
  TranslationServer.set_locale("zh_TW")
  # Let the actual 1.8-second exploration reveal finish before judging pixels.
  for i: int in range(65):game._physics_process(1.0/30)
  await capture(game,"world-"+str(planet))
  if planet==2:
   for locale: String in ["zh_CN","en"]:
    TranslationServer.set_locale(locale);await capture(game,"frost-"+locale)
    check(not game.tr("ruin.balance.hint").begins_with("ruin."),"mechanism guidance translates in "+locale)
   TranslationServer.set_locale("zh_TW")
  var amount: int=game.sim.pouch.amount
  var actions: Array[int]=[];var times: Array[int]=[]
  match planet:
   1:actions.assign([0,2])
   3:actions.assign([1,2])
   2:actions.assign([0,0,1,2])
   4:actions.assign([1,1,0,2])
   5:actions.assign([0,1,2]);times.assign([24,28,32])
   6:actions.assign([0,1,2]);times.assign([28,30,32])
  for i: int in range(actions.size()):
   if not times.is_empty():game.sim.workforce.elapsed=float(times[i])
   await press(game,actions[i],planet%2==0)
  check(site.progress==3,"keyboard or mobile gesture solves this family in the real scene")
  check(game.sim.pouch.amount==amount,"mechanism interactions do not accidentally throw crystals")
  game.knight.position=Vector2(site.x,430);game._physics_process(1.0/30)
  check(game.sim.modules.equipped==site.id,"scene awards the expected planet module")
  if planet==5:
   game.paused=true
   var phase: int=m.phase(0,roundi(game.sim.workforce.elapsed*30))
   for i: int in range(30):game._physics_process(0.5)
   check(m.phase(0,roundi(game.sim.workforce.elapsed*30))==phase,"pause freezes the visible pulse needle")
   game.paused=false
  clear_world(game);game.journey.observe(game.sim)
 var packet: Dictionary=game.journey.capture(game.sim,{"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0})
 check(not Voyage.restore(packet).is_empty(),"all six solved worlds remain valid in a real voyage save")
 game.queue_free();await frames(2)
 print("Planet ruin scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
