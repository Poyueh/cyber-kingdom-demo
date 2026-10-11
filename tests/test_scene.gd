extends SceneTree
## Exercise actual physics, InputMap, scene wiring and persistence together.
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

func run_scene() -> void:
	verify_art_override()
	var scene = load("res://scenes/training.tscn").instantiate()
	var location := "user://test_scene_%d.json" % Time.get_ticks_usec()
	scene.progress_path = location
	scene.hit_stop_seconds = 0.05 # Exercise buffering with a deliberately longer stop.
	root.add_child(scene)
	await frames(12)
	check(scene.knight.is_on_floor(), "knight lands on actual collision floor")
	var start_x: float = scene.knight.position.x
	key(KEY_D, true)
	await frames(12)
	key(KEY_D, false)
	check(scene.knight.position.x > start_x + 10.0, "D key moves knight through input adapter")
	check(scene.knight.visual.animation == &"run", "moving knight displays run artwork in real scene")
	key(KEY_SPACE, true)
	await frames(2)
	key(KEY_SPACE, false)
	check(scene.knight.velocity.y < 0.0, "Space starts physical jump")
	check(scene.knight.visual.animation == &"jump", "airborne knight uses dedicated jump drawing")
	key(KEY_L, true)
	await frames(2)
	key(KEY_L, false)
	check(scene.session.hero.stamina < 100.0, "L dash consumes model stamina")
	check(scene.knight.visual.animation == &"dash", "airborne dash displays its own pose")
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	check(scene.paused, "Escape pauses encounter")
	var paused_position: Vector2 = scene.knight.position
	await frames(4)
	check(scene.knight.position == paused_position, "pause freezes physical motion")
	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	check(not scene.paused and scene.session.hero.hp == 100, "R restarts and resumes")
	await frames(12)
	scene.knight.position = Vector2(620, 430)
	scene.sentinel.position = Vector2(655, 430)
	scene.session.hero.stats.damage = 200
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	check(scene.session.enemy.is_alive(), "windup does not hit immediately")
	check(scene.knight.visual.animation == &"attack" and scene.knight.visual.frame == 0, "visible windup matches zero damage")
	await wait_for_damage(scene.session.enemy)
	check(not scene.session.enemy.is_alive(), "J attack hits nearby sentinel")
	check(scene.knight.visual.frame == 4, "hit occurs while visible blade is active")
	check(scene.impacts.has_impacts(), "killing strike still emits impact sparks")
	check(scene.session.scrap == 20, "scene grants one defeat reward")
	check(scene.store.load_scrap() == 20, "scene writes isolated progress save")
	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	await frames(12)
	scene.knight.position = Vector2(620, 430)
	scene.sentinel.position = Vector2(655, 430)
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	key(KEY_L, true)
	await frames(2)
	key(KEY_L, false)
	check(scene.session.enemy.hp == 100, "dash cancels windup before damage")
	check(scene.knight.visual.animation == &"dash", "dash replaces cancelled sword with its burst artwork")

	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	await frames(12)
	scene.knight.position = Vector2(620, 430)
	scene.sentinel.position = Vector2(655, 430)
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	var held_frame: int = scene.knight.visual.frame
	var held_hp: int = scene.session.enemy.hp
	await frames(12)
	check(scene.knight.visual.frame == held_frame and scene.session.enemy.hp == held_hp, "pause freezes both sword artwork and damage")
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	key(KEY_A, true)
	await frames(2)
	check(not scene.knight.visual.flip_h, "reversing movement keeps sword facing its original target")
	key(KEY_A, false)
	await wait_for_damage(scene.session.enemy)
	check(not scene.session.enemy.is_alive(), "resumed sword hits its original forward target")

	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	await frames(12)
	scene.session.hero.stats.damage = 25
	scene.knight.position = Vector2(620, 430)
	scene.sentinel.position = Vector2(655, 430)
	key(KEY_J, true)
	await frames(2)
	key(KEY_J, false)
	await wait_for_damage(scene.session.enemy)
	check(scene.sentinel.visual != null, "sentinel uses generated artwork")
	var impact_position: Vector2 = scene.knight.position
	var impact_progress: float = scene.session.hero.attack_progress()
	check(scene.session.enemy.hp == 75, "normal slash damages once before hit stop")
	key(KEY_D, true)
	key(KEY_L, true)
	await frames(2)
	key(KEY_L, false)
	check(scene.knight.position == impact_position and scene.session.hero.attack_progress() == impact_progress, "hit stop freezes physics and sword together")
	check(scene.session.hero.dash_remaining == 0.0, "hit-stop action is buffered instead of moving the frozen body")
	await frames(4)
	key(KEY_D, false)
	check(scene.session.hero.dash_remaining > 0.0 and scene.knight.position.x > impact_position.x, "dash pressed during hit stop runs after stop ends")

	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	check(not scene.impacts.has_impacts() and scene.camera.offset == Vector2.ZERO, "restart clears sparks and camera displacement")
	await frames(12)
	scene.knight.position = Vector2(620, 430)
	scene.sentinel.position = Vector2(655, 430)
	await frames(3)
	check(scene.sentinel.visual.animation == &"windup" and scene.session.hero.hp == 100, "devourer braces its claws before causing damage")

	scene.set_physics_process(false)
	await physics_frame
	var before_partial_step: float = scene.knight.position.x
	var half_step := 0.5 / Engine.physics_ticks_per_second
	scene.knight.advance_motion(1.0, false, half_step)
	check(absf(scene.knight.position.x - before_partial_step - scene.knight.tuning.move_speed * half_step) < 0.01, "partial time after hit stop moves only its share of a physics tick")

	scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(location)
	print("Scene assertions: %d; failures: %d" % [assertions, failures])
	quit(0 if failures == 0 else 1)

func verify_art_override() -> void:
	var sprite=load("res://scenes/knight_visual.tscn").instantiate()
	var original=load("res://data/knight_animation_frames.tres")
	var atlas_path: String=original.get_frame_texture("idle",0).atlas.resource_path
	var replacement=load("res://art/eightbit/v001/knight-idle.png")
	sprite.texture_overrides={atlas_path:replacement}
	root.add_child(sprite)
	check(sprite.sprite_frames.get_frame_texture("idle",0).atlas==replacement,"art override replaces the atlas actually displayed")
	var timing_preserved:=true
	for clip in [&"idle",&"attack",&"dash"]:
		timing_preserved=timing_preserved and sprite.sprite_frames.get_frame_count(clip)==original.get_frame_count(clip)
		timing_preserved=timing_preserved and sprite.sprite_frames.get_animation_speed(clip)==original.get_animation_speed(clip)
		for index in range(original.get_frame_count(clip)):
			timing_preserved=timing_preserved and sprite.sprite_frames.get_frame_duration(clip,index)==original.get_frame_duration(clip,index)
	check(timing_preserved,"art override preserves editable frame counts, speeds and durations")
	check(sprite.sprite_frames.get_frame_texture("idle",0).region==original.get_frame_texture("idle",0).region,"art override preserves frame crop and alignment")
	check(original.get_frame_texture("idle",0).atlas.resource_path==atlas_path,"art override never mutates the shared original resource")
	sprite.queue_free()
