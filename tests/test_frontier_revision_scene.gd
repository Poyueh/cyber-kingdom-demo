extends "res://tests/test_scene.gd"
const STEP: float=1.0/30.0
var edition: String="full" if "--sword-main" in OS.get_cmdline_user_args() else "demo"
func step(game: Node, count: int) -> void:
 for tick: int in range(count):
  if not game.hud.core_hud.panel.visible:game.paused=false
  game._physics_process(STEP)
  await physics_frame
func shot(game: Node, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 game.view.queue_redraw();RenderingServer.force_draw(false)
 DirAccess.make_dir_recursive_absolute("res://test-results/sword-"+edition)
 root.get_texture().get_image().save_png("res://test-results/sword-"+edition+"/"+name+".png")
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
 sim.clock.survived=2;sim.clock.day=3;sim.pouch.amount=30
 sim.command.used.assign(preload("res://application/feature_lessons.gd").IDS)
 for region: Dictionary in sim.frontier.regions:region.discovered=true
 for id: String in ["wall","wall_left"]:sim.world.walls[id].level=1;sim.world.walls[id].hp=40
 for node: RefCounted in sim.frontier.nodes:
  if absf(node.x)<1100:node.collected=true;node.delivered=true
 for person: Dictionary in sim.world.people:person.role="guard"
 for side: int in [-1,1]:
  game.knight.position.x=sim.command.barracks_x(side)
  await step(game,12);await shot(game,"barracks-%d"%side)
  check(sim.context(game.knight.position.x).id=="sword_station","barracks owns the local interaction on each side")
  key(KEY_E,true);await step(game,2);key(KEY_E,false);await frames(2)
  var hud: Control=game.hud.core_hud
  check(game.paused and hud.panel.visible and hud.order_role=="guard","E opens the actual sword orders panel")
  await step(game,1)
  check(hud.row_nodes.sword_left.visible and not hud.row_nodes.beacon.visible,"shield orders offer ground walls and hide towers")
  var before: int=sim.pouch.amount
  var target: String="sword_left" if side<0 else "sword_right"
  hud.row_buttons[target][1].pressed.emit();await step(game,1)
  check(sim.core_loop.orders.targets.has(target) and sim.pouch.amount==before-1,"the actual panel posts a swordsman for one crystal")
  await shot(game,"orders-%d"%side)
  hud.row_buttons[target][0].pressed.emit();await step(game,1)
  check(not sim.core_loop.orders.targets.has(target) and sim.pouch.amount==before-1,"actual panel releases the soldier for free")
  var stock: int=sim.world.tools.blade
  var money: int=sim.pouch.amount
  hud.sword_button.pressed.emit();await step(game,1)
  check(sim.world.tools.blade==stock+1 and sim.pouch.amount==money-sim.prices.armory,"barracks gear button stocks real equipment at its displayed price")
  hud.panel.hide();hud.orders_toggled.emit(false)
 game.queue_free();await frames(3)
 print("Sword defense scene: %d assertions; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
