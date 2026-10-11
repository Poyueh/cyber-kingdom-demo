extends RefCounted
## Dawn renewal preserves resident IDs, finite minerals and undelivered cargo.
var frontier
var last_dawn := 1
var population_limit: int
var waiting_limit: int
func _init(map, config: Dictionary={}) -> void:
	frontier=map
	population_limit=clampi(int(config.get("population_limit",24)),8,40)
	waiting_limit=clampi(int(config.get("camp_waiting_limit",2)),1,4)
func camp_x(index: int) -> float:
	var region: Dictionary=frontier.regions[index]
	return region.x+region.width*0.12
func habitat(index: int) -> bool:
	if not preload("res://domain/planet_level_layout.gd").is_supply(frontier.regions[index]):return false
	if frontier.regions[index].kind!="forest":return true
	return frontier.nodes.any(func(n):return n.region==index and n.kind=="tree" and not n.collected)
func waiting(index: int, people: Array) -> int:
	var count:=0
	for person in people:
		if person.role=="wanderer" and person.get("region",-1)==index and absf(person.x-camp_x(index))<160:count+=1
	return count
func clearing_last_tree(node) -> bool:
	if node.kind!="tree" or node.collected or node.marked:return false
	return not frontier.nodes.any(func(n):return n!=node and n.region==node.region and n.kind=="tree" and not n.collected and not n.marked)
func arrival_x(index: int, people: Array) -> float:
	var center:=camp_x(index)
	for offset in [-36.0,0.0,36.0,72.0]:
		var point: float=center+offset
		if not people.any(func(p):return absf(p.x-point)<20):return point
	return center+108

func renew(day: int, people: Array) -> Array[Dictionary]:
	var arrivals: Array[Dictionary]=[]
	if day<=last_dawn:return arrivals
	last_dawn=day
	for index in range(frontier.regions.size()):
		if not habitat(index):continue
		if people.size()+arrivals.size()<population_limit and waiting(index,people)<waiting_limit:
			arrivals.append({"x":arrival_x(index,people),"region":index})
	for animal in frontier.animals:
		if animal.alive or not habitat(animal.region):continue
		animal["home_x"]=animal.get("home_x",animal.x)
		animal.x=animal.home_x+float((day*17+animal.region*11)%31)-15
		animal.alive=true
	for node in frontier.nodes:
		if node.kind not in ["berries","herbs"] or not node.delivered or node.carried:continue
		node.collected=false
		node.delivered=false
		node.marked=false
		node.worker=-1
		node.remaining_work=75
		node.work_elapsed=0.0
		node.pickup_x=node.x
		node.pickup_y=node.y
	return arrivals
