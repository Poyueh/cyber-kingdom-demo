extends "res://tests/test_scene.gd"
func refresh(game: Node) -> void:
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,false)
 game._water.present(game.sim);game._sunbeams.present(game.sim)
func capture(game: Node, name: String) -> void:
 refresh(game);await frames(3);refresh(game)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/core-spirit")
 root.get_texture().get_image().save_png("res://test-results/core-spirit/"+name+".png")
func run_scene() -> void:
 for trial: bool in [true,false]:
  var game: Node=load("res://scenes/frontier.tscn").instantiate()
  game._core_trial=trial;game._guided_campaign=not trial;game.campaign_save_path="";game.audio_preferences_path=""
  root.add_child(game);await frames(10);game.set_physics_process(false)
  game.sim.advance(181,game.knight.position.x);refresh(game)
  var guide: Node=game.hud.guide_view
  check(guide.visible and guide.modulate.a>0.9,"real scene keeps the ghost visible after old deadline")
  check(not game.hud.core_hud.caption.visible,"companion replaces duplicate static top instruction")
  for locale: String in ["zh_TW","zh_CN","en"]:
   TranslationServer.set_locale(locale)
   await capture(game,("demo-" if trial else "main-")+locale)
   check(not guide._guide_label.text.contains("spirit."),"ghost short text translated: "+locale)
   check(game.hud.safe_rect().encloses(guide._guide_label.get_rect()),"ghost caption fits: "+locale)
  game.hud.core_hud.guide_button.pressed.emit();refresh(game)
  check(not guide.visible and game.sim.core_loop.stage==0,"hide button removes ghost without advancing tutorial")
  game.hud.core_hud.guide_button.pressed.emit();refresh(game)
  check(guide.visible,"show button restores current ghost objective")
  game.knight.position.x=game.sim.world.sites.hall;refresh(game)
  key(KEY_E,true);key(KEY_E,false);game._physics_process(1.0/30)
  for tick: int in range(110):game._physics_process(1.0/30)
  check(game.sim.frontier.city_level==1 and guide.hint.get("kind")=="recruit","real founding input advances ghost to a resident")
  TranslationServer.set_locale("zh_TW")
  await capture(game,("demo-" if trial else "main-")+"recruit")
  game.paused=true;refresh(game);check(not guide.visible,"pause hides companion")
  game.paused=false;game.sim.core_loop.stage=3;refresh(game)
  game.sim.workforce.elapsed+=12;refresh(game)
  check(guide.modulate.a==0,"independent preparation lets companion quietly step aside")
  if not trial:
   var shrine: float=game.sim.spirit.shrine_x(game.sim.world.sites.hall)
   game.knight.position.x=shrine;refresh(game)
   key(KEY_E,true);key(KEY_E,false);game._physics_process(1.0/30)
   check(game.sim.spirit.summoned,"actual shrine input recalls the spirit after first night")
   check(guide.visible and guide.modulate.a>0.9 and not guide.hint.get("core",false),"paid recall visibly overrides the faded autonomous companion")
   game.sim.spirit.expires_tick=0
  game.sim.core_loop.stage=4;refresh(game)
  check(guide.visible and guide.modulate.a>0.9,"second night recalls warning companion")
  await capture(game,("demo-" if trial else "main-")+"warning")
  for bounds: Rect2 in game.hud.core_hud.exclusion_rects():
   check(not guide._guide_label.get_rect().intersects(bounds),"companion caption avoids action controls")
  game.sim.mission.outcome="defeat";refresh(game);check(not guide.visible,"defeat hides companion")
  game.queue_free();await frames(3)
 print("Core spirit scene: %d assertions, %d failures"%[assertions,failures]);quit(1 if failures else 0)
