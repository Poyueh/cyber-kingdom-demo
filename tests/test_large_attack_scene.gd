extends "res://tests/test_mobile_scene.gd"
func run_scene() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(10)
 game.sim.interact(30,"hall");game.knight.position=Vector2(30,430)
 game.hud.preview_safe_margins=Vector4(44,10,35,20)
 await frames(4)
 # Safe-area layout runs on render frames, independently from physics ticks.
 await process_frame;await process_frame
 var safe: Rect2=game.hud.safe_rect()
 var edge: Vector2=safe.end-Vector2(113,64)
 touch(0,edge,true);await frames(3)
 check(game.sim.hero.attack_remaining>0,"outer left area of enlarged attack button starts a slash")
 check(game.hud.drag_controls.state.fingers.is_empty(),"attack touch cannot become a movement gesture")
 touch(0,edge,false);await frames(3)
 check(not Input.is_action_pressed("attack"),"releasing the enlarged button clears attack input")
 touch(1,Vector2(180,300),true);drag(1,Vector2(220,300));await frames(2)
 check(game.hud.movement_axis()>0,"movement remains available beside enlarged attack button")
 touch(1,Vector2(220,300),false)
 game.paused=true;game.hud.present_world(game.sim,true,game.knight.position.x,true)
 check(not game.hud.get_node("attack").visible,"pause hides the enlarged attack button")
 game.queue_free();await frames(3)
 print("Large attack scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
