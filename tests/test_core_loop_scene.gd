extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene: Node=load("res://scenes/frontier.tscn").instantiate()
 scene._core_trial=true;scene.campaign_save_path="";scene.audio_preferences_path=""
 root.add_child(scene)
 await frames(15)
 check(scene.sim.core_loop.enabled,"real frontier opens the independent core trial")
 check(scene.hud.core_hud.wallet.visible,"core wallet is visible in the scene")
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
 scene.queue_free();await process_frame
 print("Core scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
