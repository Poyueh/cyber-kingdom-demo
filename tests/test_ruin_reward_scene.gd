extends "res://tests/test_mobile_scene.gd"
func capture(game: Node, label: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results/ruin-rewards")
 game.get_viewport().get_texture().get_image().save_png("res://test-results/ruin-rewards/"+label+".png")
func run_scene() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";root.add_child(game);await frames(8)
 game.set_physics_process(false)
 var sim: RefCounted=game.sim
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 var site: RefCounted=sim.trials.sites[0]
 game.knight.position=Vector2(site.x,430)
 game.knight.get_node("Camera2D").reset_smoothing()
 game._physics_process(1.0/30)
 TranslationServer.set_locale("en")
 game.hud._present_modules(sim,site.positions[0],false,false)
 check(game.hud.module_hint.text.contains("Repels nearby"),"unsolved station previews its actual reward purpose")
 for station: int in site.order:
  sim.interact(site.positions[station],"trial:%s:%d"%[site.id,station])
 check(site.progress==3,"real station interactions solve the seal")
 game.hud._present_modules(sim,site.positions[2],false,false)
 check(game.hud.module_hint.text.contains("pedestal"),"solving directs player to the unclaimed reward")
 sim.modules.observe(sim,site.x,430)
 game.hud._present_modules(sim,site.x,false,false)
 check(sim.modules.equipped==site.id,"approaching pedestal equips actual reward")
 check(game.hud.module_hint.text.contains("Repels nearby") and game.hud.module_hint.text.contains("K"),"milestone cannot hide reward purpose or activation input")
 game.hud._present_modules(sim,site.x,false,true)
 check(game.hud.module_hint.text.contains("two fingers"),"touch pickup explains the correct gesture")
 sim.effects.clear()
 game.hud._present_modules(sim,site.x,false,false)
 check(not game.hud.module_hint.visible,"claimed ruins do not keep advertising a reward")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale)
  sim.effects.append({"kind":"module_pickup","module":site.id,"x":site.x,"life":5.0})
  game.hud._present_modules(sim,site.x,false,false)
  await capture(game,"pickup-"+locale)
  check(not game.hud.module_hint.text.contains("reward."),"reward text translates in "+locale)
  game.hud._present_modules(sim,site.x,true,false)
  check(not game.hud.module_hint.visible,"pause hides reward hint in "+locale)
  sim.effects.clear()
 TranslationServer.set_locale("en")
 var q: RefCounted=sim.mount_quest
 game.hud._present_modules(sim,q.levers[0],false,false)
 check(game.hud.module_hint.text.contains("steed core"),"conductor previews the steed reward")
 for i: int in range(2):
  while q.rotations[i]!=i+1:sim.interact(q.levers[i],"mount_lever:%d"%i)
 game.hud._present_modules(sim,q.ruin_x,false,false)
 check(game.hud.module_hint.text.contains("press E"),"powered cradle explains recovery input")
 sim.interact(q.ruin_x,"mount_recover")
 game.hud._present_modules(sim,q.ruin_x,false,false)
 check(q.recovered and game.hud.module_hint.text.contains("%d crystals"%q.cost),"core pickup explains actual stable price")
 game.queue_free();await process_frame
 print("Ruin reward assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
