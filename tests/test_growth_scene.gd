extends "res://tests/test_scene.gd"
func pay(scene) -> void:
	scene.hud.interact_button.button_down.emit()
	scene._physics_process(1.0/60)
	scene.hud.interact_button.button_up.emit()
	scene._physics_process(1.0/60)
func place(scene,x: float) -> void:
	scene.knight.position=Vector2(x,430)
	await frames(2)
	scene._physics_process(1.0/60)
func run_scene() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12
	root.add_child(scene)
	await frames(8)
	scene.knight.position.x=30
	await frames(2)
	scene.set_physics_process(false)
	scene.paused=false
	pay(scene);pay(scene)
	var sim=scene.sim
	sim.world.people.clear()
	await place(scene,350)
	pay(scene);pay(scene)
	check(sim.hero.shield==20,"touch investment installs first capacitor")
	check(scene.hud.dashboard.values.get("shield_capacity",-1)==20,"HUD shows installed shield capacity")
	check(scene.hud.interact_button.disabled,"first camp cannot buy another capacitor")
	sim.hero.take_damage(15)
	scene._physics_process(1.0/60)
	check(not scene.hud.interact_button.disabled and scene.view._context.id=="shield_charge","damage changes forge to touch recharge")
	pay(scene)
	check(sim.hero.shield==20 and sim.world.scrap==0,"touch recharge restores energy using only crystals")
	sim.frontier.city_level=2
	scene._physics_process(1.0/60)
	pay(scene);pay(scene);pay(scene)
	check(sim.hero.shield==40,"second settlement unlocks next capacitor")
	check(scene.hud.dashboard.values.get("shield_capacity",-1)==40,"HUD updates actual upgraded capacity")
	await place(scene,1230)
	pay(scene);pay(scene)
	check(sim.hero.stats.damage==30 and sim.frontier.food==0,"touch training changes real damage without food")
	check(scene.hud.dashboard.values.get("damage",-1)==30,"HUD shows trained sword power")
	var wallet: int=sim.pouch.amount
	scene.paused=true
	pay(scene)
	check(sim.pouch.amount==wallet,"pause blocks growth investment")
	scene.restart()
	scene._physics_process(1.0/60)
	check(scene.sim.hero.stats.damage==25 and scene.sim.hero.shield==0,"restart resets purchased combat strength")
	check(scene.hud.dashboard.values.get("shield_capacity",-1)==0,"restart clears capacitor capacity")
	scene.queue_free()
	await process_frame
	print("Growth scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
