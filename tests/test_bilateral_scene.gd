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
	scene.knight.position.x=30
	await frames(2)
	scene.set_physics_process(false)
	pay(scene);pay(scene)
	check(scene.sim.frontier.city_level==1,"touch investment establishes camp")
	var sim=scene.sim
	sim.world.people.clear()
	scene.knight.position=Vector2(sim.world.sites.wall_left,430)
	scene._physics_process(1.0/60)
	pay(scene)
	check(sim.context(scene.knight.position.x).paid==1,"left touch input fills one left slot")
	scene.knight.position.x=sim.world.sites.wall
	scene._physics_process(1.0/60)
	pay(scene);pay(scene);pay(scene)
	check(sim.world.wall.pending and not sim.world.walls.wall_left.pending,"right touch order leaves left partial")
	scene.knight.position.x=sim.world.sites.wall_left
	scene._physics_process(1.0/60)
	pay(scene);pay(scene)
	check(sim.pouch.amount==4,"camp and two wall orders consume exactly eight crystals")
	for id in ["wall","wall_left"]:
		var side:=1 if id=="wall" else -1
		sim.world.people.append({"role":"engineer","x":sim.world.sites[id]-side*12,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1})
	scene.paused=true
	var progress: float=sim.world.walls.wall_left.progress
	for tick in range(5):scene._physics_process(0.1)
	check(sim.world.walls.wall_left.progress==progress,"pause freezes left construction")
	scene.paused=false
	for tick in range(210):
		await physics_frame
		scene._physics_process(1.0/60)
	check(sim.world.walls.wall_left.hp==40 and sim.world.wall.hp==40,"real campaign updates build both defenses")
	sim.clock.remaining=29
	scene._physics_process(1.0/60)
	check(scene.hud.dashboard.values.raid_left==1 and scene.hud.dashboard.values.raid_right==2,"HUD previews separate night directions")
	sim.clock.remaining=0.01
	for tick in range(160):
		await physics_frame
		scene._physics_process(1.0/60)
	var left_enemy=sim.raiders.filter(func(r):return r.get("side",1)<0)[0]
	var right_enemy=sim.raiders.filter(func(r):return r.get("side",1)>0)[0]
	check(left_enemy.direction>0 and right_enemy.direction<0,"opposite invaders face toward the camp")
	scene.knight.position.x=30
	left_enemy.x=sim.world.sites.wall_left-25
	right_enemy.x=sim.world.sites.wall+25
	for tick in range(45):
		await physics_frame
		scene._physics_process(1.0/60)
	check(sim.world.walls.wall_left.hp==20,"left siege damages visible left defense")
	check(sim.world.wall.hp==20,"right siege independently damages right defense")
	scene.restart()
	check(scene.sim.world.walls.wall_left.level==0 and scene.sim.world.wall.level==0,"restart clears both defenses")
	check(scene.sim.raid_pressure()=={"left":0,"right":0},"restart clears raid warning")
	scene.queue_free()
	await process_frame
	print("Bilateral scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
