extends RefCounted
## Hunters not posted to a wall hunt by day inside the hunting range beyond the walls,
## and come home before dusk.
const STEP: float=1.0/30.0

func free_forest() -> RefCounted:
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	sim.frontier.city_level=1
	sim.core_loop.income=6;sim.core_loop.stage=3;sim.core_loop.checkpoint_index=2;sim.core_loop.checkpoint_pending=0
	sim.clock.is_night=false;sim.clock.remaining=sim.clock.day_seconds
	return sim

func advance(sim: RefCounted, seconds: float) -> void:
	for i in range(roundi(seconds/STEP)):sim.advance(STEP,sim.world.sites.hall)

func make_hunter(sim: RefCounted) -> int:
	for i in range(sim.world.people.size()):
		if sim.world.people[i].role=="wanderer":
			sim.world.people[i].role="hunter";sim.world.people[i].x=sim.world.sites.hunt_tools
			return i
	return -1

func game_beyond_walls(sim: RefCounted) -> Dictionary:
	for animal: Dictionary in sim.frontier.animals:
		if animal.alive and (animal.x<sim.world.sites.wall_left or animal.x>sim.world.sites.wall):return animal
	return {}

func test_forest_animals_belong_to_the_region_they_stand_in(t):
	var sim: RefCounted=free_forest()
	var wrong: Array=[]
	for animal: Dictionary in sim.frontier.animals:
		var area: Dictionary=sim.frontier.regions[animal.region]
		if animal.x<area.x or animal.x>=area.x+area.width:wrong.append(animal.x)
	t.equal(wrong,[],"every animal is filed under the region it actually stands in")

func test_an_unposted_hunter_hunts_beyond_the_wall_by_day(t):
	var sim: RefCounted=free_forest()
	var index: int=make_hunter(sim)
	var animal: Dictionary=game_beyond_walls(sim)
	t.truth(index>=0 and not animal.is_empty(),"a hunter and game outside the walls")
	if index<0 or animal.is_empty():return
	t.truth(sim.work_area.contains(animal.x),"the game is inside the hunting range")
	sim.core_loop.orders.clean(sim)
	t.truth(sim.core_loop.orders.targets[index].is_empty(),"the hunter has no wall post")
	advance(sim,60.0)
	t.truth(not animal.alive,"the unposted hunter brings the game down")
	# The catch drops crystals; residents may already have picked them up to hand over.
	var on_ground: bool=sim.pouch.drops.any(func(drop: Dictionary)->bool:return absf(drop.x-animal.x)<160)
	var carried: bool=sim.world.people.any(func(p: Dictionary)->bool:return int(p.get("crystals",0))>0)
	t.truth(on_ground or carried,"the catch is worth crystals, on the ground or in a resident's keeping")

func test_unposted_hunters_stay_home_at_night(t):
	var sim: RefCounted=free_forest()
	var index: int=make_hunter(sim)
	if index<0:return
	sim.clock.is_night=true
	advance(sim,15.0)
	t.truth(absf(sim.world.people[index].x-sim.world.sites.hunt_tools)<150,"no one leaves to hunt after dark")
