extends RefCounted
## UI-only projection of validated worlds. No reconstruction, rewards or persistence.
static func read(journey: RefCounted, sim: RefCounted, id: int) -> Dictionary:
	if id<0 or id>=journey.planets.size():return {"known":false}
	var regions: Array[Dictionary]=[]
	var level: int=0;var solved: int=0;var total: int=0
	if id==journey.current:
		regions.assign(sim.frontier.regions);level=sim.frontier.city_level
		for site: RefCounted in sim.trials.sites:
			total+=1
			if site.progress==3:solved+=1
		if sim.mount_quest.enabled:
			total+=1
			if sim.mount_quest.recovered:solved+=1
	else:
		var world: Dictionary=journey.planets[id]
		if world.is_empty():return {"known":false}
		var saved: Dictionary=world.campaign
		regions.assign(saved.frontier.regions);level=saved.frontier.city_level
		for site: Dictionary in saved.trials:
			total+=1
			if site.progress==3:solved+=1
		if id==0 and journey.configs[id].get("mount_enabled",0)==1:
			total+=1
			if saved.mount.recovered:solved+=1
	var explored: int=0
	for region: Dictionary in regions:
		if region.discovered:explored+=1
	var goals: Array[Dictionary]=[_goal("survey","map",explored,regions.size()),_goal("ruins","gear",solved,total),_goal("settlement","camp",level,3)]
	return {"known":true,"core":journey.has_core(id,sim),"settlement":level,"goals":goals}
static func _goal(id: String, icon: String, count: int, total: int) -> Dictionary:
	return {"id":id,"icon":icon,"count":count,"total":total,"complete":total>0 and count>=total}
static func newly_opened(journey: RefCounted, sim: RefCounted, claimed: int) -> Array[int]:
	var result: Array[int]=[]
	if claimed<0 or claimed>=journey.planets.size() or not journey.has_core(claimed,sim):return result
	for id: int in range(journey.planets.size()):
		if id==journey.current or not journey.planets[id].is_empty():continue
		if journey.core_count(sim)==1 and journey.accessible(id,sim):result.append(id)
	return result
