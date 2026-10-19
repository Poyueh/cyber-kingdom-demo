extends RefCounted
## The module workshop means nothing before the first module, so it only appears once
## the knight has found one.
func free_forest() -> RefCounted:
	var sim: RefCounted=load("res://tests/test_resident_revert.gd").new().guided()
	sim.frontier.city_level=1
	sim.core_loop.income=6;sim.core_loop.stage=3;sim.core_loop.checkpoint_index=2;sim.core_loop.checkpoint_pending=0
	return sim

func test_module_workshop_waits_for_the_first_module(t):
	var sim: RefCounted=free_forest()
	var station: float=sim.world.sites.drill
	t.truth(not sim.site_visible("drill"),"no workshop stands in camp before any module is found")
	t.truth(sim.context_for_key(station,"drill").get("id","")!="module_station","walking past offers no empty workshop")
	t.truth(not sim.modules.relics.is_empty(),"the forest hides modules to find")
	if sim.modules.relics.is_empty():return
	sim.modules.found.append(str(sim.modules.relics[0].id))
	t.truth(sim.site_visible("drill"),"the workshop appears once a module is found")
	t.truth(sim.can_use_module_station(station),"and it can be used right away")
