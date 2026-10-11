extends "res://tests/test_star_voyage_scene.gd"
func touch(index: int, at: Vector2, down: bool) -> void:
	var event: InputEventScreenTouch=InputEventScreenTouch.new();event.index=index;event.position=at;event.pressed=down
	root.push_input(event,true);Input.flush_buffered_events()
func capture(game: Node, name: String) -> void:
	game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
	game.view.present(game.sim,game.knight.position.x);game._water.present(game.sim);game._sunbeams.present(game.sim)
	await frames(4)
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/dragon-opening")
	game.get_viewport().get_texture().get_image().save_png("res://test-results/dragon-opening/"+name+".png")
func verify_counterattack(game: Node, dragon: Dictionary, planet: int) -> void:
	var cooldown: float=dragon.cooldown;game.paused=true
	for i: int in range(10):game._physics_process(0.25)
	check(dragon.cooldown==cooldown and game.sim.planet.attack.opening.exposed(dragon),"pause preserves the actual damage opportunity")
	game.paused=false;game.sim.hero.facing=1;game.sim.hero.stamina=100
	# Match resume: show the touch button before injecting its press.
	game._physics_process(1.0/30)
	var hp: int=dragon.fighter.hp;var damage: int=roundi(game.sim.hero.stats.damage*1.5)
	var button: TouchScreenButton=game.hud.get_node("attack")
	var at: Vector2=button.position+button.texture_normal.get_size()*0.5
	if planet%2:
		touch(19,at,true)
		check(button.is_pressed() and Input.is_action_pressed("attack"),"visible touch control receives the real finger press")
	else:key(KEY_J,true)
	game.set_physics_process(true);await frames(3);game.set_physics_process(false)
	if planet%2:touch(19,at,false)
	else:key(KEY_J,false)
	for i: int in range(30):
		game._physics_process(1.0/30)
		if dragon.fighter.hp<hp:break
	check(hp-dragon.fighter.hp==damage,"keyboard or touch sword applies one exposed-core bonus")
func run_scene() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path="";game._map_seed=416;game._seed_initialized=true
	root.add_child(game);await frames(10);game.set_physics_process(false)
	for planet: int in [0,1,3,2,4,5,6]:
		if planet>0:
			clear_world(game);game.sim.planet.launch_requested=true;game._star_travel.observe()
			await click(game._star_travel.map._buttons[planet]);await click(game._star_travel.map._launch);await frames(3)
			game._arrival_banner.hide()
		check(game.journey.current==planet,"real star voyage reaches counterattack world "+str(planet))
		game.sim.world.people.clear();game.sim.survival.armed=true;game.sim.frontier.city_level=1
		game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0;game.sim.pouch.amount=30
		game.sim.clock.remaining=game.sim.clock.day_seconds*0.65
		game.knight.position=Vector2(2500,430)
		for region: Dictionary in game.sim.frontier.regions:region.discovered=true
		for gate: Dictionary in game.sim.mission.rifts:gate.sealed=true
		game._physics_process(1.0/30)
		var dragon: Dictionary=game.sim.raiders.filter(func(e: Dictionary)->bool:return e.get("kind","")=="dragon")[0]
		dragon.x=2680.0;dragon.direction=1.0;dragon.windup=0.5;dragon.cooldown=0.0;dragon.target={"kind":"hero","x":2900.0}
		game.hud.control_mode=1 if planet%2 else 2
		TranslationServer.set_locale("zh_TW")
		check(not game.sim.planet.attack.opening.exposed(dragon),"warning is not presented as a safe counterattack")
		if planet==0:await capture(game,"forest-warning")
		for i: int in range(300):
			game._physics_process(1.0/30)
			if game.sim.planet.attack.opening.exposed(dragon):break
		check(game.sim.planet.attack.opening.exposed(dragon),"completing actual volley exposes the core")
		game.knight.position=Vector2(dragon.x-90,430);game.knight.velocity=Vector2.ZERO
		await capture(game,"world-"+str(planet))
		if planet in [0,6]:
			for locale: String in ["zh_CN","en"]:
				TranslationServer.set_locale(locale);await capture(game,"world-%d-%s"%[planet,locale])
				check(not game.tr("dragon.opening").begins_with("dragon."),"opening instruction translates in "+locale)
			TranslationServer.set_locale("zh_TW")
		await verify_counterattack(game,dragon,planet)
		if planet==0:
			dragon.direction=-1.0;await capture(game,"forest-facing-left")
		clear_world(game);game.journey.observe(game.sim)
	game.queue_free();await frames(3)
	print("Dragon opening scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
