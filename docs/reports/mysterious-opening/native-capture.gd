extends "res://tests/test_scene.gd"
const Menu: PackedScene=preload("res://scenes/start_menu.tscn")
const Movie: Script=preload("res://presentation/campaign_prologue.gd")
var out: String="/tmp/cyber-title-captures-final"
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run_scene() -> void:
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1152,648)
 if has_meta("campaign_prologue_seen"):remove_meta("campaign_prologue_seen")
 var menu: Control=Menu.instantiate()
 menu.campaigns_directory="user://title_native_test";menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu);await frames(4)
 var cinema: Control
 for child: Node in menu.get_children():
  if child.get_script()==Movie:cinema=child
 for moment: float in [1.5,4.3,6.2,8.8,10.5,12.5,16.5,18.0]:
  while is_instance_valid(cinema) and cinema.stage.elapsed<moment:await physics_frame
  await capture("shot-%04.1f"%moment)
 while is_instance_valid(cinema):await physics_frame
 await create_timer(1.0).timeout;await capture("menu-natural")
 check(menu.view.visible,"natural opening reveals the menu")
 for locale: String in ["zh_TW","zh_CN","en"]:
  TranslationServer.set_locale(locale);menu.view._refresh_language();await frames(4)
  await capture("menu-"+locale)
  menu.view.new_button.pressed.emit();await frames(4);await capture("pace-"+locale)
  var chooser: Control=menu.view.pace_picker
  check(chooser.get_global_rect().end.y<=menu.view.size.y,"pace controls fit: "+locale)
  chooser.back.pressed.emit();await frames(3)
  menu.show_records();await frames(3);await capture("records-"+locale)
  menu.view.back_button.pressed.emit();await frames(3)
  check(menu.catalog.entries().is_empty(),"menu exploration never allocates a journey: "+locale)
 check(menu.view.replay_button.get_global_rect().end.y<=menu.view.size.y,"replay button stays on screen")
 menu.queue_free();await frames(3)
 print("Title native assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
