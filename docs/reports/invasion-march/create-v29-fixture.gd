extends SceneTree
func _initialize() -> void:
	var tuning: Resource=load("res://data/campaign.tres")
	var config: Dictionary=tuning.campaign_rules()
	config.merge({"seed":103,"economy":tuning.economy_rules()},true)
	config.merge(load("res://data/planets/forest.tres").rules(),true)
	assert(not config.has("march_version"))
	var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
	sim.frontier.city_level=1;sim.survival.armed=true;sim.world.people.clear()
	sim.clock.remaining=0.01
	for tick: int in range(30):sim.advance(1.0/30.0,30.0)
	var enemy: Dictionary=sim._spawn_raider()
	enemy.x=5000.0;enemy.side=1;enemy.carried_crystals=1;enemy.retreat_x=sim.mission.entry_x(1);enemy.module_chill_until=120
	sim.raiders.append(enemy)
	var body: Dictionary={"x":30.0,"y":430.0,"vx":0.0,"vy":0.0}
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var saved: Dictionary=codec.capture(sim,config,body)
	assert(not codec.restore(JSON.parse_string(JSON.stringify(saved))).is_empty())
	FileAccess.open("/tmp/cyber-v29-march-save.json",FileAccess.WRITE).store_string(JSON.stringify(saved))
	for tick: int in range(60):sim.advance(1.0/30.0,30.0)
	FileAccess.open("/tmp/cyber-v29-march-continued.json",FileAccess.WRITE).store_string(JSON.stringify(codec.capture(sim,config,body)))
	print("PASS: released v0.0.29 created a real night-invasion save and its sixty-tick continuation.")
	quit()
