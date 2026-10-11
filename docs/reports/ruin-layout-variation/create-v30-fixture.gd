extends SceneTree
func _initialize() -> void:
	var tuning: Resource=load("res://data/campaign.tres")
	var base: Dictionary=tuning.campaign_rules();base.seed=813;base.economy=tuning.economy_rules()
	var profiles: Array[Dictionary]=[]
	for name: String in ["forest","desert","frost","swamp","volcanic","storm","void"]:profiles.append(load("res://data/planets/"+name+".tres").rules())
	var trip: RefCounted=load("res://application/star_voyage.gd").new(base,profiles)
	var codec: RefCounted=load("res://application/campaign_snapshot.gd").new()
	var before: Array[Dictionary]=[];var after: Array[Dictionary]=[]
	for planet: int in range(1,7):
		var config: Dictionary=trip.configs[planet]
		var sim: RefCounted=load("res://application/campaign_session.gd").new(config)
		for region: Dictionary in sim.frontier.regions:region.discovered=true
		var site: RefCounted=sim.trials.sites[0];var m: RefCounted=site.mechanism
		var chosen: int=0
		while sim.context(site.positions[chosen]).id!="trial":chosen+=1
		if m.kind==3:sim.workforce.elapsed=float(posmod(int(m.window/2)-m.offsets[chosen],m.period))/30
		assert(sim.interact(site.positions[chosen]))
		var body: Dictionary={"x":site.positions[chosen],"y":430.0,"vx":0.0,"vy":0.0}
		before.append(codec.capture(sim,config,body))
		for tick: int in range(60):sim.advance(1.0/30,body.x)
		after.append(codec.capture(sim,config,body))
	FileAccess.open("/tmp/cyber-v30-ruin-before.json",FileAccess.WRITE).store_string(JSON.stringify(before))
	FileAccess.open("/tmp/cyber-v30-ruin-after.json",FileAccess.WRITE).store_string(JSON.stringify(after))
	print("Actual v0.0.30 PCK: six partial mechanism saves and sixty-tick continuations generated.")
	quit()
