extends "res://tests/test_scene.gd"
## Real campaign input/physics regression: hit stop must not eat combo input.
var game: Node
const STEP: float = 1.0 / 60.0

func tick() -> void:
	await physics_frame
	game._physics_process(STEP)

func reset_fight() -> void:
	game.restart()
	game.sim.world.people.clear()
	game.sim.clock.remaining = 10000.0
	game.knight.position = Vector2(800,430)
	for unused: int in range(4): await tick()

func target_at(distance: float) -> Dictionary:
	var enemy: Dictionary = game.sim._spawn_raider()
	enemy.x = game.knight.position.x + distance
	enemy.side = 1
	enemy.cooldown = 1000.0
	enemy.fighter.hp = 500
	enemy.fighter.stats.max_hp = 500
	game.sim.raiders.append(enemy)
	return enemy

func swing_until_hit(enemy: Dictionary) -> void:
	var health: int = enemy.fighter.hp
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	for unused: int in range(30):
		if enemy.fighter.hp < health: return
		await tick()
	check(false,"nearby enemy receives the sword hit")

func run_scene() -> void:
	game = load("res://scenes/frontier.tscn").instantiate()
	game.tuning = game.tuning.duplicate()
	game.tuning.immersive_loop = false
	root.add_child(game)
	game.set_physics_process(false)
	await reset_fight()
	var enemy: Dictionary = target_at(42)
	var start: Vector2 = game.knight.position
	await swing_until_hit(enemy)
	var health: int = enemy.fighter.hp
	var progress: float = game.sim.hero.attack_progress()
	var clock: float = game.sim.workforce.elapsed
	check(game.knight.position == start,"standing slash stays planted")
	check(game.knight.get_node("Camera2D").offset.length() > 0,"confirmed sword hit gives camera impact")
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	check(game.sim.hero.attack_progress() == progress and game.sim.workforce.elapsed == clock,"confirmed hit briefly holds sword and world together")
	check(enemy.fighter.hp == health,"frozen hit cannot deal repeated damage")
	var reached_second: bool = false
	for unused: int in range(28):
		await tick()
		if game.sim.hero.combo_step == 2 and game.sim.hero.attack_remaining > 0:
			reached_second = true
			break
	check(reached_second,"attack pressed during contact stop buffers the second slash")
	await reset_fight()
	check(game.knight.get_node("Camera2D").offset == Vector2.ZERO,"restart clears contact camera offset")
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	var empty_swing_continues: bool = true
	for unused: int in range(22):
		clock = game.sim.workforce.elapsed
		await tick()
		empty_swing_continues = empty_swing_continues and game.sim.workforce.elapsed > clock
	check(empty_swing_continues,"an empty swing does not stop the simulation")
	check(game.knight.get_node("Camera2D").offset == Vector2.ZERO,"empty swing does not fake a contact shake")
	await reset_fight()
	enemy = target_at(42)
	enemy.fighter.invulnerability_remaining = 5.0
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	for unused: int in range(22): await tick()
	check(enemy.fighter.hp == 500 and game.knight.get_node("Camera2D").offset == Vector2.ZERO,"rejected damage does not produce false contact feedback")
	await reset_fight()
	enemy = target_at(42)
	await swing_until_hit(enemy)
	game.paused = true
	progress = game.sim.hero.attack_progress()
	var offset: Vector2 = game.knight.get_node("Camera2D").offset
	for unused: int in range(12): await tick()
	check(game.sim.hero.attack_progress() == progress and game.knight.get_node("Camera2D").offset == offset,"menu pause holds both combat and contact effect")
	game.paused = false
	await tick()
	check(game.sim.hero.attack_progress() == progress,"menu pause does not consume remaining contact stop")
	for unused: int in range(50): await tick()
	check(game.knight.get_node("Camera2D").offset == Vector2.ZERO,"camera returns exactly to rest after contact")
	await reset_fight()
	enemy = target_at(42)
	await swing_until_hit(enemy)
	var light_hold: int = await held_ticks()
	await reset_fight()
	enemy = target_at(42)
	var second_enemy: Dictionary = target_at(50)
	await swing_until_hit(enemy)
	check(second_enemy.fighter.hp < 500,"one sword can hit two enemies")
	check(await held_ticks() == light_hold,"a group hit never multiplies the contact stop")
	await reset_fight()
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	var buffered: int = 0
	for unused: int in range(60):
		if game.sim.hero.combo_step > buffered and game.sim.hero.combo_step < 3 and game.sim.hero.attack_progress() > 0.45:
			buffered = game.sim.hero.combo_step
			key(KEY_J,true)
		await tick()
		key(KEY_J,false)
		if game.sim.hero.combo_step == 3: break
	enemy = target_at(42)
	for unused: int in range(25):
		await tick()
		if enemy.fighter.hp < 500: break
	check(enemy.fighter.hp < 500,"buffered third cut connects in the real campaign")
	check(await held_ticks() > light_hold,"heavy finisher has a longer contact hold than the light cut")
	await reset_fight()
	game.sim.effects.append({"kind":"hit","x":842.0,"to":842.0,"life":0.25})
	clock = game.sim.workforce.elapsed
	await tick()
	await tick()
	check(game.sim.workforce.elapsed > clock and game.knight.get_node("Camera2D").offset == Vector2.ZERO,"archer impact does not freeze the knight")
	await reset_fight()
	enemy = target_at(42)
	await swing_until_hit(enemy)
	key(KEY_J,true)
	await tick()
	key(KEY_J,false)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.paused = false
	for unused: int in range(45): await tick()
	check(game.sim.hero.combo_step == 0,"focus loss discards buffered follow-up attacks")
	game.controls.release_all()
	game.queue_free()
	game = null
	for unused: int in range(8): await process_frame
	print("Sword feedback scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures == 0 else 1)

func held_ticks() -> int:
	var held: int = 0
	var before: float = game.sim.workforce.elapsed
	for unused: int in range(12):
		await tick()
		if game.sim.workforce.elapsed > before: break
		held += 1
	return held
