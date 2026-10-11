extends "res://tests/test_mobile_scene.gd"
func refresh(game: Node) -> void:
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 game.view.present(game.sim,game.knight.position.x)
 game.hud.present_world(game.sim,game.paused,game.knight.position.x,true)
 game._water.present(game.sim);game._sunbeams.present(game.sim)
func capture(game: Node, filename: String) -> void:
 refresh(game);await frames(3);refresh(game)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/supply-guidance")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/supply-guidance/"+filename+".png")
func empty_camp(game: Node, mobile: bool) -> void:
 game.sim.pouch.amount=0;game.knight.position=Vector2(30,430)
 game.hud.control_mode=1 if mobile else 2
 refresh(game)
 check(game.hud.guide_view.hint.get("kind")=="camp","empty pouch is still guided to free sword and fire")
 if mobile:
  touch(31,Vector2(180,220),true);drag(31,Vector2(180,275));touch(31,Vector2(180,275),false)
 else:key(KEY_E,true);key(KEY_E,false)
 game._physics_process(1.0/30)
 check(game.sim.frontier.city_level==1 and game.sim.can_wield_sword(),"free camp lights with "+("down swipe" if mobile else "E"))
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(8);game.set_physics_process(false)
 await empty_camp(game,false)
 game.restart();await frames(3);game.set_physics_process(false)
 await empty_camp(game,true)
 # Visual fixture: first gift already used, a resident owns earned income.
 game.sim.merchant.phase=game.sim.merchant.Phase.WAITING_PAYMENT
 game.sim.merchant.x=game.sim.merchant.home_x
 game.sim.pouch.drops.clear();game.sim.pouch.amount=1
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
 game.sim.world.people[0].role="engineer";game.sim.world.people[0].x=510.0
 game.sim.world.people[0]["crystals"]=4
 game.sim.world.people[1].role="citizen"
 # This fixture follows a carrier east with D; choose his job on that side.
 game.sim.frontier.nodes.filter(func(n: RefCounted)->bool:return n.kind=="tree" and n.x>510.0)[0].marked=true
 game.knight.position=Vector2(game.sim.spirit.shrine_x(game.sim.world.sites.hall),430)
 game._arrival_banner.hide();game.hud.control_mode=2
 key(KEY_E,true);key(KEY_E,false);game._physics_process(1.0/30)
 check(game.sim.pouch.amount==0 and game.sim.spirit.summoned,"last crystal summons the guide through the actual E interaction")
 check(game.hud.guide_view.hint.get("kind")=="resident_income","recalled ghost points to resident income")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);await capture(game,"income-"+locale)
  var label: Label=game.hud.guide_view._guide_label
  check(label.text.contains(game.tr("guide.income")) and not label.text.contains("guide."),"income text is translated in "+locale)
  check(game.hud.safe_rect().encloses(label.get_rect()),"caption fits the viewport in "+locale)
  check(not label.get_rect().intersects(game.hud.immersive_feedback.day_caption_bounds()),"translated hint avoids the temporary day caption in "+locale)
 game.hud.control_mode=1;game.hud.preview_safe_margins=Vector4(90,18,30,32);game.hud._layout()
 await capture(game,"income-touch-safe")
 check(game.hud.safe_rect().encloses(game.hud.guide_view._guide_label.get_rect()),"English hint fits touch safe insets")
 check(not game.hud.guide_view._guide_label.get_rect().intersects(game.hud.immersive_feedback.day_caption_bounds()),"touch hint avoids sunrise caption with safe insets")
 game.hud.preview_safe_margins=Vector4.ZERO;game.hud.control_mode=2;game.hud._layout()
 TranslationServer.set_locale("zh_TW")
 game.set_physics_process(true);key(KEY_D,true)
 for tick: int in range(180):
  await physics_frame
  if game.sim.pouch.amount>=4:break
 key(KEY_D,false);game.set_physics_process(false)
 check(game.sim.pouch.amount>=4,"walking to the carrier receives the visible crystal burst without payment")
 await capture(game,"received-income")
 game.sim.pouch.amount=0;game.sim.pouch.drops.clear()
 for person: Dictionary in game.sim.world.people:person["crystals"]=0
 for node: RefCounted in game.sim.frontier.nodes:node.marked=false;node.worker=-1
 game.sim.merchant.phase=game.sim.merchant.Phase.RETURNING
 game.sim.merchant.return_day=game.sim.clock.day
 game.sim.merchant.x=game.sim.merchant.home_x+500
 game.knight.position=Vector2(game.sim.merchant.home_x,430)
 game.hud.control_mode=1;refresh(game)
 check(game.hud.guide_view.hint.get("kind")=="merchant_return","returning trader points to camp")
 check(game.hud.guide_view._guide_label.text.contains(game.tr("guide.command.trade_wait")),"waiting for a merchant is not mislabeled as taking tools")
 await capture(game,"merchant-touch")
 game.sim.planet.cleared=true;game.sim.planet.claim_core();game.sim.planet.rocket_pending=true
 game.knight.position=Vector2(preload("res://application/planet_operations.gd").rocket_x(game.sim),430)
 refresh(game)
 check(game.hud.guide_view._guide_label.text.contains(game.tr("guide.rocket_building")),"rocket construction has a specific progress caption")
 check(game.hud.guide_view._guide_label.text.contains(game.tr("guide.command.rocket_wait")),"paid rocket never asks for another purchase")
 await capture(game,"rocket-work")
 game.paused=true;refresh(game)
 check(not game.hud.guide_view.visible,"pause hides the guidance")
 game.paused=false;game.sim.spirit.expires_tick=0;refresh(game)
 check(not game.hud.guide_view.visible,"visit expiry still removes the guide")
 game.audio.enabled=false;game.audio.stop();game.queue_free();await frames(2)
 print("Supply guidance scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
