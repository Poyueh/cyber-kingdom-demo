extends RefCounted
## Assign paid expeditions without discarding carried harvests or storing a session.
var world
var frontier
var mission
func _init(settlement, map, objective) -> void:
	world=settlement
	frontier=map
	mission=objective
func prepare(unavailable: Array[int]=[]) -> void:
	var assigned: Array[int]=[]
	for rift in mission.rifts:
		if rift.sealed:rift.worker=-1
		if rift.worker>=0 and world.people[rift.worker].role!="engineer":rift.worker=-1
		if rift.worker>=0:assigned.append(rift.worker)
	for rift in mission.rifts:
		if not rift.ordered or rift.sealed or rift.worker>=0:continue
		var nearest:=INF
		for i in range(world.people.size()):
			var person: Dictionary=world.people[i]
			if person.role!="engineer" or i in assigned or i in unavailable:continue
			if frontier.nodes.any(func(n):return n.worker==i and n.carried):continue
			if absf(person.x-rift.x)<nearest:
				nearest=absf(person.x-rift.x)
				rift.worker=i
		if rift.worker>=0:
			assigned.append(rift.worker)
			for node in frontier.nodes:
				if node.worker==rift.worker:node.worker=-1
func target(index: int, seconds: float) -> float:
	for rift in mission.rifts:
		if not rift.ordered or rift.sealed or rift.worker!=index:continue
		var person: Dictionary=world.people[index]
		if absf(person.get("y",430.0)-430.0)>0.1:
			person["y"]=move_toward(person.get("y",430.0),430.0,70.0*seconds)
			person["work_state"]="climb"
			return person.x
		var at: float=rift.x-rift.side*28.0
		person["work_state"]="work" if absf(person.x-at)<8 else "walk"
		person["direction"]=float(rift.side)
		return at
	return NAN
func worker_ready(rift: Dictionary) -> bool:
	return rift.worker>=0 and world.people[rift.worker].role=="engineer" and absf(world.people[rift.worker].x-rift.x)<40 and absf(world.people[rift.worker].get("y",430.0)-430.0)<1
