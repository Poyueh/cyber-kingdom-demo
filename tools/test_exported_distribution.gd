extends SceneTree
var failures: int=0
var assertions: int=0
func check(ok: bool, label: String) -> void:
 assertions+=1
 if not ok:failures+=1
 print(("PASS: " if ok else "FAIL: ")+label)
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 set_meta("campaign_prologue_seen",true)
 call_deferred("verify")
func verify() -> void:
 var demo: bool=preload("res://infrastructure/distribution.gd").demo()
 for world: String in ["desert","frost","swamp","volcanic","storm","void"]:
  check(ResourceLoader.exists("res://data/planets/"+world+".tres")==not demo,"world data membership: "+world)
  check(ResourceLoader.exists("res://data/levels/"+world+".tres")==not demo,"level membership: "+world)
  check(ResourceLoader.exists("res://data/trails/"+world+".tres")==not demo,"encounter membership: "+world)
  check(ResourceLoader.exists("res://data/enemy_appearance/dragon-"+world+".tres")==not demo,"dragon data membership: "+world)
  check(ResourceLoader.exists("res://art/characters/devourers-v001/dragon-"+world+".png")==not demo,"dragon atlas membership: "+world)
  var folder: String="v001" if world in ["desert","frost"] else "v002"
  check(ResourceLoader.exists("res://art/planets/"+folder+"/"+world+"-sky.png")==not demo,"planet scenery membership: "+world)
 var menu: Node=load("res://scenes/start_menu.tscn").instantiate()
 menu.campaigns_directory="user://edition-test-records";menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu)
 for i: int in range(5):await process_frame
 check(menu.view.new_button.visible==not demo,"only main edition offers full journey")
 check(menu.campaigns_directory==("user://forest_demo_campaigns" if demo else "user://edition-test-records"),"edition uses isolated record directory")
 menu.queue_free();await process_frame
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game._guided_campaign=true;game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game)
 for i: int in range(8):await process_frame
 check(game.sim.core_loop.enabled and not game.sim.core_loop.trial and game.sim.core_loop.contained==demo,"shipped scene resolves correct guidance mode")
 check((game.journey==null)==demo,"demo cannot create a seven-world envelope")
 check(game.sim.frontier.right_boundary>5000,"both editions play the full forest map")
 check(game.sim.merchant.enabled and game.sim.modules.relics.size()>0,"both editions ship the merchant and ruin discoveries")
 check(game.sim.mission.rifts.size()>0,"both editions ship gates for engineers to seal")
 check(game.sim.planet.enabled and game.sim.planet.finale==demo,"main builds a rocket to travel; the demo's rocket is its finale")
 check(game.hud.core_hud.wallet.visible,"common guidance UI renders in shipped scene")
 check(game.hud.guide_view.visible and game.hud.guide_view.hint.get("core",false),"shipped companion is visible with a real core objective")
 check(not game.hud.core_hud.caption.visible,"shipped UI has no duplicate static tutorial")
 game.sim.advance(181,game.knight.position.x)
 for i: int in range(3):await physics_frame
 check(game.hud.guide_view.visible and game.hud.guide_view.modulate.a>0.9,"shipped companion survives the old time limit")
 var packet: Dictionary={"session":game.sim}
 check(preload("res://infrastructure/distribution.gd").accepts(packet),"edition accepts its own record")
 if demo:
  packet["journey"]=true
  check(not preload("res://infrastructure/distribution.gd").accepts(packet),"demo refuses seven-world record")
 if DisplayServer.get_name()!="headless":
  await process_frame
  root.get_texture().get_image().save_png("/tmp/edition-"+("demo" if demo else "main")+".png")
 game.queue_free();await process_frame
 print("Distribution assertions: %d; failures: %d"%[assertions,failures])
 quit(1 if failures else 0)
