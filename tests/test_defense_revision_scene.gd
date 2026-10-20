extends "res://tests/test_scene.gd"
const STEP: float=1.0/30.0
var edition: String="full" if "--defense-main" in OS.get_cmdline_user_args() else "demo"
func step(game: Node, count: int) -> void:
 for tick: int in range(count):
  if not game.hud.core_hud.panel.visible:game.paused=false # Native OS focus may pause background test windows.
  game._physics_process(STEP)
  await physics_frame
func shot(game: Node, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 game.view.queue_redraw();RenderingServer.force_draw(false)
 DirAccess.make_dir_recursive_absolute("res://test-results/defense-"+edition)
 root.get_texture().get_image().save_png("res://test-results/defense-"+edition+"/"+name+".png")
func run_scene() -> void:
 ProjectSettings.set_setting("distribution/edition",edition)
 ProjectSettings.set_setting("campaign/control_preview",2)
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game._guided_campaign=true;game.campaign_save_path="";game.audio_preferences_path=""
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(8);game.set_physics_process(false)
 var sim: RefCounted=game.sim
 sim.interact(sim.world.sites.hall,"hall");await step(game,170)
 sim.frontier.city_level=3;sim.core_loop.income=6;sim.core_loop.stage=5;sim.core_loop.checkpoint_index=0;sim.core_loop.checkpoint_pending=0
 sim.clock.survived=2;sim.clock.day=3;sim.pouch.amount=12
 sim.command.used.assign(preload("res://application/feature_lessons.gd").IDS)
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 for id: String in ["wall","wall_left"]:sim.world.walls[id].level=1;sim.world.walls[id].hp=sim.world.wall_max_hp(1)
 sim.world.people[0].role="hunter"
 game.knight.position.x=sim.core_loop.orders.station_x(sim)
 await step(game,18);await shot(game,"command-post")
 check(sim.context(game.knight.position.x).id=="guard_station","station owns the real E interaction")
 key(KEY_E,true);await step(game,2);key(KEY_E,false);await frames(2)
 check(game.paused and game.hud.core_hud.panel.visible,"E opens the building's orders panel")
 var before: int=sim.pouch.amount
 game.hud.core_hud.row_buttons.wall[1].pressed.emit();await step(game,1)
 check(sim.pouch.amount==before-1 and sim.core_loop.orders.targets.has("wall"),"the real panel assigns one archer and spends one crystal")
 await shot(game,"paid-orders")
 game.hud.core_hud.panel.hide();game.hud.core_hud.orders_toggled.emit(false)
 game.knight.position.x=sim.world.sites.hall;await step(game,12);await shot(game,"camp-max")
 check(not game.hud.core_hud.action_button.visible or game.hud.core_hud.action_button.disabled,"maximum camp does not accept payment")
 game.knight.position.x=sim.world.sites.wall+300;await step(game,20)
 var soldier: Dictionary=sim.world.people[1];soldier.role="guard";soldier.x=game.knight.position.x+135;soldier.direction=1.0
 var enemy: Dictionary=sim._spawn_raider();enemy.x=soldier.x+26;enemy.cooldown=0.5;enemy.fighter.hp=500;enemy.fighter.stats.max_hp=500;sim.raiders.append(enemy)
 for i: int in range(36):
  await step(game,1)
  if i in [0,4,10,18,26,35]:await shot(game,"shield-%02d"%i)
 check(soldier.role=="guard","sword and shield survive a telegraphed front strike")
 sim.raiders.clear()
 sim.mount_quest.unlocked=true;sim.mount_quest.riding=true
 game.knight.position.x=sim.world.sites.wall+300
 await step(game,3)
 key(KEY_D,true)
 for i: int in range(45):
  await step(game,1)
  if i%3==0:await shot(game,"horse-%02d"%i)
 key(KEY_D,false);await step(game,15);await shot(game,"horse-stop")
 check(game.knight.mounted and game.knight.velocity.x==0,"new mount returns to a planted stop")
 game.paused=true
 var region: Rect2=game.knight.visual.get_node("MountedKnight").texture.region
 await frames(5)
 check(game.knight.visual.get_node("MountedKnight").texture.region==region,"pause freezes mounted motion")
 game.queue_free();await frames(3)
 print("Defense scene: %d assertions; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
