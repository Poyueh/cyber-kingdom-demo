extends RefCounted
## Players found the forest camp too crowded: every structure between the walls gets its own
## room. A tower may stand close to its wall; that pair reads as one fortification.
const MIN_GAP: float=150.0
## Standing at the dragon core offers only the core: it keeps out of every other site's reach.
const INTERACTION_REACH: float=73.0
const Ops=preload("res://application/planet_operations.gd")
const FORTIFICATION_GAP: float=80.0
const HIDDEN_IN_NEW_JOURNEYS: Array[String]=["forge","trade","heal","horn"]
## The beacon site is drawn as its tower; cleared plots share their tree's spot;
## frontier wall plots are not built in the guided forest.
const DRAWN_ELSEWHERE: Array[String]=["beacon"]

func camp(sim: RefCounted) -> Array:
	var left: float=sim.world.sites.wall_left
	var right: float=sim.world.sites.wall
	var items: Array=[]
	for id: String in sim.world.sites:
		if id in HIDDEN_IN_NEW_JOURNEYS or id in DRAWN_ELSEWHERE or id.begins_with("frontier_wall") or id.begins_with("cleared"):continue
		var x: float=sim.world.sites[id]
		if x>=left and x<=right:items.append([x,"wall" if id in ["wall","wall_left"] else id])
	for id: String in sim.buildings:
		var site: Dictionary=sim.buildings[id]
		if site.kind=="tower" and not id.begins_with("cleared") and site.x>=left and site.x<=right:items.append([site.x,"tower"])
	items.append([sim.spirit.shrine_x(sim.world.sites.hall),"shrine"])
	items.append([Ops.rocket_x(sim),"rocket"]) # Stands once the dragon core is claimed.
	for node: RefCounted in sim.frontier.nodes:
		if node.kind=="tree" and node.x>left and node.x<right:items.append([node.x,"tree"])
	items.sort_custom(func(a: Array,b: Array)->bool:return a[0]<b[0])
	return items

func test_forest_camp_gives_every_structure_room(t):
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	var items: Array=camp(sim)
	var crowded: Array[String]=[]
	for i in range(1,items.size()):
		var gap: float=items[i][0]-items[i-1][0]
		var pair: Array=[items[i-1][1],items[i][1]]
		var fortification: bool=pair.has("tower") and pair.has("wall")
		if gap<(FORTIFICATION_GAP if fortification else MIN_GAP):crowded.append("%s@%.0f-%s@%.0f"%[pair[0],items[i-1][0],pair[1],items[i][0]])
	t.equal(crowded,[] as Array[String],"camp structures keep at least %.0f px apart"%MIN_GAP)
	t.truth(sim.world.sites.wall-sim.world.sites.hall>=1000 and sim.world.sites.hall-sim.world.sites.wall_left>=1000,"the walls stand at least 1000 px from the campfire")

func test_the_dragon_core_appears_clear_of_other_interactions(t):
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	var core: float=Ops.core_x(sim)
	var near: Array[String]=[]
	for item: Array in camp(sim):
		if item[1]!="tree" and absf(item[0]-core)<INTERACTION_REACH:near.append("%s@%.0f"%[item[1],item[0]])
	t.equal(near,[] as Array[String],"the dragon core at %.0f is not within reach of another camp site"%core)
	t.truth(core>sim.world.sites.wall_left and core<sim.world.sites.wall,"the dragon core appears inside the walls")

func test_stable_has_its_own_clear_plot(t):
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	var stable: float=sim.mount_quest.stable_x
	for item: Array in camp(sim):
		t.truth(absf(item[0]-stable)>=180,"stable clears %s by at least 180 px"%item[1])
