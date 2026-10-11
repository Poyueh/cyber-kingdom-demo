extends SceneTree
func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	call_deferred("run")
func run() -> void:
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);await physics_frame;game.set_physics_process(false)
	var journey: RefCounted=game.journey;var sim: RefCounted=game.sim
	for gate: Dictionary in sim.mission.rifts:gate.sealed=true
	sim.raiders.clear();sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.frontier.city_level=3;sim.survival.armed=true;sim.advance(0.1,30)
	for region: Dictionary in sim.frontier.regions:region.discovered=true
	for site: RefCounted in sim.trials.sites:sim.trials.unlock(site.id)
	sim.mount_quest.rotations.assign([1,2]);sim.mount_quest.recover()
	var body: Dictionary={"x":-730.0,"y":430.0,"vx":0.0,"vy":0.0}
	var before: Array[Dictionary]=[journey.capture(sim,body)]
	var after: Array[Dictionary]=[]
	for tick: int in range(60):sim.advance(1.0/30,body.x)
	after.append(journey.capture(sim,body))
	sim.interact(-185,"dragon_core");sim.planet.rocket_ready=true
	var moved: Dictionary=journey.prepare(sim,body,1)
	assert(not moved.is_empty())
	journey=moved.journey;sim=moved.session;body=moved.body
	before.append(journey.capture(sim,body))
	for tick: int in range(60):sim.advance(1.0/30,body.x)
	after.append(journey.capture(sim,body))
	FileAccess.open("/tmp/cyber-v32-voyage-before.json",FileAccess.WRITE).store_string(JSON.stringify(before))
	FileAccess.open("/tmp/cyber-v32-voyage-after.json",FileAccess.WRITE).store_string(JSON.stringify(after))
	game.queue_free();await process_frame
	print("Actual v0.0.32 PCK: two multiworld checkpoints and sixty-tick continuations generated.");quit()
