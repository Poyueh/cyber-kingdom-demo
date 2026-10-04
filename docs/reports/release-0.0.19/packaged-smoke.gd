extends SceneTree
var game: Node
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run")
func key(down: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_J
	event.keycode = KEY_J
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func tick() -> void:
	await physics_frame
	game.paused = false
	game._physics_process(1.0/60)
func run() -> void:
	root.size=Vector2i(960,540)
	game=load("res://scenes/frontier.tscn").instantiate()
	game.tuning=game.tuning.duplicate()
	game.tuning.larger_desktop_window=false
	root.add_child(game)
	game.set_physics_process(false)
	game.knight.position=Vector2(30,430)
	game.sim.interact(30,"hall")
	for unused: int in range(155): await tick()
	game.sim.world.people.clear()
	game.knight.position=Vector2(800,430)
	var enemy: Dictionary=game.sim._spawn_raider()
	enemy.x=845.0
	enemy.side=1
	enemy.cooldown=1000.0
	game.sim.raiders.append(enemy)
	var hp: int=enemy.fighter.hp
	key(true)
	await tick()
	key(false)
	for unused: int in range(25):
		await tick()
		if enemy.fighter.hp<hp: break
	assert(enemy.fighter.hp<hp)
	assert(game.knight.get_node("SwordTrail").visible)
	var atlas: AtlasTexture=game.knight.visual._combo_attack.texture
	assert(atlas.atlas.resource_path=="res://art/characters/blacksteel-combo-v004/planted.png")
	assert(game.knight.visual.appearance.resource_path=="res://data/blacksteel_v004_appearance.tres")
	assert(game.knight.get_node("Camera2D").offset.length()>0)
	var pose: float=game.sim.hero.attack_progress()
	key(true)
	await tick()
	key(false)
	assert(game.sim.hero.attack_progress()==pose)
	assert(game.knight.position.x==800.0)
	var camera: Camera2D=game.knight.get_node("Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/body-combo-packaged.png")
	for unused: int in range(30):
		await tick()
		if game.sim.hero.combo_step==2: break
	assert(game.sim.hero.combo_step==2)
	print("PASS: exported PCK uses v004 whole-body atlas, blade trail, contact camera, rooted hit stop and buffered next cut")
	game.controls.release_all()
	game.queue_free()
	game=null
	for unused: int in range(8): await process_frame
	quit()
