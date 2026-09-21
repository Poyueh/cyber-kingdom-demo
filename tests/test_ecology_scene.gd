extends "res://tests/test_scene.gd"
func dawn(scene) -> void:
	scene.sim.clock.is_night=true
	scene.sim.clock.remaining=0.01
	scene._physics_process(0.02)
func run_scene() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false
	# Keep this renewal/recruitment fixture below the population ceiling.
	scene.tuning=scene.tuning.duplicate()
	scene.tuning.outer_regions_per_side=0
	root.add_child(scene)
	await frames(8)
	scene.set_physics_process(false)
	scene.paused=false
	var sim=scene.sim
	dawn(scene)
	check(sim.clock.day==2 and sim.world.people.size()==14,"real scene dawn replenishes six camps")
	var newcomer: Dictionary=sim.world.people.back()
	scene.knight.position=Vector2(newcomer.x,430)
	await frames(2)
	scene._physics_process(1.0/60)
	check(scene.view._context.id=="recruit","new arrival is selected by actual proximity UI")
	scene.hud.interact_button.button_down.emit()
	scene._physics_process(1.0/60)
	scene.hud.interact_button.button_up.emit()
	scene._physics_process(1.0/60)
	check(newcomer.role=="citizen","touch recruits a dawn arrival")
	scene.paused=true
	dawn(scene)
	check(sim.world.people.size()==14 and sim.clock.day==2,"pause cannot replenish another dawn")
	scene.paused=false
	scene._physics_process(0.02)
	check(sim.world.people.size()==15 and sim.clock.day==3,"next dawn replaces only recruited waiting place")
	var forest: int=sim.frontier.regions.find(sim.frontier.regions.filter(func(r):return r.kind=="forest")[0])
	sim.frontier.regions[forest].discovered=true
	var prey=sim.frontier.animals.filter(func(a):return a.region==forest)[0]
	for animal in sim.frontier.animals:animal.alive=false
	prey.alive=true
	var hunter: Dictionary={"role":"hunter","x":prey.x,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1}
	sim.world.people.append(hunter)
	var initial: int=sim.pouch.amount+sim.pouch.ground_total()
	scene._physics_process(0.02)
	check(not prey.alive and sim.frontier.food==0 and sim.pouch.amount+sim.pouch.ground_total()==initial+2,"actual hunter drops two crystals")
	dawn(scene)
	check(prey.alive,"next dawn restores hunted prey slot")
	for tick in range(190):
		await physics_frame
		scene._physics_process(1.0/60)
	check(sim.pouch.amount+sim.pouch.ground_total()>=initial+4,"renewable prey supplies further crystals")
	check(sim.frontier.food==0,"hunting never accumulates a second currency")
	scene.restart()
	check(scene.sim.world.people.size()==8 and scene.sim.ecology.last_dawn==1,"restart restores initial camps and renewal clock")
	scene.queue_free()
	await process_frame
	print("Ecology scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
