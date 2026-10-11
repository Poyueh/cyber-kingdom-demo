extends SceneTree
## Actual campaign renderer, deterministic presentation tour. Never reads player saves.
const Campaign = preload("res://application/campaign_session.gd")
var game: Node
var output: String="res://test-results/devourers"
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run")
func show_frame(name: String) -> void:
	game.view.present(game.sim,game.knight.position.x)
	game._water.present(game.sim);game._sunbeams.present(game.sim)
	game.knight.refresh_visual(0.0)
	var camera: Camera2D=game.knight.get_node("Camera2D")
	camera.reset_smoothing();camera.force_update_scroll()
	await process_frame;await RenderingServer.frame_post_draw
	if not name.is_empty():root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game)
	for index: int in range(8):await physics_frame
	game.set_physics_process(false);game.knight.set_physics_process(false)
	game.hud.hide();game.paused=false
	for planet: int in range(7):
		var config: Dictionary=game.journey.configs[planet].duplicate(true)
		var sim: RefCounted=Campaign.new(config)
		game.sim=sim;game.knight.configure(sim.hero,game.knight_tuning)
		game.knight.position=Vector2(2500,430);game.knight.velocity=Vector2.ZERO
		sim.survival.armed=true;sim.spirit.opening_finished=true;sim.spirit.expires_tick=0
		sim.world.people.clear();sim.clock.remaining=sim.clock.day_seconds*0.30
		for region: Dictionary in sim.frontier.regions:region.discovered=true
		game._build_terrain();game._sync_knight_equipment()
		var grunt: Dictionary=sim._spawn_raider();grunt.x=2570.0;grunt.direction=-1.0
		var elite: Dictionary=sim._spawn_raider();elite.x=2695.0;elite.direction=-1.0;elite.kind="warden"
		sim.raiders.assign([grunt,elite]);sim.workforce.elapsed=40
		game.view.present(sim,2500);sim.workforce.elapsed+=2
		await show_frame("world-%d-enemies"%planet)
		grunt.fighter.take_damage(18);elite.fighter.take_damage(18)
		sim.effects.append({"kind":"hit","x":grunt.x,"life":0.28,"heavy":true,"facing":1})
		sim.workforce.elapsed+=0.04
		await show_frame("world-%d-hit"%planet)
		for tick: int in range(20):
			sim.workforce.elapsed+=1.0/24;grunt.x-=0.6;elite.x-=0.5
			await show_frame("")
		grunt.carried_crystals=1;grunt.direction=1
		await show_frame("world-%d-carry"%planet)
		sim.raiders.clear()
		var boss: Dictionary=sim._spawn_raider();boss.kind="dragon";boss.x=2710.0;boss.direction=-1.0
		boss.target={"kind":"hero","x":2500.0};boss.windup=2.0;boss.cooldown=5.0
		sim.raiders.append(boss);game.view.present(sim,2500)
		for tick: int in range(72):
			sim.workforce.elapsed+=1.0/24
			boss.windup=maxf(0,2.0-(tick+1)/24.0)
			if tick==47:sim.effects.append({"kind":"dragon_fire" if planet==0 else "planet_strike","x":boss.x if planet==0 else 2500.0,"to":2500.0,"life":0.7 if planet==0 else 0.85})
			for effect: Dictionary in sim.effects:effect.life-=1.0/24
			sim.effects=sim.effects.filter(func(e: Dictionary)->bool:return e.life>0)
			await show_frame("world-%d-charge"%planet if tick==38 else "world-%d-release"%planet if tick==50 else "")
		boss.fighter.take_damage(99999);sim.workforce.elapsed+=0.03;game.view.present(sim,2500)
		for tick: int in range(24):
			sim.workforce.elapsed+=1.0/24
			await show_frame("world-%d-fallen"%planet if tick==12 else "")
	game.queue_free();await process_frame;quit()
