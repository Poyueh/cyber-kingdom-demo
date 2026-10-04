extends SceneTree
## Native campaign recording, using real input. No user saves are loaded.
var game: Node
var output: String = "/tmp/sword-feedback-render"
var evidence: Dictionary = {}
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run")
func key(code: int, down: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func tick() -> void:
	await physics_frame
	game.paused = false
	game._physics_process(1.0/60)
func capture(clip: String, index: int) -> void:
	var camera: Camera2D = game.knight.get_node("Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("%s-%03d.png" % [clip,index]))
	evidence[clip].append({"step":game.sim.hero.combo_step,"progress":game.sim.hero.attack_progress(),
		"screen":str(game.knight.get_global_transform_with_canvas().origin),"x":game.knight.position.x,
		"trail":game.knight.get_node("SwordTrail").visible,"offset":str(camera.offset)})
func combo(clip: String, advancing: bool, facing: int, hits: bool) -> void:
	game.restart()
	game.knight.position = Vector2(30,430)
	game.sim.interact(30,"hall")
	for unused: int in range(150): await tick()
	if clip == "mounted": game.sim.frontier.drill_level = 3
	game.sim.world.people.clear()
	game.sim.clock.remaining = 10000
	game.knight.position = Vector2(800,430)
	game.sim.hero.facing = facing
	for unused: int in range(5): await tick()
	if hits:
		var enemy: Dictionary = game.sim._spawn_raider()
		enemy.x = 800+facing*45
		enemy.side = facing
		enemy.cooldown = 1000.0
		enemy.fighter.hp = 500
		enemy.fighter.stats.max_hp = 500
		game.sim.raiders.append(enemy)
	if advancing: key(KEY_D if facing==1 else KEY_A,true)
	var buffered: int = 0
	evidence[clip] = []
	for index: int in range(84):
		if index == 0 or (game.sim.hero.combo_step > buffered and game.sim.hero.combo_step < 3 and game.sim.hero.attack_progress() > 0.45):
			if index > 0: buffered = game.sim.hero.combo_step
			key(KEY_J,true)
		await tick()
		key(KEY_J,false)
		await capture(clip,index)
	key(KEY_D,false)
	key(KEY_A,false)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,540)
	game = load("res://scenes/frontier.tscn").instantiate()
	game.tuning = game.tuning.duplicate()
	game.tuning.larger_desktop_window = false
	root.add_child(game)
	game.set_physics_process(false)
	if "--mounted" in OS.get_cmdline_user_args():
		output = "/tmp/sword-mounted-render"
		DirAccess.make_dir_recursive_absolute(output)
		await combo("mounted",false,1,true)
	else:
		await combo("contact",false,1,true)
		await combo("advancing",true,1,true)
		await combo("left",false,-1,true)
		await combo("empty",false,1,false)
	var file: FileAccess = FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t"))
	file.close()
	print("PASS: native sword recordings saved to " + output)
	game.controls.release_all()
	game.queue_free()
	game = null
	for unused: int in range(8): await process_frame
	quit()
