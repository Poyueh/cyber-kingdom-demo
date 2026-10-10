extends SceneTree
var failures: int=0
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func check(value: bool, message: String) -> void:
 if not value:failures+=1;printerr("FAIL: "+message)
 else:print("PASS: "+message)
func collect(game: Node) -> void:
 for relic: RefCounted in game.sim.modules.relics:
  var site: RefCounted=game.sim.trials.get_site(relic.id)
  for station: int in site.order:
   game.sim.advance(0.1,site.positions[station])
   check(game.sim.interact(site.positions[station],"trial:%s:%d"%[site.id,station]),"exported ruin accepts ordinary interaction")
  game.sim.advance(0.1,relic.x)
  check(game.sim.modules.equipped==relic.id,"exported world grants its distinct relic: "+relic.id)
func win(game: Node) -> void:
 for rift: Dictionary in game.sim.mission.rifts:rift.sealed=true
 game.sim.raiders.clear();game.sim.mission.dragon_summoned=true;game.sim.mission.dragon_defeated=true;game.sim.mission.dragon_day=6
 game.sim.frontier.city_level=1;game.sim.survival.armed=true
 game.sim.advance(0.1,-730)
 check(game.sim.planet.claim_core(),"unique core claim")
 game.sim.planet.rocket_ready=true;game.knight.position=Vector2(-730,430)
func run() -> void:
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path="";root.add_child(game)
 for i: int in range(8):await physics_frame
 game.set_physics_process(false);game.sim.interact(30,"hall");game.sim.pouch.amount=30
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 check(game.sim.modules.specs.size()==8,"release catalogue contains eight definitions")
 check(not FileAccess.file_exists("res://art/concepts/mount-expedition-v001/source.png"),"source art excluded from release")
 collect(game)
 check(game.sim.activate_module(30),"exported active module works")
 var owned: int=game.sim.modules.found.size()
 for target: int in [1,3,2,4,5,6]:
  win(game)
  var remaining: int=maxi(0,game.sim.modules.ready_tick-roundi(game.sim.workforce.elapsed*30))
  check(game.sim.interact(-730,"star_map"),"rocket interaction opens route")
  game._star_travel.observe()
  game._star_travel.map._buttons[target].pressed.emit();game._star_travel.map._launch.pressed.emit()
  check(game.journey.current==target,"release arrives on chosen planet")
  check(game.sim.modules.found.size()==owned,"release-mode travel actually transfers inventory")
  check(game.sim.modules.ready_tick-roundi(game.sim.workforce.elapsed*30)==remaining,"release-mode travel preserves remaining cooldown")
  collect(game);owned=game.sim.modules.found.size()
  var body: Dictionary={"x":game.knight.position.x,"y":430.0,"vx":0.0,"vy":0.0}
  var packet: Dictionary=game.journey.capture(game.sim,body)
  check(not load("res://application/star_voyage.gd").restore(JSON.parse_string(JSON.stringify(packet))).is_empty(),"world and collection checkpoint round-trip")
 check(game.sim.modules.found.size()==8,"all eight distinct rewards are obtainable")
 win(game);game.journey.observe(game.sim)
 check(game.sim.mission.outcome=="victory","seven-core victory remains reachable")
 game._arrival_banner.hide();game.paused=true
 game.hud.module_menu.show();game.hud.module_menu.present(game.sim.modules,false,30)
 for i: int in range(5):await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/cyber-v23-packaged.png")
 game.audio.enabled=false;game.audio.stop();game.queue_free();await process_frame
 print("Packaged star relic checks, failures: ",failures)
 quit(1 if failures else 0)
