extends SceneTree
## Exercise actual physics, InputMap, scene wiring and persistence together.
var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
 ProjectSettings.set_setting("campaign/control_preview",1)
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run_scene")

func check(value: bool, description: String) -> void:
 assertions += 1
 if not value:
  failures += 1
  printerr("FAIL: " + description)
 else:
  print("PASS: " + description)

func key(code: int, down: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func frames(count: int) -> void:
 for unused in range(count):
  await physics_frame


const Menu: PackedScene=preload("res://scenes/start_menu.tscn")
const Prologue: Script=preload("res://presentation/campaign_prologue.gd")
func movie(menu: Node) -> Control:
 for child: Node in menu.get_children():
  if child.get_script()==Prologue:return child
 return null
func run_scene() -> void:
 set_meta("campaign_prologue_seen",true)
 var menu: Control=Menu.instantiate()
 menu.campaigns_directory="user://test_title_replay_%d"%Time.get_ticks_usec()
 menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu);await frames(4)
 check(menu.view.has_signal("prologue_requested"),"title offers a replay without starting a journey")
 if not menu.view.has_signal("prologue_requested"):quit(1);return
 for repeat: int in range(2):
  menu.view.replay_button.pressed.emit();await frames(4)
  var cinema: Control=movie(menu)
  check(cinema!=null and not menu.view.visible,"replay opens one isolated performance")
  check(menu.audio.suspended,"replay suspends the title score")
  check(menu.catalog.entries().is_empty(),"replay never allocates a player save")
  menu.view.replay_button.pressed.emit();await frames(2)
  var movies: int=0
  for child: Node in menu.get_children():
   if child.get_script()==Prologue:movies+=1
  check(movies==1,"duplicate replay requests cannot create overlapping performances")
  key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(6)
  check(menu.view.visible and movie(menu)==null and not menu.audio.suspended,"Escape returns to the same menu and audio owner")
  check(not menu.view.pace_picker.visible and menu.catalog.entries().is_empty(),"skip input never starts a journey or opens pace selection")
 menu.queue_free();await frames(4)
 print("Title replay scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
