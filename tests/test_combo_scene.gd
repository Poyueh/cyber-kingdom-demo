extends "res://tests/test_scene.gd"
## Real keyboard and touch input through the campaign composition root.
func run_scene() -> void:
	var scene = load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12
	root.add_child(scene)
	await frames(8)
	scene.set_physics_process(false)
	# A held direction cannot slide the first slash; later cuts supply their own step.
	for direction in [KEY_D,KEY_A]:
		scene.restart()
		var sign_x := 1.0 if direction == KEY_D else -1.0
		scene.sim.hero.facing = int(sign_x)
		var seen := {}
		var planted := {}
		var travel := {1: 0.0, 2: 0.0, 3: 0.0}
		key(direction,true)
		for tick in range(65):
			await physics_frame
			scene.paused = false
			if tick in [0,8,23]: key(KEY_J,true)
			var before: float = scene.knight.position.x
			scene._physics_process(1.0/60)
			key(KEY_J,false)
			if scene.sim.hero.attack_remaining>0:
				var step: int = scene.sim.hero.combo_step
				seen[step] = true
				travel[step] += (scene.knight.position.x-before)*sign_x
				if scene.knight.get_node("KnightVisual/ComboAttack").visible and not scene.knight.get_node("KnightVisual/MovingAttack").visible:
					planted[step] = true
		key(direction,false)
		check(seen.size()==3,"keyboard presses reach all three cuts in each direction")
		check(planted.size()==3,"every cut uses planted sword choreography even with direction held")
		check(absf(travel[1])<0.01,"first slash ignores held movement")
		check(travel[2]>10 and travel[2]<40,"second cut advances a short controlled step")
		check(travel[3]>travel[2] and travel[3]<50,"finisher advances farther without running")
		var before_walk: float = scene.knight.position.x
		key(direction,true)
		await physics_frame
		scene._physics_process(1.0/60)
		key(direction,false)
		check((scene.knight.position.x-before_walk)*sign_x>1,"walking resumes after attack recovery")
	await verify_step_motion(scene)
	# Hold the touchscreen sword: one down event is one slash, never auto-chain.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = scene.hud.get_node("attack").get_global_transform_with_canvas().origin+Vector2(28,28)
	touch.pressed = true
	var held_steps := {}
	for tick in range(70):
		await physics_frame
		if tick==0:
			root.push_input(touch,true)
			Input.flush_buffered_events()
		scene.paused = false
		scene._physics_process(1.0/60)
		if scene.sim.hero.attack_remaining>0: held_steps[scene.sim.hero.combo_step] = true
	touch.pressed = false
	root.push_input(touch,true)
	Input.flush_buffered_events()
	check(held_steps.size()==1 and held_steps.has(1),"holding touchscreen sword produces one cut")
	var tapped_steps := {}
	for tick in range(70):
		await physics_frame
		scene.paused = false
		if tick in [0,1,8,9,23,24]:
			touch.pressed = tick in [0,8,23]
			root.push_input(touch,true)
		scene._physics_process(1.0/60)
		if scene.sim.hero.attack_remaining>0: tapped_steps[scene.sim.hero.combo_step]=true
	check(tapped_steps.size()==3,"three touchscreen taps connect the full combo")
	# Focus loss after a buffered press must not release it on resume.
	for tick in range(10):
		await physics_frame
		scene.paused = false
		if tick in [0,8]: key(KEY_J,true)
		scene._physics_process(1.0/60)
		key(KEY_J,false)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var frozen: float = scene.sim.hero.attack_progress()
	var frozen_position: Vector2 = scene.knight.position
	scene._physics_process(0.2)
	check(scene.knight.position==frozen_position,"focus pause freezes physical position")
	check(scene.sim.hero.attack_progress()==frozen,"focus pause freezes current attack pose")
	for tick in range(35):
		await physics_frame
		scene.paused = false
		scene._physics_process(1.0/60)
	check(scene.sim.hero.combo_step!=2,"resume discards buffered follow-up")
	scene.restart()
	check(scene.sim.hero.stats.combo_enabled and scene.sim.hero.combo_step==0,"restart keeps tuning and clears old combo")
	scene.controls.release_all()
	scene.queue_free()
	await process_frame
	print("Combo scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)

func verify_step_motion(scene) -> void:
	# Resource changes must reach gameplay through the composition root.
	var original: Resource = scene.combo_tuning
	scene.combo_tuning = original.duplicate()
	scene.combo_tuning.return_step_distance = 15.0
	scene.combo_tuning.finisher_step_distance = 24.0
	scene.restart()
	var origin: float = scene.knight.position.x
	for tick in range(65):
		await physics_frame
		scene.paused = false
		if tick in [0,8,23]: key(KEY_J,true)
		scene._physics_process(1.0/60)
		key(KEY_J,false)
	check(absf(scene.knight.position.x-origin-39.0)<0.1,"neutral input combo follows Inspector step distances")
	scene.combo_tuning = original
	scene.restart()
	# Turn intent changes the NEXT sword cut; it cannot drag this cut backwards.
	scene.sim.hero.start_attack()
	scene.sim.hero.advance(0.34)
	scene.sim.hero.start_attack()
	origin = scene.knight.position.x
	var backwards := false
	key(KEY_A,true)
	for tick in range(15):
		await physics_frame
		scene.paused = false
		var before: float = scene.knight.position.x
		scene._physics_process(1.0/60)
		backwards = backwards or scene.knight.position.x<before-0.001
	key(KEY_A,false)
	check(not backwards and absf(scene.knight.position.x-origin-22.0)<0.1,"opposite input cannot reverse the current forward step")
	# A real physics obstacle must stop the step, with no queued push after removal.
	scene.restart()
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8,100)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = scene.knight.position+Vector2(32,-40)
	scene.add_child(wall)
	await physics_frame
	origin = scene.knight.position.x
	for tick in range(65):
		await physics_frame
		scene.paused = false
		if tick in [0,8,23]: key(KEY_J,true)
		scene._physics_process(1.0/60)
		key(KEY_J,false)
	check(scene.knight.position.x>origin and scene.knight.position.x<wall.position.x-4,"combo advances up to actual wall collision without tunneling")
	wall.queue_free()
	await physics_frame
	origin = scene.knight.position.x
	for tick in range(5):
		await physics_frame
		scene._physics_process(1.0/60)
	check(absf(scene.knight.position.x-origin)<0.01,"blocked travel is discarded instead of released after wall removal")
	# Focus loss during the advancing cut freezes time; resuming completes only its remainder.
	scene.restart()
	scene.sim.hero.start_attack()
	scene.sim.hero.advance(0.34)
	scene.sim.hero.start_attack()
	origin = scene.knight.position.x
	for tick in range(7):
		await physics_frame
		scene.paused = false
		scene._physics_process(1.0/60)
	var paused_x: float = scene.knight.position.x
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	for tick in range(5):
		await physics_frame
		scene._physics_process(1.0/60)
	check(paused_x>origin and scene.knight.position.x==paused_x,"pause freezes an in-progress forward step")
	for tick in range(20):
		await physics_frame
		scene.paused = false
		scene._physics_process(1.0/60)
	check(absf(scene.knight.position.x-origin-22.0)<0.1,"resuming completes step without extra distance")
	# Dash cancels the rooted swing and takes control immediately.
	scene.restart()
	scene.sim.hero.start_attack()
	origin = scene.knight.position.x
	key(KEY_L,true)
	await physics_frame
	scene._physics_process(1.0/60)
	key(KEY_L,false)
	check(scene.sim.hero.attack_remaining>0 and is_equal_approx(scene.knight.position.x,origin),"removed dash cannot cancel the planted attack")
	scene.restart()
