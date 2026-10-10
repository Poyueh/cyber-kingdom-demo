extends "res://tests/test_scene.gd"
func place(game: Node, x: float) -> void:
 game.knight.position=Vector2(x,430);game.knight.velocity=Vector2.ZERO
 game.knight.get_node("Camera2D").reset_smoothing()
 await frames(35)
func tap(game: Node) -> void:
 key(KEY_E,true);await frames(2);key(KEY_E,false);await frames(2)
func capture(game: Node, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/mount-expedition")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/mount-expedition/"+name+".png")
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);await frames(10)
 game.sim.frontier.city_level=1;game.sim.survival.armed=true;game.sim.pouch.amount=30
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 game.sim.clock.day=2
 game.hud.control_mode=2
 game.sim.clock.remaining=game.sim.clock.day_seconds*0.6
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 var q: RefCounted=game.sim.mount_quest
 for index: int in [0,1,1]:
  await place(game,q.levers[index]);await tap(game)
 check(q.powered(),"real E input aligns both physical junctions")
 await capture(game,"junction")
 await place(game,q.ruin_x);await frames(60);await capture(game,"cradle")
 await tap(game)
 check(q.recovered,"real E input claims the awakened steed")
 await place(game,q.stable_x)
 check(game.sim.context(q.stable_x).key=="mount_stable","stable is selectable without a nearby building stealing input")
 for i: int in range(q.cost):await tap(game)
 check(game.sim.mounted() and game.knight.mounted,"crystal sockets unlock the real horse presentation")
 await frames(15);await capture(game,"stable")
 await tap(game);check(not game.knight.mounted,"same E input dismounts at the stable")
 await tap(game);check(game.knight.mounted,"same E input mounts again")
 key(KEY_D,true);await frames(10)
 check(game.knight.velocity.x>game.tuning.walking_speed,"reward actually increases ground speed")
 key(KEY_D,false);await frames(2)
 game.hud.control_mode=1;await frames(10);await capture(game,"touch")
 check(game.hud.uses_touch_controls(),"mobile presentation retains touch input")
 game.queue_free();await process_frame
 print("Mount expedition scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
