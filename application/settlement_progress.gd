extends RefCounted
## Read-only settlement milestones for the map and completion presentation.
static func read(sim: RefCounted) -> Dictionary:
	if not sim.life.enabled:
		return {"level":0,"stages":[]}
	var level: int = sim.frontier.city_level
	var stages: Array[Dictionary] = []
	for rank: int in range(1, 4):
		var unlocks: Array[String] = []
		match rank:
			1: unlocks.assign(["workshop", "hunt_tools"])
			2: unlocks.assign(["farm_tools"])
			3: unlocks.assign(["armory"])
		var locations: Array[float] = []
		for site: String in unlocks:
			locations.append(float(sim.world.sites[site]))
		stages.append({
			"level":rank, "complete":level >= rank,
			"title":"settlement.stage.%d" % rank,
			"detail":"settlement.unlock.%d" % rank,
			"icon":["camp", "hoe", "sword"][rank - 1],
			"unlocks":unlocks, "locations":locations
		})
	return {"level":level, "stages":stages}
