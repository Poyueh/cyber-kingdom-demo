extends "res://tests/test_mobile_scene.gd"
func capture_game(game: Node, name: String) -> void:
 await process_frame
 await process_frame
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/planet-modules")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/planet-modules/"+name+".png")
func click_button(button: Button) -> void:
 for down: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=button.get_global_rect().get_center()
  root.push_input(event,true);Input.flush_buffered_events();await frames(2)
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";root.add_child(game);await frames(8)
 game.set_physics_process(false)
 game.sim.interact(30,"hall");game.sim.pouch.amount=30
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 game.hud.control_mode=2
 for id: String in ["arc","lance","magnet","frost"]:
  game.sim.modules.found.append(id);game.sim.modules.stored.append(id)
 for site: RefCounted in game.sim.trials.sites:site.progress=3
 game.sim.modules.equipped="arc"
 game.knight.position=Vector2(game.sim.world.sites.drill,430)
 game.sim.advance(0.1,game.knight.position.x)
 game.knight.get_node("Camera2D").reset_smoothing()
 TranslationServer.set_locale("zh_TW")
 game._physics_process(1.0/30)
 key(KEY_F,true);key(KEY_F,false);game._physics_process(1.0/30);await frames(5)
 check(game.hud.module_menu.visible and game.paused,"F opens the expanded collection")
 var menu: Control=game.hud.module_menu
 check(menu._buttons.size()==8,"all eight styles are visible in the catalogue")
 await capture_game(game,"collection-zh-TW")
 await click_button(menu._buttons[3])
 check(game.sim.modules.equipped=="frost" and game.sim.pouch.amount==22,"real menu click installs frost for eight crystals")
 for locale: String in ["zh_CN","en"]:
  TranslationServer.set_locale(locale);menu.present(game.sim.modules,false,game.sim.pouch.amount);await frames(5)
  await capture_game(game,"collection-"+locale)
  check(not menu._title.text.begins_with("module."),"collection title translates in "+locale)
 menu._scroll.scroll_vertical=1000;await frames(5);await capture_game(game,"collection-bottom")
 await click_button(menu._close);game._physics_process(1.0/30)
 var enemy: Dictionary=game.sim._spawn_raider();enemy.x=game.knight.position.x+140;game.sim.raiders.append(enemy)
 key(KEY_K,true);key(KEY_K,false);game._physics_process(1.0/30)
 check(enemy.has("module_chill_until"),"K uses new frost ability against an actual enemy")
 await frames(6);await capture_game(game,"frost")
 game.sim.modules.ready_tick=0;game.sim.hero.stamina=100
 game.hud.control_mode=1;game._physics_process(1.0/30)
 touch(10,Vector2(180,330),true);touch(11,Vector2(340,330),true)
 drag(10,Vector2(180,245));drag(11,Vector2(340,245))
 touch(10,Vector2(180,245),false);touch(11,Vector2(340,245),false)
 game._physics_process(1.0/30)
 check(game.sim.modules.ready_tick>0,"two-finger up gesture activates the new ability")
 game.hud.loadout_requested.emit();game._physics_process(1.0/30);await frames(5)
 menu.arrange(Rect2(24,12,912,516));menu.present(game.sim.modules,true,game.sim.pouch.amount)
 await frames(5);await capture_game(game,"collection-touch")
 check(menu._close.size.y>=46,"touch menu retains a reachable return control")
 game.queue_free();await process_frame
 print("Planet module scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
