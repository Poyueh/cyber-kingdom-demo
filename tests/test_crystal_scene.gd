extends SceneTree
var assertions := 0
var failures := 0
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run_test")
func check(value: bool, message: String) -> void:
	assertions+=1
	if not value:
		failures+=1
		printerr("FAIL: ",message)
	else: print("PASS: ",message)
func frames(count: int) -> void:
	for tick in range(count): await physics_frame
func key(code: int, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func click(button: Button) -> void:
	if not button.visible:
		preload("res://tests/touch_gesture.gd").start(root)
		await frames(2)
		preload("res://tests/touch_gesture.gd").finish(root)
		await frames(2)
		return
	var at:=root.get_final_transform()*button.get_global_rect().get_center()
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=at
		event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
func run_test() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false
	root.add_child(scene)
	await frames(5)
	check(scene.hud.drop_button.text.is_empty() and scene.hud.drop_button.icon!=null,"drop control uses an icon")
	var before: int=scene.sim.pouch.amount
	key(KEY_Q,true)
	await frames(2)
	key(KEY_Q,false)
	check(scene.sim.pouch.amount==before-1 and scene.sim.pouch.ground_total()==1,"Q throws one conserved crystal through actual input")
	await frames(8)
	check(scene.sim.pouch.amount==before-1,"nearby freshly thrown currency is not immediately absorbed")
	await click(scene.hud.drop_button)
	check(scene.sim.pouch.amount==before-2,"downward drag throws one more crystal")
	scene.knight.position=Vector2(-100,320)
	scene.knight.velocity=Vector2.ZERO
	await frames(2)
	check(not scene.knight.is_on_floor(),"test knight is airborne")
	key(KEY_Q,true)
	await frames(2)
	key(KEY_Q,false)
	check(scene.sim.pouch.amount==before-3,"Q throws during a jump without requiring floor contact")
	key(KEY_ESCAPE,true)
	await frames(2)
	key(KEY_ESCAPE,false)
	var drops: Array=scene.sim.pouch.drops.duplicate(true)
	var time: float=scene.sim.workforce.elapsed
	key(KEY_Q,true)
	await frames(2)
	key(KEY_Q,false)
	await click(scene.hud.drop_button)
	await frames(8)
	check(scene.paused and scene.sim.pouch.drops==drops,"pause freezes physical crystals and blocks both throw routes")
	check(scene.sim.workforce.elapsed==time,"pause freezes the clock shared by all idle artwork")
	check(scene.hud.drop_button.disabled,"paused drop button is disabled")
	key(KEY_ESCAPE,true)
	await frames(2)
	key(KEY_ESCAPE,false)
	check(scene.sim.pouch.amount==before-3,"resuming does not replay paused throws")
	scene.sim.pouch.amount=0
	await frames(2)
	check(scene.hud.drop_button.disabled,"empty backpack disables throw icon")
	var ground_before: int=scene.sim.pouch.ground_total()
	key(KEY_Q,true)
	await frames(2)
	key(KEY_Q,false)
	check(scene.sim.pouch.ground_total()==ground_before,"empty Q does not create a crystal")
	scene.restart()
	await frames(2)
	check(scene.sim.pouch.drops.is_empty(),"restart clears old physical drops")
	scene.queue_free()
	await process_frame
	print("Crystal scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
