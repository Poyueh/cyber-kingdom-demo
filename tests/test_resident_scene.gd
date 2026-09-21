extends "res://tests/test_scene.gd"
func run_scene() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false
	scene.tuning=scene.tuning.duplicate()
	scene.tuning.return_margin=18.0
	scene.tuning.hunter_damage=14
	root.add_child(scene)
	await frames(8)
	scene.set_physics_process(false)
	var sim=scene.sim
	sim.frontier.city_level=1
	sim.world.people.clear()
	var farmer={"role":"farmer","x":sim.world.sites.farm,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1}
	var hunter={"role":"hunter","x":1010.0,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1}
	sim.world.people.append(farmer)
	sim.world.people.append(hunter)
	sim.world.wall.merge({"level":1,"hp":40},true)
	sim.frontier.farm_active=true
	sim.frontier.farm_progress=2.0
	sim.clock.remaining=2.0
	var start: float=farmer.x
	for tick in range(150):
		await physics_frame
		scene.paused=false
		scene._physics_process(1.0/60)
	check(farmer.x>start+100,"campaign physics moves the farmer home before night")
	check(farmer.get("walk_distance",0)>100,"retreat advances the existing walk animation")
	check(sim.frontier.farm_progress==2.0,"presentation loop cannot farm while returning")
	check(sim.clock.is_night,"scene calendar naturally enters night")
	check(sim.return_margin==18.0 and sim.hunter_damage==14,"Inspector resident tuning reaches campaign rules")
	var raider=sim.raiders[0]
	raider.x=hunter.x+100
	var health: int=raider.fighter.hp
	hunter.cooldown=0
	await physics_frame
	scene._physics_process(1.0/60)
	check(raider.fighter.hp==health-14,"actual night bow uses configured damage")
	check(sim.effects.any(func(effect):return effect.kind=="bolt"),"night bow feeds existing visible bolt effects")
	scene.paused=true
	var paused_x: float=farmer.x
	for tick in range(5):
		await physics_frame
		scene._physics_process(1.0/60)
	check(farmer.x==paused_x,"pause freezes returning residents")
	scene.restart()
	check(not scene.sim.clock.is_night and scene.sim.world.people[0].role=="wanderer","restart clears nightly role state")
	scene.queue_free()
	await process_frame
	print("Resident scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
