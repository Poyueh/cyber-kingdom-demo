extends "res://tests/test_scene.gd"
const STEP: float=1.0/30.0
var edition: String="full" if "--command-main" in OS.get_cmdline_user_args() else "demo"
func step(game: Node, count: int) -> void:
 for tick: int in range(count):
  game.paused=false;game._physics_process(STEP)
  await physics_frame
func shot(game: Node, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 game.view.queue_redraw();RenderingServer.force_draw(false)
 DirAccess.make_dir_recursive_absolute("res://test-results/command-"+edition)
 root.get_texture().get_image().save_png("res://test-results/command-"+edition+"/"+name+".png")
func run_scene() -> void:
 ProjectSettings.set_setting("distribution/edition",edition)
 ProjectSettings.set_setting("campaign/control_preview",2)
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game._guided_campaign=true;game.campaign_save_path="";game.audio_preferences_path=""
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(8);game.set_physics_process(false)
 var sim: RefCounted=game.sim
 sim.interact(sim.world.sites.hall,"hall")
 await step(game,170)
 sim.frontier.city_level=3;sim.core_loop.income=6;sim.core_loop.stage=5;sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
 sim.clock.survived=2;sim.clock.day=3;sim.pouch.amount=30
 sim.command.used.assign(["farm","farm_tools"])
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 for id: String in ["wall","wall_left"]:sim.world.walls[id].level=1;sim.world.walls[id].hp=sim.world.wall_max_hp(1)
 game.knight.position.x=sim.command.barracks_x()
 await step(game,300);await shot(game,"barracks")
 check(sim.context_for_key(game.knight.position.x,"command_armory").enabled,"barracks has playable gear interaction")
 var keeper: RefCounted=game.view._attendants
 check(keeper.site_x(&"armory")==sim.command.barracks_x() and keeper.states[5].visible,"barracks keeper moves with the real command post")
 for i: int in range(3):sim.interact(game.knight.position.x,"command_armory")
 await step(game,2)
 check(keeper.states[5].mode==3,"real gear purchase triggers the barracks service animation")
 game.knight.position.x=sim.command.flag_x(1)
 await step(game,10);await shot(game,"flag-missing")
 check(sim.context(game.knight.position.x).id=="rally" and not sim.context(game.knight.position.x).enabled,"missing roster remains visible but unavailable")
 var fixture: RefCounted=load("res://tests/test_command_squads.gd").new()
 fixture.people(sim,18)
 game.knight.position.x=sim.command.flag_x(1)
 await step(game,12);await shot(game,"flag-ready")
 key(KEY_E,true);await step(game,45);key(KEY_E,false);await step(game,2)
 check(sim.command.squads.size()>=1,"actual E investment forms a company")
 sim.pouch.amount=30
 for attempt: int in range(2):
  sim.interact(game.knight.position.x,"rally:1");sim.interact(game.knight.position.x,"rally:1")
 key(KEY_D,true);await step(game,45);key(KEY_D,false);await step(game,30)
 await shot(game,"three-squads")
 check(sim.command.squads.size()==3,"three companies remain together outside town")
 game.knight.position.x=sim.world.sites.hall;await step(game,2)
 check(sim.command.squads.is_empty(),"entering town releases all squads in the real scene")
 game.knight.position.x=sim.command.ship_x;sim.pouch.amount=30
 await step(game,18);await shot(game,"wreck")
 key(KEY_E,true);await step(game,80);key(KEY_E,false);await step(game,2)
 check(sim.command.repaired,"actual input repairs the wreck")
 sim.clock.day+=3;sim.clock.survived+=3
 await step(game,3);await shot(game,"rescue-three")
 check(sim.command.waiting==3,"three real passengers light the ship bays")
 var before: int=sim.world.people.size()
 key(KEY_E,true);await step(game,55);key(KEY_E,false);await step(game,2)
 check(sim.world.people.size()>before and sim.command.waiting<3,"actual input recruits a passenger")
 await shot(game,"rescue-recruited")
 game.queue_free();await frames(3)
 print("Command scene: %d assertions; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
