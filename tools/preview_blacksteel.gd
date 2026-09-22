extends SceneTree
## Native visual review of the installed campaign appearance, without save writes.
var scene: Node
var output: String = "/tmp/knight-v002-native"

func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	ProjectSettings.set_setting("campaign/control_preview",1)
	call_deferred("run")

func capture(label: String) -> void:
	scene.view.present(scene.sim,scene.knight.position.x)
	scene.knight.get_node("Camera2D").reset_smoothing()
	scene.knight.get_node("Camera2D").force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	scene=load("res://scenes/frontier.tscn").instantiate()
	root.add_child(scene)
	for tick: int in range(8):await physics_frame
	scene.set_physics_process(false)
	scene.knight.position=Vector2(30,430)
	var view: AnimatedSprite2D=scene.knight.visual
	assert(view.appearance!=null)
	assert(view.sprite_frames.get_frame_texture(&"run",0).atlas.resource_path.ends_with("blacksteel-v002/run.png"))
	for label: String in ["unarmed","idle","run","sprint","fatigue","ceremony","slash","advancing","mounted","hurt","death"]:
		view.reset_pose()
		view.equipped_module="arc"
		view.unarmed=label in ["unarmed","death"]
		view.breathing=label=="fatigue"
		view.exertion=1.0 if label=="fatigue" else 0.0
		view.ceremony_age=1.35 if label=="ceremony" else -1.0
		view.set_mounted(label=="mounted")
		var pose: Dictionary={"alive":label!="death","facing":1,"moving":label in ["run","sprint","advancing"],
			"horizontal_speed":322.0 if label=="sprint" else 165.0,"grounded":true,"hp":10.0,"shield":0.0,
			"invulnerable":false,"attack_progress":0.43 if label in ["slash","advancing"] else 1.0,
			"attack_advancing":label=="advancing","combo_step":1}
		view.present(pose,0.5)
		view.present(pose,0.1)
		if label=="hurt":
			view.damage_serial+=1
			view.present(pose,0.02)
		await capture(label)
	view.reset_pose();view.unarmed=false;view.breathing=false;view.set_mounted(false);view.ceremony_age=-1
	for index: int in range(8):
		view._gait_time=float(index)/12.0
		view.present({"alive":true,"facing":1,"moving":true,"grounded":true,"hp":10,"shield":0,"invulnerable":false,"attack_progress":1.0,"horizontal_speed":165.0},0)
		await capture("run-%02d"%index)
	scene.sim.interact(30,"hall")
	scene.sim.effects.clear()
	scene.sim.pouch.amount=20
	for i: int in range(5):scene.sim.interact(30,"hall:1")
	for i: int in range(2):scene.sim.interact(scene.sim.world.sites.farm_tools,"farm_tools")
	scene.knight.position.x=scene.sim.world.sites.farm_tools
	view.unarmed=false;view.equipped_module="lance"
	view.present({"alive":true,"facing":1,"moving":false,"hp":10,"shield":0,"invulnerable":false,"grounded":true,"attack_progress":1.0},0.1)
	scene.hud.present_world(scene.sim,false,scene.knight.position.x,true)
	await capture("farm-tools-tier-two")
	scene.sim.modules.found.assign(["arc","lance"]);scene.sim.modules.stored.assign(["arc","lance"])
	scene.knight.position.x=scene.sim.world.sites.drill
	for language: String in ["zh_TW","zh_CN","en"]:
		TranslationServer.set_locale(language)
		scene.hud.module_menu.show();scene.hud.module_menu.present(scene.sim.modules,false)
		scene.hud.present_world(scene.sim,true,scene.knight.position.x,true)
		await capture("modules-"+language)
	scene.hud.control_mode=2
	scene.hud.present_world(scene.sim,true,scene.knight.position.x,true)
	await capture("modules-desktop")
	print("PASS: installed appearance rendered in campaign for 11 states; saves disabled")
	scene.queue_free()
	await process_frame
	quit()
