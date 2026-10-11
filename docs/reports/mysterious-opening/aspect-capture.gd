extends "res://tests/test_scene.gd"
func run_scene() -> void:
 set_meta("campaign_prologue_seen",true)
 var menu: Control=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory="user://title_aspects_test";menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu);await frames(4)
 for dimensions: Vector2i in [Vector2i(1024,768),Vector2i(1170,540)]:
  root.size=dimensions;await frames(5)
  for locale: String in ["zh_TW","zh_CN","en"]:
   TranslationServer.set_locale(locale);menu.view._refresh_language();await frames(3)
   check(menu.view.get_global_rect().encloses(menu.view.replay_button.get_global_rect()),"replay fits "+str(dimensions)+" / "+locale)
   check(menu.view.get_global_rect().encloses(menu.view.new_button.get_global_rect()),"primary action fits "+str(dimensions)+" / "+locale)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/cyber-title-"+str(dimensions.x)+".png")
 menu.show_prologue();await frames(4)
 key(KEY_ENTER,true);key(KEY_ENTER,false);await frames(5)
 check(menu.view.visible and not is_instance_valid(menu._prologue),"Enter skips and returns to the menu")
 check(not menu.view.pace_picker.visible and menu.catalog.entries().is_empty(),"Enter skip does not begin a journey")
 menu.queue_free();await frames(3)
 print("Title aspect assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
