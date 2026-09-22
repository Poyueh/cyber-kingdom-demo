extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(10)
 game.sim.interact(30,"hall");game.knight.position=Vector2(30,430)
 await frames(160) # Finish the sword ceremony before observing fatigue.
 key(KEY_D,true);await frames(6)
 var normal: float=game.knight.velocity.x
 check(normal>0,"ordinary input moves the real knight")
 key(KEY_D,false);await frames(2);key(KEY_D,true);await frames(6)
 check(game.knight.velocity.x>normal*1.5,"second tier is visibly faster than the normal run")
 game.sim.hero.stamina=0;await frames(4)
 check(is_zero_approx(game.knight.velocity.x),"actual exhaustion forces a breathing stop despite held input")
 var slid_while_resting: bool=false
 var saw_rest_pose: bool=false
 var moved_during_stop: bool=false
 var rest_at: Vector2=game.knight.position
 for tick: int in range(123):
  await frames(1)
  saw_rest_pose=saw_rest_pose or (game.knight.visual.fatigue.visible and game.knight.visual.fatigue.modulate.a>0.8)
  if game.sim.travel.breath_ticks>0:moved_during_stop=moved_during_stop or game.knight.position!=rest_at
  slid_while_resting=slid_while_resting or (game.knight.visual.fatigue.visible and game.knight.visual.fatigue.modulate.a>0.01 and absf(game.knight.velocity.x)>0.1)
 check(saw_rest_pose and not moved_during_stop,"held movement cannot displace the knight during the visible breathing stop")
 check(not slid_while_resting,"resting silhouette finishes in place before movement resumes")
 check(game.knight.velocity.x>0 and game.knight.velocity.x<normal*0.6,"breathing is followed by a distinct slow walk")
 game.sim.hero.stamina=40;await frames(4)
 check(is_equal_approx(game.knight.velocity.x,normal) and game.sim.travel.exhausted,"partial recovery restores running but keeps sprint locked")
 game.sim.hero.stamina=100;await frames(6)
 check(is_equal_approx(game.knight.velocity.x,normal),"holding the second tier cannot auto-cycle into sprint")
 key(KEY_D,false);await frames(60)
 key(KEY_D,true);await frames(3)
 check(is_equal_approx(game.knight.velocity.x,normal),"a one-second stop cannot clear the rest requirement")
 key(KEY_D,false);await frames(140)
 key(KEY_D,true);await frames(2);key(KEY_D,false);await frames(2);key(KEY_D,true);await frames(3)
 check(game.knight.velocity.x>normal*1.5,"two seconds of uninterrupted rest rearms the second tier")
 key(KEY_D,false)
 game.queue_free();await frames(3)
 print("Running recovery scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
