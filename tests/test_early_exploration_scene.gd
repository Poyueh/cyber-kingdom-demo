extends "res://tests/test_trail_scene.gd"
func snapshot(name: String) -> void:
 await capture("early-"+name)
func run_scene() -> void:
 game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=617;game._seed_initialized=true
 root.add_child(game);await frames(10)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 game.sim.interact(game.sim.world.sites.hall,"hall")
 # Exploration begins after the real founding transition, before teleporting the fixture.
 for tick: int in range(105):game._physics_process(1.0/30)
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 game.sim.pouch.amount=6;game.sim.clock.remaining=160
 game._sync_knight_equipment();game._arrival_banner.hide()
 var nest: RefCounted=game.sim.trails.sites[0]
 var unit: RefCounted=game.sim.trails.units[0]
 place(nest.x+45)
 for tick: int in range(90):
  game._physics_process(1.0/30)
  if unit.phase==1:break
 check(game.sim.raiders.size()==1 and unit.phase==1,"actual new forest starts a single telegraphed fight")
 for tick: int in range(8):game._physics_process(1.0/30)
 await snapshot("forest-windup")
 var bag: int=game.sim.pouch.amount
 game.set_physics_process(true);game.knight.set_physics_process(true)
 key(KEY_D,true);await frames(50);key(KEY_D,false)
 game.set_physics_process(false);game.knight.set_physics_process(false)
 game.paused=false
 check(game.knight.position.x>nest.x+140,"ordinary D movement escapes the locked first lunge")
 for tick: int in range(60):
  game._physics_process(1.0/30)
  if unit.phase==3:break
 print("EVADE_STATE ",game.sim.pouch.amount," before=",bag," phase=",unit.phase," paused=",game.paused," x=",game.knight.position.x-nest.x)
 check(game.sim.pouch.amount==bag and unit.phase==3,"evade keeps crystals and exposes recovery")
 await snapshot("forest-recovery")
 game.paused=false;game.controls.release_all()
 var enemy: Dictionary=game.sim.raiders[0]
 for cut: int in range(2):
  place(enemy.x-24);game.sim.hero.facing=1
  game.set_physics_process(true);key(KEY_J,true);await frames(2);key(KEY_J,false)
  await frames(32);game.set_physics_process(false)
 check(not enemy.fighter.is_alive(),"two normal J attacks clear the introductory beast")
 place(nest.x);key(KEY_E,true);game._physics_process(1.0/30);key(KEY_E,false)
 check(nest.claimed,"normal E collects the defeated nest reward")
 game.paused=false;game.controls.release_all()
 var find: RefCounted=game.sim.trails.sites[1]
 game.sim.merchant.enabled=false;game.sim.pouch.amount=0;game.sim.pouch.drops.clear()
 game.sim.spirit.summoned=true;game.sim.spirit.expires_tick=int(game.sim.workforce.elapsed*30)+600
 place(find.x)
 check(game.hud.guide_view.hint.get("key")=="trail:1","actual ghost points to the known free roadside find")
 check(game.hud.guide_view._guide_label.text.contains(game.tr("trail.claim")),"roadside prompt describes gathering rather than a purchase")
 await snapshot("quiet-reward")
 game.controls.release_all();touch_find();game._physics_process(1.0/30)
 check(find.claimed,"normal touch down-swipe claims the quiet find")
 game.paused=false;game.sim.spirit.expires_tick=0;game.sim.clock.remaining=74.9
 place(find.x)
 for tick: int in range(30):game._physics_process(1.0/30)
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  game.hud.control_mode=1 if locale=="en" else 2
  game.hud.preview_safe_margins=Vector4(70,18,24,24) if locale=="en" else Vector4.ZERO
  game.hud._layout();await snapshot("return-"+locale)
  var watch: Control=game.hud.night_watch_view
  check(watch.visible and watch._info.get("lead")==-1,"brief return cue points to camp in "+locale)
  check(watch.caption.text==game.tr("night.return") and not watch.caption.text.begins_with("night."),"return caption translates in "+locale)
  print("RETURN_LAYOUT ",locale," safe=",game.hud.safe_rect()," caption=",watch.caption.get_rect()," reserved=",game.hud.immersive_feedback.day_caption_bounds())
  check(game.hud.safe_rect().encloses(watch.caption.get_rect()),"return cue fits safe margins in "+locale)
  check(not game.hud.guide_view.visible,"return cue does not resurrect spirit dialogue")
 game.paused=true;await snapshot("paused")
 check(not game.hud.night_watch_view.visible,"pause hides return reminder")
 game.paused=false
 for tick: int in range(250):game._physics_process(1.0/30)
 check(not game.hud.night_watch_view.visible,"return reminder expires after eight seconds")
 place(game.sim.world.sites.hall)
 for tick: int in range(8):game._physics_process(1.0/30)
 place(find.x)
 for tick: int in range(8):game._physics_process(1.0/30)
 check(not game.hud.night_watch_view.visible,"leaving camp again does not repeat the same day's reminder")
 TranslationServer.set_locale("zh_TW")
 game.audio.enabled=false;game.audio.stop();game.queue_free();await frames(2)
 print("Early exploration scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
