extends "res://tests/test_scene.gd"
const Codec=preload("res://application/campaign_snapshot.gd")
var game: Node
func step(count: int) -> void:
 for tick: int in range(count):game._physics_process(1.0/30)
func place(x: float) -> void:
 game.knight.position=Vector2(x,430);game.knight.velocity=Vector2.ZERO
 step(1)
func capture(label: String) -> void:
 game.knight.get_node("Camera2D").reset_smoothing();game.knight.get_node("Camera2D").force_update_scroll()
 await frames(2)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("/tmp/cyber-attendants-native")
 root.get_texture().get_image().save_png("/tmp/cyber-attendants-native/"+label+".png")
func run_scene() -> void:
 game=load("res://scenes/frontier.tscn").instantiate();game.campaign_save_path="";game.audio_preferences_path=""
 game._map_seed=617;game._seed_initialized=true
 root.add_child(game);await frames(10);game.set_physics_process(false);game.knight.set_physics_process(false)
 var attendants: RefCounted=game.view.get("_attendants")
 check(attendants!=null,"campaign scene wires a persistent facility animation presenter")
 if attendants==null:
  game.queue_free();await frames(2);quit(1);return
 game.sim.frontier.city_level=3;game.sim.survival.armed=true;game.sim.pouch.amount=30
 game.sim.spirit.opening_finished=true;game.sim.spirit.expires_tick=0
 for region: Dictionary in game.sim.frontier.regions:region.discovered=true
 for site: String in ["workshop","farm_tools","hunt_tools","armory"]:game.sim.built[site]=true
 # The artificer's workshop appears only once a module has been found: claim one the normal way.
 for shrine: RefCounted in game.sim.trials.sites:
  for station: int in shrine.order:
   game.sim.advance(0.1,shrine.positions[station])
   game.sim.interact(shrine.positions[station],"trial:%s:%d"%[shrine.id,station])
 game.sim.advance(0.1,game.sim.modules.relics[0].x)
 check(not game.sim.modules.found.is_empty(),"a module is found before visiting the artificer")
 var body: Dictionary={"x":0.0,"y":430.0,"vx":0.0,"vy":0.0}
 place(2000);step(10)
 var before: Dictionary=Codec.new().capture(game.sim,game._campaign_config,body)
 for index: int in range(6):
  var site: StringName=attendants.Cast.sites[index]
  var x: float=game.sim.world.sites[site]+attendants.Cast.offsets[index].x
  place(x-70);step(10)
  var state: RefCounted=attendants.states[index]
  check(state.mode==1,"approaching "+site+" triggers a brief greeting")
  var facing: float=state.facing
  place(x+2);step(1)
  check(state.facing==facing,"greeting locks facing instead of flipping at the player's feet")
  await capture(str(site)+"-greeting")
  step(80)
  check(state.mode==0,"lingering at "+site+" lets the keeper resume work")
  var work_age: float=state.work_age
  game.paused=true;step(30)
  check(state.work_age==work_age,"pause freezes the actual facility work pose")
  game.paused=false
  place(x+120);step(10);place(x+100);step(10)
  check(state.mode==0,"hovering across the approach threshold does not repeat greetings")
  place(x+210);step(270);place(x-70);step(10)
  check(state.mode==1,"leaving and returning later rearms the greeting")
  step(80);await capture(str(site)+"-work")
  if DisplayServer.get_name()!="headless":
   for frame: int in range(20):
    step(8);await capture(str(site)+"-cycle-%02d"%frame)
 place(game.sim.world.sites.workshop);step(60)
 var mechanic: RefCounted=attendants.states[1]
 var stock: int=game.sim.world.tools.hammer
 var money: int=game.sim.pouch.amount
 key(KEY_E,true);step(1);key(KEY_E,false);step(1)
 check(mechanic.mode==2 and game.sim.pouch.amount==money-1,"ordinary E investment gets a short acknowledgement")
 key(KEY_E,true);step(1);key(KEY_E,false);step(1)
 check(mechanic.mode==3 and game.sim.world.tools.hammer==stock+1,"completed paid production gets its own service animation")
 step(12);await capture("mechanic-service")
 var age: float=mechanic.age
 game.view.present(game.sim,game.knight.position.x)
 check(mechanic.age==age,"redrawing a paused clock does not replay service")
 var frozen: Dictionary=Codec.new().capture(game.sim,game._campaign_config,body)
 for count: int in range(20):game.view.present(game.sim,game.knight.position.x)
 check(Codec.new().capture(game.sim,game._campaign_config,body)==frozen,"animation and proximity observations never mutate saved economy or population")
 var restored: Dictionary=Codec.new().restore(frozen)
 check(not restored.is_empty(),"facility interaction remains a valid v20 checkpoint")
 # Real living enemy objects, already created by the scene's encounter flow.
 var enemy: Dictionary={}
 if not game.sim.raiders.is_empty():enemy=game.sim.raiders[0]
 check(not enemy.is_empty(),"danger scenario has an actual living local creature")
 if not enemy.is_empty():
  var old_x: float=enemy.x
  enemy.x=game.sim.world.sites.workshop+100
  game.view.present(game.sim,game.knight.position.x)
  check(mechanic.mode==4 and mechanic.visible,"nearby danger interrupts work without deleting the NPC")
  await capture("mechanic-alert")
  enemy.x=old_x;step(90)
  check(mechanic.mode==0,"keeper waits for safety before returning to work")
 check(before.session.keys()==frozen.session.keys(),"presentation adds no campaign save fields")
 # A fresh saved campaign must not inherit the prior scene's service or greeting.
 game.sim=restored.session;game._campaign_config=restored.config
 game.view.present(game.sim,game.knight.position.x)
 check(attendants.states.size()==6 and attendants.states.all(func(s: RefCounted)->bool:return s.mode==0),"loading a saved scene clears transient service without replay")
 # Reuse the normal shrine and discovery flow before the existing F menu.
 for shrine: RefCounted in game.sim.trials.sites:
  for station: int in shrine.order:
   game.sim.advance(0.1,shrine.positions[station])
   game.sim.interact(shrine.positions[station],"trial:%s:%d"%[shrine.id,station])
 for relic: RefCounted in game.sim.modules.relics:game.sim.advance(0.1,relic.x)
 game.sim.pouch.amount=20
 place(game.sim.world.sites.drill);step(2)
 key(KEY_F,true);key(KEY_F,false);step(1)
 check(game.paused and game.hud.module_menu.visible,"existing module menu opens at the artificer")
 game.hud.module_menu._buttons[0].pressed.emit()
 game.hud.module_menu._close.pressed.emit();step(1)
 check(attendants.states[4].mode==3 and game.sim.pouch.amount==12,"actual paid module swap cues the artificer's calibration")
 step(12);await capture("artificer-service")
 game.view.cinematic=true;game.view.present(game.sim,game.knight.position.x)
 check(attendants.states.all(func(s: RefCounted)->bool:return s.mode==0),"cinematic staging suppresses player-service reactions")
 game.queue_free();await frames(2)
 print("Attendant native scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
