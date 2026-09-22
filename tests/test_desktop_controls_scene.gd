extends "res://tests/test_scene.gd"
func mouse_at(at: Vector2, down: bool, device: int=0) -> void:
 var event: InputEventMouseButton=InputEventMouseButton.new()
 event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT
 event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 event.pressed=down;event.device=device
 root.push_input(event,true);Input.flush_buffered_events()
func menu_point(at: Vector2, down: bool) -> void:
 # parse_input_event does not synthesize OS mouse-to-touch emulation. Supply both
 # halves of the configured desktop pointing route to the real scene.
 mouse_at(at,down)
 var event: InputEventScreenTouch=InputEventScreenTouch.new()
 event.index=0;event.position=at;event.pressed=down;event.device=InputEvent.DEVICE_ID_EMULATION
 root.push_input(event,true);Input.flush_buffered_events()
func tap_again(code: int) -> void:
 key(code,false);await frames(2);key(code,true);await frames(3)
func run_scene() -> void:
 ProjectSettings.set_setting("campaign/control_preview",2)
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(12)
 game.sim.interact(30,"hall");game.knight.position=Vector2(30,430)
 await frames(160)
 key(KEY_D,true);await frames(3)
 var normal: float=game.knight.velocity.x
 check(normal>0,"one press starts ordinary movement")
 key(KEY_SHIFT,true);await frames(3)
 check(is_equal_approx(game.knight.velocity.x,normal),"Shift no longer activates sprint")
 key(KEY_SHIFT,false);await tap_again(KEY_D)
 check(game.knight.velocity.x>normal*1.5,"second D press held down starts sprint")
 await frames(20)
 check(game.knight.velocity.x>normal*1.5,"continued hold preserves sprint")
 key(KEY_D,false);await frames(3)
 check(is_zero_approx(game.knight.velocity.x),"releasing the second press stops movement")
 key(KEY_A,true);await frames(3)
 check(is_equal_approx(game.knight.velocity.x,-normal),"changing direction starts ordinary movement")
 await tap_again(KEY_A)
 check(game.knight.velocity.x< -normal*1.5,"double A also sprints left")
 key(KEY_D,true);await frames(3)
 check(is_zero_approx(game.knight.velocity.x),"opposed keys cancel movement")
 key(KEY_A,false);await frames(3)
 check(is_equal_approx(game.knight.velocity.x,normal),"opposed input does not transfer sprint to the other direction")
 key(KEY_D,false);await frames(25)
 key(KEY_D,true);await frames(24);await tap_again(KEY_D)
 check(is_equal_approx(game.knight.velocity.x,normal),"a slow second press is ordinary movement")
 var echo: InputEventKey=InputEventKey.new()
 echo.physical_keycode=KEY_D;echo.keycode=KEY_D;echo.pressed=true;echo.echo=true
 Input.parse_input_event(echo);Input.flush_buffered_events();await frames(3)
 check(is_equal_approx(game.knight.velocity.x,normal),"keyboard auto-repeat cannot trigger sprint")
 key(KEY_D,false);await frames(25)
 key(KEY_D,true);await frames(2);await tap_again(KEY_D)
 key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false)
 check(game.paused,"Escape pauses a held sprint")
 var stopped: Vector2=game.knight.position
 key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(3)
 check(game.knight.position==stopped,"resuming does not replay a held sprint")
 key(KEY_D,false);await frames(25)
 game.sim.hero.stamina=100
 var world_click: Vector2=Vector2(500,240)
 mouse_at(world_click,true);await frames(3)
 check(game.sim.hero.attack_remaining>0,"left mouse click starts a real sword attack")
 await frames(80)
 check(game.sim.hero.attack_remaining==0,"holding mouse does not auto-attack")
 mouse_at(world_click,false);await frames(3)
 mouse_at(world_click,true);await frames(2);mouse_at(world_click,false);await frames(9)
 mouse_at(world_click,true);await frames(2);mouse_at(world_click,false);await frames(18)
 check(game.sim.hero.combo_step==2,"repeated left clicks connect a combo")
 await frames(80)
 var button: TouchScreenButton=game.hud.get_node("pause")
 var at: Vector2=button.position+Vector2(32,32)
 menu_point(at,true);await frames(1);menu_point(at,false);await frames(3)
 check(game.paused and game.sim.hero.attack_remaining==0,"clicking the hamburger opens UI without attacking")
 menu_point(at,true);await frames(1);menu_point(at,false);await frames(4)
 check(not game.paused and game.sim.hero.attack_remaining==0,"closing the menu does not leak an attack")
 mouse_at(world_click,true,InputEvent.DEVICE_ID_EMULATION);await frames(3)
 check(game.sim.hero.attack_remaining==0,"touch-generated mouse events do not attack")
 mouse_at(world_click,false,InputEvent.DEVICE_ID_EMULATION)
 game.queue_free();await frames(3)
 print("Desktop control scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
