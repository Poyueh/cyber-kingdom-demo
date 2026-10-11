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
		for recovery: bool in [false,true]:
			var config: Dictionary=game.journey.configs[id]
			var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
			sim.world.people.clear();sim.survival.armed=true
			for gate: Dictionary in sim.mission.rifts:gate.sealed=true
			sim._summon_dragon(2000)
			var dragon: Dictionary=sim.raiders[0]
			dragon.x=2500.0;dragon.direction=1.0;dragon.windup=0.1;dragon.cooldown=0.0;dragon.target={"kind":"hero","x":2700.0}
			if recovery:
				for beat: int in range(1 if id==0 else sim.planet.attack.beats):
					if id==0:load("res://application/dragon_assault.gd").advance(sim,dragon,dragon.windup+0.01,4500,430)
					else:load("res://application/biome_dragon_assault.gd").advance(sim,dragon,dragon.windup+0.01,4500,430)
			var body: Dictionary={"x":4500.0,"y":430.0,"vx":0.0,"vy":0.0}
			before.append(codec.capture(sim,config,body))
			for tick: int in range(60):sim.advance(1.0/30,body.x)
			after.append(codec.capture(sim,config,body))
	FileAccess.open("/tmp/cyber-v31-dragons-before.json",FileAccess.WRITE).store_string(JSON.stringify(before))
	FileAccess.open("/tmp/cyber-v31-dragons-after.json",FileAccess.WRITE).store_string(JSON.stringify(after))
	game.queue_free();await process_frame
	print("Actual v0.0.31 PCK: fourteen mid-fight saves and sixty-tick continuations generated.");quit()
