extends "res://tests/test_scene.gd"
## The Demo finale in the shipped scene: the fallen dragon points to its core, the
## finished rocket plays its own epilogue, and the game then returns to the start menu.
const Ops=preload("res://application/planet_operations.gd")
const Direction=preload("res://data/outcome_direction.tres")

func settle(count: int) -> void:
	await frames(count)
	await process_frame;await process_frame

func run_scene() -> void:
	ProjectSettings.set_setting("distribution/edition","demo")
	set_meta("campaign_prologue_seen",true)
	var game: Node=load("res://scenes/frontier.tscn").instantiate()
	game.campaign_save_path="";game.audio_preferences_path=""
	root.add_child(game);current_scene=game
	await frames(8)
	var sim: RefCounted=game.sim
	check(sim.core_loop.contained and sim.planet.finale,"the shipped demo ends with the rocket finale")
	sim.interact(sim.world.sites.hall,"hall")
	sim.core_loop.income=6;sim.core_loop.stage=5;sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
	for rift: Dictionary in sim.mission.rifts:rift.sealed=true
	sim.mission.dragon_summoned=true;sim.mission.dragon_defeated=true;sim.mission.dragon_day=6
	sim.raiders.clear()
	await frames(3)
	check(sim.is_running() and game._arrival_banner.visible,"the fallen dragon is announced while the demo goes on")
	check(game._arrival_banner._label.text.contains(game.tr("planet.claim_info")),"the announcement points to the dragon core")
	check(sim.interact(Ops.core_x(sim),"dragon_core"),"the core is claimed in the scene")
	sim.pouch.amount=sim.pouch.capacity
	for i: int in range(int(sim.planet.cost())):sim.interact(Ops.rocket_x(sim),"rocket")
	check(sim.planet.rocket_pending,"the rocket is funded")
	sim.planet.work_on(sim.planet.work_required)
	await frames(3)
	check(sim.mission.outcome=="victory" and game.hud.dashboard.victory,"the finished rocket completes the demo")
	check(game.hud.dashboard.epilogue_lines().has("火箭完成了。"),"the epilogue tells of the rocket")
	await frames(int(Direction.finale_return*0.5*Engine.physics_ticks_per_second))
	check(current_scene==game,"the epilogue stays on screen before leaving")
	await settle(int(Direction.finale_return*0.6*Engine.physics_ticks_per_second)+10)
	check(current_scene!=null and current_scene.name=="StartMenu","the finished demo returns to the start menu by itself")
	ProjectSettings.set_setting("distribution/edition","full")
	print("Demo finale scene: %d assertions, %d failures"%[assertions,failures])
	quit(1 if failures else 0)
