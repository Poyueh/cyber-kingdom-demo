extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10)
 game.set_physics_process(false);game.paused=false
 game.sim.frontier.city_level=1;game.sim.survival.armed=true
 game.knight.position=Vector2(30,430)
 game.sim.mission.damage_core(game.sim.mission.core_hp)
 game._physics_process(1.0/60);await frames(2)
 check(game.sim.mission.outcome=="defeat","camp destruction records the loss")
 var at: float=game.knight.position.x
 key(KEY_D,true)
 for tick: int in range(12):
  await physics_frame;game._physics_process(1.0/60)
 key(KEY_D,false)
 check(game.knight.position.x>at+5,"knight can finish moving while the blackout begins")
 if game.hud.dashboard.has_method("blackout_alpha"):
  check(game.hud.dashboard.blackout_alpha()>0 and game.hud.dashboard.message_alpha()==0,"blackout begins before any defeat message")
 else:check(false,"defeat needs independently timed blackout and message")
 await create_timer(3.0).timeout
 game._physics_process(1.0/60)
 at=game.knight.position.x
 var wallet: int=game.sim.pouch.amount
 key(KEY_D,true);key(KEY_J,true);game.hud.throw_requested.emit()
 for tick: int in range(6):
  await physics_frame;game._physics_process(1.0/60)
 key(KEY_D,false);key(KEY_J,false)
 check(game.knight.position.x==at and game.sim.pouch.amount==wallet,"message locks motion, attacking and spending")
 if game.hud.dashboard.has_method("blackout_alpha"):
  check(game.hud.dashboard.blackout_alpha()==1 and game.hud.dashboard.message_alpha()==1,"defeat message rests on a complete blackout")
 key(KEY_ESCAPE,true);await physics_frame;game._physics_process(1.0/60);key(KEY_ESCAPE,false)
 check(game.paused and game.hud.options_menu.visible,"finished defeat still permits returning to title through the menu")
 game.queue_free();await frames(2)
 print("Camp loss scene assertions: %d; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
