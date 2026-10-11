extends SceneTree
func _initialize() -> void:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.seed=103;config.economy=tuning.economy_rules();config.night_seconds=10000.0
	var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
	sim.clock.day=5;sim.clock.survived=4;sim.clock.remaining=0.01
	sim.world.people.clear()
	for tick: int in range(130):sim.advance(0.1,30.0)
	var packet: Dictionary=load("res://application/campaign_snapshot.gd").new().capture(sim,config,{"x":30.0,"y":430.0,"vx":0.0,"vy":0.0})
	assert(packet.version==18)
	var file: FileAccess=FileAccess.open("/tmp/cyber-v26-night-checkpoint.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(packet));file.close()
	print("Created actual v0.0.26 night checkpoint; remaining: ",sim._spawn_remaining)
	quit()
