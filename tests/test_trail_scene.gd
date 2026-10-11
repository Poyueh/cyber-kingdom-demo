extends "res://tests/test_scene.gd"
const Codec=preload("res://application/campaign_snapshot.gd")
const Campaign=preload("res://application/campaign_session.gd")
var game: Node
func capture(name: String) -> void:
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,game.knight.is_on_floor())
 game._water.present(game.sim);game._sunbeams.present(game.sim)
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 await frames(3)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("/tmp/cyber-trail-native")
 root.get_texture().get_image().save_png("/tmp/cyber-trail-native/"+name+".png")
func touch_find() -> void:
 var at: Vector2=Vector2(220,180)
 var start: InputEventScreenTouch=InputEventScreenTouch.new();start.index=9;start.position=at;start.pressed=true
 root.push_input(start,true);Input.flush_buffered_events()
 var drag: InputEventScreenDrag=InputEventScreenDrag.new();drag.index=9;drag.position=at+Vector2(0,70)
 root.push_input(drag,true);Input.flush_buffered_events()
 var end: InputEventScreenTouch=InputEventScreenTouch.new();end.index=9;end.position=drag.position;end.pressed=false
 root.push_input(end,true);Input.flush_buffered_events()
func place(x: float) -> void:
 game.knight.position=Vector2(x,430);game.knight.velocity=Vector2.ZERO
 game._physics_process(1.0/30)
func run_scene() -> void:
 game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=617;game._seed_initialized=true
 root.add_child(game);await frames(10);game.set_physics_process(false);game.knight.set_physics_process(false)
 var catalog: Resource=load("res://data/settlement_identity.tres")
 check(catalog.valid(),"six facility staff have a complete native-pixel cast")
 var config: Dictionary=game.journey.configs[0]
 for planet: int in range(7):
  config=game.journey.configs[planet]
  game.sim=Campaign.new(config);game._campaign_config=config
  game.knight.configure(game.sim.hero,game.knight_tuning);game._build_terrain();game._sync_knight_equipment()
  game.sim.frontier.city_level=3;game.sim.survival.armed=true;game.sim.pouch.amount=24
  game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
  game.sim.clock.remaining=game.sim.clock.day_seconds*.75
  for region: Dictionary in game.sim.frontier.regions:region.discovered=true
  for site: String in ["workshop","farm_tools","hunt_tools","armory"]:game.sim.built[site]=true
  place(30)
  for tick: int in range(65):game._physics_process(1.0/30)
  if planet in [0,2,6]:
   await capture("camp-"+str(planet))
   place(game.sim.world.sites.workshop);await capture("workshop-"+str(planet))
   place(game.sim.world.sites.drill);await capture("artificer-"+str(planet))
  if planet==0:
   for site: String in ["farm_tools","hunt_tools","armory"]:
    place(game.sim.world.sites[site]);await capture("staff-"+site)
  var nest: RefCounted=game.sim.trails.sites[0]
  var unit: RefCounted=game.sim.trails.units[0]
  place(nest.x-100)
  for tick: int in range(90):
   game._physics_process(1.0/30)
   if unit.phase==1:break
  check(unit.phase==1,"local beast provides a visible windup before contact")
  for tick: int in range(8):game._physics_process(1.0/30)
  await capture("encounter-"+str(planet))
  check(game.sim.raiders.size()<=2,"local enemy budget stays small on planet "+str(planet))
  check(game.view._raider_motion.appearance("roamer").atlas!=null,"local beast uses the planet's complete animation atlas")
  var time: float=game.sim.workforce.elapsed
  var remaining: int=unit.remaining
  game.paused=true
  for tick: int in range(12):game._physics_process(1.0/30)
  check(game.sim.workforce.elapsed==time and unit.remaining==remaining,"pause freezes local attacks and work poses")
  game.paused=false
  var gems: int=game.sim.pouch.amount
  place(nest.x-310)
  for tick: int in range(90):
   game._physics_process(1.0/30)
   if unit.phase==3:break
  check(unit.phase==3 and unit.remaining>30,"attack commits then leaves a readable recovery window")
  check(game.sim.pouch.amount==gems,"moving outside the locked strike avoids local damage")
  if planet==0:
   var creature: Dictionary=game.sim.raiders[0]
   place(creature.x-24);game.sim.hero.facing=1
   var hp: int=creature.fighter.hp
   game.set_physics_process(true)
   key(KEY_J,true);await frames(2);key(KEY_J,false)
   await frames(30);game.set_physics_process(false)
   check(creature.fighter.hp<hp,"ordinary J sword input damages the local beast")
   await capture("forest-counterattack")
  var find: RefCounted=game.sim.trails.sites[1]
  place(find.x);game.hud.control_mode=1 if planet%2==0 else 2
  await capture("discovery-"+str(planet))
  game.controls.release_all()
  if planet%2==0:touch_find()
  else:key(KEY_E,true)
  game._physics_process(1.0/30);key(KEY_E,false);await frames(2)
  check(find.claimed,"normal keyboard or touch input claims the quiet discovery")
  var body: Dictionary={"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0}
  check(not Codec.new().restore(Codec.new().capture(game.sim,config,body)).is_empty(),"real scene checkpoint retains native encounter state")
  for locale: String in ["zh_TW","zh_CN","en"]:
   TranslationServer.set_locale(locale)
   check(not game.tr("trail.nest.%d"%planet).begins_with("trail."),"encounter identity translates in "+locale)
 TranslationServer.set_locale("zh_TW")
 game.queue_free();await frames(2)
 print("Trail native scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
