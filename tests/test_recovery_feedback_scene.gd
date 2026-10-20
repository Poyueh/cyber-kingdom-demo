extends "res://tests/test_scene.gd"
const STEP: float=1.0/30.0
func step(game: Node, count: int) -> void:
 for tick: int in range(count):
  game.paused=false
  game._physics_process(STEP)
  await physics_frame

func shot(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 RenderingServer.force_draw(false)
 DirAccess.make_dir_recursive_absolute("res://test-results/recovery-feedback")
 root.get_texture().get_image().save_png("res://test-results/recovery-feedback/"+name+".png")

func run_scene() -> void:
 for edition: String in ["full","demo"]:
  ProjectSettings.set_setting("distribution/edition",edition)
  ProjectSettings.set_setting("campaign/control_preview",2)
  var game: Node=load("res://scenes/frontier.tscn").instantiate()
  game._guided_campaign=true;game.campaign_save_path="";game.audio_preferences_path=""
  game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
  root.add_child(game);await frames(8);game.set_physics_process(false)
  game.sim.interact(game.sim.world.sites.hall,"hall");game.knight.position.x=game.sim.world.sites.hall
  await step(game,170)
  key(KEY_D,true);await step(game,5)
  var run: float=game.knight.velocity.x
  key(KEY_D,false);await step(game,2);key(KEY_D,true);await step(game,4)
  check(game.knight.velocity.x>run*1.5,edition+": real double-tap starts sprinting")
  game.sim.hero.stamina=0;await step(game,2)
  check(is_zero_approx(game.knight.velocity.x) and game.knight.visual.breathing,edition+": exhausted input stops in the breathing pose")
  var stopped_x: float=game.knight.position.x
  await step(game,40)
  check(is_equal_approx(game.knight.position.x,stopped_x) and is_zero_approx(game.sim.hero.stamina),edition+": held sprint cannot move or regenerate during breathing")
  await shot(edition+"-breathing")
  key(KEY_J,true);await step(game,1);key(KEY_J,false);await step(game,3)
  check(is_equal_approx(game.knight.position.x,stopped_x),edition+": free attack cannot step through the breathing stop")
  await step(game,35)
  check(game.knight.velocity.x>0 and game.knight.velocity.x<run*0.6 and not game.knight.visual.breathing,edition+": after breathing movement becomes slow walking")
  var bar: ProgressBar=game.hud.core_hud.stamina
  var recovering: float=bar.value
  check(bar.is_visible_in_tree() and recovering>0 and recovering<game.sim.hero.stats.max_stamina/3,edition+": walking recovery is visible below one third")
  await shot(edition+"-walking")
  await step(game,105)
  check(is_equal_approx(game.knight.velocity.x,run) and game.sim.travel.exhausted,edition+": one third restores running while sprint remains locked")
  await shot(edition+"-running")
  var resumed: bool=false
  for frame: int in range(230):
   await step(game,1)
   if game.knight.velocity.x>run*1.5:resumed=true;break
  check(resumed and not game.sim.travel.exhausted,edition+": reaching full rearms held sprint without another stop")
  await shot(edition+"-sprinting")
  key(KEY_D,false);await step(game,240)
  check(not bar.visible and is_equal_approx(game.sim.hero.stamina,game.sim.hero.stats.max_stamina),edition+": fully recovered bar retires after reaching full")
  game.queue_free();await frames(3)
 print("Recovery feedback scene: %d assertions; failures: %d"%[assertions,failures]);quit(1 if failures else 0)
