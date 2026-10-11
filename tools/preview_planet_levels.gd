extends SceneTree
## Native renderer tour of actual generated rooms; no player saves or world mutation.
var game: Node
var output: String="/tmp/cyber-level-preview"
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run")
func capture(name: String, x: float) -> void:
	game.knight.position=Vector2(x,430);game.knight.velocity=Vector2.ZERO
	game.view.present(game.sim,x);game.sim.workforce.elapsed+=2
	game.view.present(game.sim,x);game._water.present(game.sim);game._sunbeams.present(game.sim)
	game.knight.refresh_visual(0.0)
	var camera: Camera2D=game.knight.get_node("Camera2D")
	camera.reset_smoothing();camera.force_update_scroll()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game)
	for index: int in range(8):await physics_frame
	game.set_physics_process(false);game.knight.set_physics_process(false)
	game.hud.hide();game.paused=false
	for planet: int in range(7):
		var sim: RefCounted=load("res://application/campaign_session.gd").new(game.journey.configs[planet])
		game.sim=sim;game.knight.configure(sim.hero,game.knight_tuning)
		sim.survival.armed=true;sim.spirit.opening_finished=true;sim.spirit.expires_tick=0
		sim.clock.remaining=sim.clock.day_seconds*0.65
		for region: Dictionary in sim.frontier.regions:region.discovered=true
		game._build_terrain();game._sync_knight_equipment()
		for role: int in [0,1,2,4]:
			for region: Dictionary in sim.frontier.regions:
				if region.level_role!=role:continue
				await capture("world-%d-role-%d"%[planet,role],region.x+region.width*0.5)
				break
	game.queue_free();await process_frame;quit()
