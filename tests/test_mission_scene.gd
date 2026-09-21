extends "res://tests/test_scene.gd"
const ObjectiveTests=preload("res://tests/test_campaign_objective.gd")
func pay(scene) -> void:
	scene.hud.interact_button.button_down.emit()
	scene._physics_process(1.0/60)
	scene.hud.interact_button.button_up.emit()
	scene._physics_process(1.0/60)

func step(scene, count: int) -> void:
	for tick in range(count):
		await physics_frame
		scene._physics_process(1.0/60)

func run_scene() -> void:
	var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12
	scene.tuning=scene.tuning.duplicate()
	scene.tuning.core_max_hp=40
	scene.tuning.core_recharge=10
	scene.tuning.rift_seal_seconds=2
	root.add_child(scene)
	await frames(8)
	scene.set_physics_process(false)
	scene.paused=false
	var sim=scene.sim
	check(sim.mission.core_hp==40 and sim.mission.core_recharge==10 and sim.mission.seal_seconds==2,"Inspector values reach the campaign mission")
	sim.world.people.clear()
	scene.knight.position.x=500
	var enemy=sim._spawn_raider()
	enemy.x=sim.world.sites.hall+20
	sim.raiders.append(enemy)
	await step(scene,160)
	check(sim.mission.outcome=="defeat" and sim.hero.is_alive(),"actual siege ends the run while knight is alive")
	check(scene.hud.dashboard.dead and not scene.hud.dashboard.victory,"HUD displays core defeat")
	check(scene.hud.get_node("restart").visible and scene.hud.new_map_button.visible,"core defeat offers replay and new map")
	check(scene.hud.interact_button.disabled and scene.hud.drop_button.disabled,"loss disables investment and dropping")
	var at: Vector2=scene.knight.position
	var wallet: int=sim.pouch.amount
	key(KEY_D,true)
	key(KEY_J,true)
	scene.hud.throw_requested.emit()
	await step(scene,4)
	key(KEY_D,false);key(KEY_J,false)
	check(scene.knight.position==at and sim.pouch.amount==wallet,"post-loss inputs cannot move or spend")
	key(KEY_R,true)
	await step(scene,1)
	key(KEY_R,false)
	await step(scene,1)
	check(scene.sim.is_running() and scene.sim.mission.core_hp==40,"replay button restores core and active run")
	sim=scene.sim
	sim.world.people.clear()
	sim.frontier.city_level=3
	sim.clock.survived=3
	for wall in sim.world.walls.values():wall.merge({"level":2,"hp":80},true)
	var helpers=ObjectiveTests.new()
	var worker=helpers.engineer(sim,30)
	await step(scene,1)
	check(not scene.hud.dashboard.victory,"city milestone does not display premature victory")
	for index in range(2):
		var rift: Dictionary=sim.mission.rifts[index]
		scene.knight.position=Vector2(rift.x,430)
		worker.x=rift.x-rift.side*28
		await step(scene,2)
		for i in range(4):pay(scene)
		check(rift.ordered,"touch slots order actual expedition "+str(index))
		await step(scene,2)
		check(sim.raiders.size()==2,"scene summons real rift wardens "+str(index))
		check(scene.hud.guide_view.hint.kind=="fight","expedition guide reports living wardens")
		helpers.clear_wardens_with_sword(sim,rift.x)
		var progress: float=rift.progress
		scene.paused=true
		await step(scene,3)
		check(rift.progress==progress,"pause freezes sealing work")
		check(not scene.hud.guide_view.visible,"pause hides expedition guide")
		scene.paused=false
		await step(scene,1)
		check(scene.hud.guide_view.hint.kind=="seal","cleared wardens switch guide to live seal progress")
		await step(scene,125)
		check(rift.sealed,"scene finishes engineer sealing work "+str(index))
	check(not scene.hud.dashboard.victory and sim.mission.dragon_summoned,"two seals summon final dragon")
	for remaining_enemy in sim.raiders:remaining_enemy.fighter.hp=0
	await step(scene,3)
	check(scene.hud.dashboard.victory and not scene.hud.dashboard.dead,"dragon defeat displays victory")
	check(not scene.hud.guide_view.visible,"victory removes expedition advice")
	check(scene.hud.get_node("restart").visible and scene.hud.new_map_button.visible,"victory offers replay and new map")
	var time: float=sim.clock.remaining
	await step(scene,3)
	check(sim.clock.remaining==time,"victory freezes calendar in actual scene")
	scene.hud.new_map_requested.emit()
	await step(scene,2)
	check(scene.sim.is_running() and scene.sim.mission.rifts.all(func(r):return not r.discovered and not r.ordered),"new map resets objectives and discovery")
	scene.queue_free()
	await process_frame
	print("Mission scene assertions: %d; failures: %d" % [assertions,failures])
	quit(0 if failures==0 else 1)
