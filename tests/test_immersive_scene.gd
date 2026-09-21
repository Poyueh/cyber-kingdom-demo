extends "res://tests/test_scene.gd"
## Actual current-campaign input path; legacy scene fixtures use their saved rules.
func touch(index: int, at: Vector2, down: bool) -> void:
 var event=InputEventScreenTouch.new();event.index=index;event.position=at;event.pressed=down
 root.push_input(event,true);Input.flush_buffered_events()
func drag(index: int, at: Vector2) -> void:
 var event=InputEventScreenDrag.new();event.index=index;event.position=at
 root.push_input(event,true);Input.flush_buffered_events()
func run_scene() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 root.add_child(game)
 await frames(8)
 game.knight.position=Vector2(30,430)
 await frames(3)
 key(KEY_J,true);await frames(2);key(KEY_J,false)
 check(game.sim.hero.attack_remaining==0,"unlit knight cannot attack via actual keyboard")
 check(game.knight.visual.unarmed,"unlit knight renders without sword")
 key(KEY_E,true);await frames(2);key(KEY_E,false);await frames(3)
 check(game.sim.frontier.city_level==1,"E draws the sword and lights camp")
 check(not game.knight.visual.unarmed,"ignition enables armed appearance")
 check(game.hud.dashboard.immersive,"new journey hides numerical top dashboard")
 game.knight.position.x=game.sim.world.sites.workshop
 await frames(4)
 var wallet: int=game.sim.pouch.amount
 key(KEY_E,true);await frames(2);key(KEY_E,false);await frames(2)
 check(game.sim.investments.is_empty(),"keyboard release refunds unfinished investment")
 check(game.sim.pouch.amount==wallet-1,"refund flies through world before collection")
 game.sim.hero.stamina=0
 key(KEY_SHIFT,true);key(KEY_D,true)
 await frames(3)
 check(game.sim.travel.exhausted and game.knight.velocity.x==0,"fast-run exhaustion physically stops knight")
 check(game.knight.visual.breathing,"exhaustion connects to breathing animation")
 key(KEY_D,false);key(KEY_SHIFT,false)
 game.sim.workforce.elapsed=155
 game.hud.present_world(game.sim,false,game.knight.position.x,true)
 check(game.hud.guide_view.hint.is_empty(),"ghost retires after early guidance")
 game.sim._hit_structure({"kind":"core","x":30.0},10)
 game.hud.present_world(game.sim,false,game.knight.position.x,true)
 check(game.hud.immersive_feedback._alarm>0,"core damage produces global alarm cue")
 game.restart();game.knight.position=Vector2(30,430)
 game.hud.control_mode=2;await frames(3)
 check(not game.hud.guide_view.touch_hint,"desktop guide chooses keyboard prompts")
 check(game.hud.guide_view._guide_label.text.contains(tr("按住 E 投入／互動")),"desktop ghost names actual interaction key")
 game.hud.control_mode=1;game.hud._layout();await frames(3)
 check(game.hud.guide_view.touch_hint,"phone guide chooses drag prompts")
 touch(20,Vector2(100,260),true);drag(20,Vector2(100,320));await frames(2)
 touch(20,Vector2(100,320),false);await frames(3)
 check(game.sim.frontier.city_level==1,"phone downward gesture ignites camp")
 game.knight.position.x=game.sim.world.sites.workshop;await frames(3)
 touch(21,Vector2(450,210),true);drag(21,Vector2(450,270));await frames(2)
 touch(21,Vector2(450,270),false);await frames(2)
 check(game.sim.investments.is_empty() and game.sim.pouch.ground_total()>0,"phone release refunds incomplete tool purchase physically")
 game.queue_free();await process_frame
 print("Immersive scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
