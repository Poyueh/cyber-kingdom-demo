extends "res://tests/test_scene.gd"
## Native integration review: live input, actual HUD hit regions, and a short cue lifecycle.
func refresh(game: Node) -> void:
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,false)
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game._core_trial=true;game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10);game.set_physics_process(false)
 var guide: Node=game.hud.guide_view
 game.knight.position.x=game.sim.world.sites.hall;refresh(game)
 for unused: int in range(75):game._physics_process(1.0/30)
 check(guide._guide_label.visible,"a first nearby action receives one short contextual cue")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);refresh(game)
  check(guide._guide_label.mouse_filter==Control.MOUSE_FILTER_IGNORE,"caption never captures touch: "+locale)
  check(game.hud.safe_rect().encloses(guide._guide_label.get_rect()),"caption fits safe area: "+locale)
  if guide._guide_label.visible:
   for bounds: Rect2 in guide.reserved_regions:check(not bounds.intersects(guide._guide_label.get_rect()),"visible cue avoids controls and interaction text")
 for unused: int in range(110):game._physics_process(1.0/30)
 check(not guide._guide_label.visible,"short cue clears while gesture remains")
 var first: Vector2=guide.spirit_pose.position
 var phase: float=guide.spirit_pose.phase
 refresh(game);refresh(game)
 check(guide.spirit_pose.position==first and guide.spirit_pose.phase==phase,"same simulation time cannot advance companion animation")
 key(KEY_E,true);key(KEY_E,false);game._physics_process(1.0/30)
 for unused: int in range(110):game._physics_process(1.0/30)
 check(game.sim.frontier.city_level==1 and guide.hint.kind=="recruit","actual founding input remains available below ghost")
 for unused: int in range(160):game._physics_process(1.0/30)
 check(guide.spirit_pose.age>4,"wandering residents do not repeatedly restart the greeting")
 key(KEY_D,true)
 for unused: int in range(12):game._physics_process(1.0/30)
 key(KEY_D,false)
 check(not guide._guide_label.visible,"moving knight is guided by motion without caption")
 game.paused=true;refresh(game);check(not guide.visible,"opening menu clears ghost and cue")
 game.queue_free();await frames(2)
 print("Companion native integration: %d assertions, %d failures"%[assertions,failures]);quit(1 if failures else 0)
