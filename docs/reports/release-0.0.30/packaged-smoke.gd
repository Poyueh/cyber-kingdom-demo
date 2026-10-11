extends SceneTree
func shot(game: Node, name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/invasion-march")
	game.get_viewport().get_texture().get_image().save_png("res://test-results/invasion-march/"+name+".png")

func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await frames(10)
	game.sim.frontier.city_level=1;game.sim.survival.armed=true;game.sim.world.people.clear()
	game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
	game.sim.clock.day=4;game.sim.clock.survived=3;game.sim.clock.is_night=true;game.sim.clock.remaining=45.0
	game.hud.control_mode=2
	game.knight.position.x=5000.0
	await frames(8)
	var enemy: Dictionary=game.sim._spawn_raider();enemy.x=6500.0;enemy.side=1;enemy.exit_x=game.sim.mission.entry_x(1)
	game.sim.raiders.append(enemy)
	var before: float=enemy.x;var start: float=game.sim.workforce.elapsed
	await frames(30)
	var elapsed: float=game.sim.workforce.elapsed-start
	check(not game.hud.uses_touch_controls(),"native scenario uses desktop layout first")
	check(before-enemy.x>140.0*elapsed,"actual scene advances a distant attacker faster than its combat walk")
	check(enemy.x<before and enemy.x>game.knight.position.x+1000.0,"arrival is continuous world movement outside the reaction zone")
	enemy.x=game.knight.position.x+320.0;before=enemy.x;start=game.sim.workforce.elapsed
	await frames(30);elapsed=game.sim.workforce.elapsed-start
	check(absf(before-enemy.x-70.0*elapsed)<0.1,"visible close approach keeps the original movement speed")
	await shot(game,"approach")
	key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
	check(game.paused,"desktop pause stops the encounter")
	before=enemy.x;await frames(20)
	check(is_equal_approx(enemy.x,before),"distant march also freezes while paused")
	key(KEY_ESCAPE,true);await frames(2);key(KEY_ESCAPE,false);await frames(2)
	game.hud.control_mode=1
	enemy.x=game.knight.position.x+320.0;before=enemy.x;start=game.sim.workforce.elapsed
	await frames(20);elapsed=game.sim.workforce.elapsed-start
	check(game.hud.uses_touch_controls(),"touch scenario displays actual touch controls")
	check(absf(before-enemy.x-70.0*elapsed)<0.1,"touch layout has the same near-field movement rule")
	await shot(game,"touch")
	game.queue_free();await process_frame
	print("Invasion march scene assertions: %d; failures: %d"%[assertions,failures])
	quit(0 if failures==0 else 1)

var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	ProjectSettings.set_setting("campaign/control_preview",1)
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	call_deferred("run_scene")

func check(value: bool, description: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for unused in range(count):
		await physics_frame

func wait_for_damage(fighter) -> void:
	var before: int = fighter.hp
	for tick in range(30):
		await physics_frame
		if fighter.hp < before:
			return
