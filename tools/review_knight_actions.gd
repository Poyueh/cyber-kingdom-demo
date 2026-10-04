extends SceneTree
## Reproducible native visual review. Does not read or write player saves.
## godot --path . --script res://tools/review_knight_actions.gd -- --no-campaign-save
var game: Node
var output: String = "/tmp/knight-v003-render"
var evidence: Dictionary = {}

func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled", false)
	ProjectSettings.set_setting("campaign/control_preview", 1)
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
	game._physics_process(1.0 / 60.0)

func capture(clip: String, index: int) -> void:
	var camera: Camera2D = game.knight.get_node("Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(output.path_join("%s-%03d.png" % [clip, index]))
	var visual: AnimatedSprite2D = game.knight.visual
	var body: Node2D = visual
	for child: Node in visual.get_children():
		if child is Sprite2D and child.visible and child.modulate.a > 0.5:
			body = child
	var texture: Texture2D = body.sprite_frames.get_frame_texture(body.animation, body.frame) if body is AnimatedSprite2D else body.texture
	if not evidence.has(clip): evidence[clip] = []
	evidence[clip].append({"x":game.knight.position.x, "speed":game.knight.velocity.x,
		"atlas":texture.atlas.resource_path if texture is AtlasTexture else "",
		"region":str(texture.region) if texture is AtlasTexture else "",
		"screen":str(visual.get_global_transform_with_canvas().origin),
		"attack_step":game.sim.hero.combo_step, "attack_progress":game.sim.hero.attack_progress()})

func travel(clip: String, sprinting: bool) -> void:
	game.sim.hero.stamina = game.sim.hero.stats.max_stamina
	key(KEY_D, true)
	if sprinting:
		await tick()
		key(KEY_D, false)
		await tick()
		key(KEY_D, true)
	for index: int in range(30):
		await tick()
		await tick()
		await capture(clip, index)
	key(KEY_D, false)
	for unused: int in range(14): await tick()

func combo(clip: String, advancing: bool) -> void:
	game.sim.hero.stamina = game.sim.hero.stats.max_stamina
	if advancing: key(KEY_D, true)
	for index: int in range(48):
		if index in [0,4,12]: key(KEY_J, true)
		await tick()
		key(KEY_J, false)
		await tick()
		await capture(clip, index)
	key(KEY_D, false)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,540)
	game = load("res://scenes/frontier.tscn").instantiate()
	game.tuning = game.tuning.duplicate()
	game.tuning.larger_desktop_window = false
	root.add_child(game)
	for unused: int in range(10): await physics_frame
	game.set_physics_process(false)
	game.knight.position = Vector2(30,430)
	await travel("unarmed-run", false)
	await travel("unarmed-sprint", true)
	game.knight.position = Vector2(30,430)
	game.sim.interact(30,"hall")
	for index: int in range(78):
		await tick()
		await tick()
		await capture("ceremony", index)
	await travel("run", false)
	await travel("sprint", true)
	await combo("planted", false)
	await combo("advancing", true)
	game.sim.hero.stamina = 0
	key(KEY_D, true)
	await tick()
	key(KEY_D, false)
	await tick()
	key(KEY_D, true)
	for index: int in range(90):
		await tick()
		await tick()
		if index % 2 == 0: await capture("fatigue", index / 2)
	key(KEY_D, false)
	var file: FileAccess = FileAccess.open(output.path_join("evidence.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t"))
	file.close()
	print("PASS: native animation capture complete: " + output)
	game.controls.release_all()
	game.queue_free()
	game = null
	for unused: int in range(8): await process_frame
	quit()
