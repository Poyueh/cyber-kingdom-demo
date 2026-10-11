extends "res://tests/test_scene.gd"
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
