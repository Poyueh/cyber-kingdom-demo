extends SceneTree
## Real native scene, isolated from player records. Review motion at normal playback speed.
var game: Node
var output: String="/tmp/cyber-companion59"
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(output)
 game=load("res://scenes/frontier.tscn").instantiate()
 game._core_trial=true;game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game)
 for unused: int in range(10):await process_frame
 game.set_physics_process(false)
 var narrow: bool="--touch-layout" in OS.get_cmdline_user_args()
 if narrow:
  output="/tmp/cyber-companion59-touch";DirAccess.make_dir_recursive_absolute(output)
  root.size=Vector2i(960,450);root.content_scale_size=Vector2i(960,450)
 game.hud.control_mode=1 if narrow else 2
 game.sim.clock.remaining=10000
 game.knight.position.x=game.sim.world.sites.hall-450
 if "--manual" in OS.get_cmdline_user_args():
  game.set_physics_process(true);return
 for tick: int in range(600):
  if tick==0:input_key(KEY_D,true)
  if tick==90:input_key(KEY_D,false)
  if tick==185:input_key(KEY_A,true)
  if tick==215:input_key(KEY_A,false)
  if tick==245:input_key(KEY_D,true)
  if tick==335:input_key(KEY_D,false)
  if tick==360:
   game.knight.position.x=game.sim.world.sites.hall
   input_key(KEY_E,true)
  if tick==361:input_key(KEY_E,false)
  game._physics_process(1.0/30)
  await process_frame
  await RenderingServer.frame_post_draw
  if tick%3==0:root.get_texture().get_image().save_png(output.path_join("frame-%03d.png"%(tick/3)))
  if tick in [70,170,230,345,470,590]:
   print("VISUAL ",tick," ",game.hud.guide_view.spirit_pose," caption=",game.hud.guide_view._guide_label.visible)
 game.queue_free();await process_frame;quit()
func input_key(code: int, down: bool) -> void:
 var event: InputEventKey=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down
 Input.parse_input_event(event);Input.flush_buffered_events()
