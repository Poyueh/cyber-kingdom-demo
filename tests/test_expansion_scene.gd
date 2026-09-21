extends "res://tests/test_scene.gd"
func pay(scene) -> void:
	scene.hud.interact_button.button_down.emit()
	scene._physics_process(1.0/60)
	scene.hud.interact_button.button_up.emit()
	scene._physics_process(1.0/60)
func run_scene() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false
	root.add_child(scene)
	await frames(8)
	scene.set_physics_process(false)
	scene.paused=false
	var sim=scene.sim
	sim.frontier.city_level=2
	sim.world.people.clear()
	var id: String="frontier_wall:3"
	var x: float=sim.world.sites[id]
	sim.frontier.regions[3].discovered=true
	sim.frontier.regions[3].outpost_built=true
	sim.world.wall.merge({"level":1,"hp":40},true)
	for node in sim.frontier.nodes:
		if node.region==3 and node.kind in ["tree","crystal","stone","cache"]:node.collected=true
	scene.knight.position=Vector2(x,430)
	await frames(2)
	scene._physics_process(1.0/60)
	check(scene.view._context.id=="wall" and scene.view._context.x==x,"actual proximity shows outward wall icon and target")
	pay(scene)
	check(scene.view._context.paid==1,"touch fills first outward wall slot")
	pay(scene);pay(scene)
	check(sim.world.walls[id].pending and sim.pouch.amount==9,"touch completes only the outward wall order")
	sim.world.people.append({"role":"engineer","x":x-12,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1})
	var guard={"role":"guard","x":x-90,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1}
	sim.world.people.append(guard)
	scene.paused=true
	scene._physics_process(1)
	check(sim.world.walls[id].progress==0,"pause freezes outward construction")
	scene.paused=false
	for tick in range(210):
		await physics_frame
		scene._physics_process(1.0/60)
	check(sim.world.walls[id].hp==40,"scene worker completes outward wall")
	check(sim.defenses.active_post(1)==id,"new wall becomes actual defense destination")
	sim.clock.remaining=0.01
	scene._physics_process(0.02)
	check(sim.raiders[0].x>x,"actual scene night spawns beyond expanded front")
	sim.world.walls[id].hp=0
	var before: float=guard.x
	scene._physics_process(0.1)
	check(guard.x<before,"guard walks back after outward wall breaks")
	scene.restart()
	check(scene.sim.world.walls[id].level==0 and scene.sim.defenses.active_post(1)=="wall","restart clears expansion and restores original post")
	check(not scene.sim.defenses.visible(id),"restart hides unexplored expansion")
	scene.queue_free()
	await process_frame
	print("Expansion scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
