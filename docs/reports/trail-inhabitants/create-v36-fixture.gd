extends SceneTree
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	call_deferred("run")
func run() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await physics_frame;game.set_physics_process(false)
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var before: Array[Dictionary]=[];var after: Array[Dictionary]=[]
	for id: int in range(7):
		var config: Dictionary=game.journey.configs[id]
		var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
		for region: Dictionary in sim.frontier.regions:region.discovered=true
		sim.survival.armed=true
		var site: RefCounted=sim.trials.sites[0]
		var body: Dictionary={"x":site.positions[0],"y":430.0,"vx":0.0,"vy":0.0}
		sim.interact(body.x)
		before.append(codec.capture(sim,config,body))
		var loaded: Dictionary=codec.restore(JSON.parse_string(JSON.stringify(before[-1])))
		assert(not loaded.is_empty())
		for tick: int in range(60):loaded.session.advance(1.0/30,body.x)
		after.append(codec.capture(loaded.session,loaded.config,body))
	FileAccess.open("/tmp/cyber-v36-level-before.json",FileAccess.WRITE).store_string(JSON.stringify(before))
	FileAccess.open("/tmp/cyber-v36-level-after.json",FileAccess.WRITE).store_string(JSON.stringify(after))
	game.queue_free();await process_frame
	print("Actual v0.0.36 PCK: seven explored worlds with partial puzzles saved and continued for sixty ticks.");quit()
