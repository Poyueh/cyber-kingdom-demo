extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene: Node=load("res://scenes/frontier.tscn").instantiate()
 scene._core_trial=true;scene.campaign_save_path="";scene.audio_preferences_path=""
 root.add_child(scene)
 await frames(15)
 check(scene.sim.core_loop.enabled,"real frontier opens the independent core trial")
 check(scene.hud.core_hud.wallet.visible,"core wallet is visible in the scene")
 check(scene.hud.guide_view.visible and scene.hud.guide_view.modulate.a>0.9,"demo onboarding visibly restores the spirit companion")
 scene.knight.position.x=scene.sim.world.sites.hall
 await frames(4)
 var action: Button=scene.hud.core_hud.action_button
 check(action.visible and not action.disabled,"camp exposes a tappable contextual action")
 var at: Vector2=action.get_global_rect().get_center()
 var press: InputEventMouseButton=InputEventMouseButton.new();press.position=at;press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true
 root.push_input(press,true)
 await frames(2)
 press=press.duplicate();press.pressed=false;root.push_input(press,true)
 await frames(180)
 check(scene.sim.frontier.city_level==1,"real pointer click lights camp through input adapter")
 key(KEY_D,true);await frames(15);key(KEY_D,false)
 check(scene.knight.position.x>scene.sim.world.sites.hall+20,"keyboard runs the core knight")
 # Values sit beside what they describe: stamina under the knight, the crystal count by the pouch.
 scene.sim.hero.stamina=scene.sim.hero.stats.max_stamina*0.5
 await frames(2)
 var hud: Control=scene.hud.core_hud
 var hero: Vector2=scene.get_viewport().get_canvas_transform()*Vector2(scene.knight.position.x,scene.sim._player_y)
 var bar: Rect2=hud.stamina.get_global_rect()
 check(hud.stamina.visible and absf(bar.get_center().x-hero.x)<=4,"stamina bar is centred on the knight")
 # The knight's feet are about 16 px below the anchor; the bar sits just under them.
 check(bar.position.y>=hero.y+16 and bar.position.y<=hero.y+40,"stamina bar sits just under the knight's feet")
 # The warhorse stands on the same ground, so the bar stays under the hooves.
 scene.sim.frontier.drill_level=3
 await frames(2)
 bar=hud.stamina.get_global_rect()
 check(scene.sim.mounted() and bar.position.y>=hero.y+16 and bar.position.y<=hero.y+40,"stamina bar stays under a mounted rider")
 scene.sim.frontier.drill_level=0
 await frames(2)
 var purse: Rect2=scene.hud.immersive_feedback.purse.bounds
 var wallet: Rect2=hud.wallet.get_global_rect()
 check(wallet.end.x<=purse.position.x and purse.position.x-wallet.end.x<=16,"crystal count sits just left of the pouch")
 check(wallet.get_center().y>=purse.position.y and wallet.get_center().y<=purse.end.y,"crystal count is level with the pouch")
 check(hud.wallet.text=="×%d"%scene.sim.pouch.amount and hud.wallet_icon.visible,"the count is a crystal icon and a multiplier, without the word")
 check(hud.wallet_icon.get_global_rect().end.x<=wallet.position.x+2,"the crystal icon leads the number")
 scene.sim.hero.stamina=0
 key(KEY_J,true);await frames(2);key(KEY_J,false)
 check(scene.sim.hero.attack_remaining>0,"real attack input works at exhausted stamina")
 scene.sim.core_loop.income=4;scene.sim.core_loop.stage=1
 await frames(4)
 scene.hud.core_hud.orders_button.pressed.emit()
 await frames(3)
 check(scene.paused and scene.hud.core_hud.panel.visible,"orders pause the actual world")
 check(not scene.hud.options_menu.visible,"orders replace pause options without overlap")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/core-orders-desktop.png")
 key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false)
 check(not scene.paused and not scene.hud.core_hud.panel.visible,"Escape closes orders and resumes cleanly")
 scene.hud.preview_safe_margins=Vector4(48,12,24,20);scene.hud._layout()
 await frames(3)
 for button: Button in [scene.hud.core_hud.orders_button,scene.hud.core_hud.guide_button,scene.hud.core_hud.action_button]:
  if button.visible:check(scene.hud.safe_rect().encloses(button.get_global_rect()),"core action stays inside the safe area")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/core-game-desktop.png")
 scene.sim.core_loop.checkpoint_pending=1
 scene._core_controller.observe()
 var saved_money: int=scene.sim.pouch.amount
 scene.sim.pouch.spend()
 key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false)
 await frames(3)
 await click_retry(scene)
 check(not scene.paused and scene.sim.pouch.amount==saved_money,"pause menu leaves preparation retry clickable and restores funds")
 scene.sim.mission.core_hp=0;scene.sim.mission.outcome="defeat";scene.sim.mission.defeat_reason="core"
 scene.paused=false
 await frames(240)
 check(scene.hud.core_hud.retry_button.visible,"retry appears after camp blackout completes")
 await click_retry(scene)
 check(scene.sim.mission.outcome=="active" and scene.sim.mission.core_hp>0,"retry is clickable above defeat blackout and restores camp")
 scene.queue_free();await process_frame
 print("Core scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)

func click_retry(scene: Node) -> void:
 var event: InputEventMouseButton=InputEventMouseButton.new()
 event.position=scene.hud.core_hud.retry_button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 root.push_input(event,true);await frames(2)
 event=event.duplicate();event.pressed=false;root.push_input(event,true);await frames(4)
