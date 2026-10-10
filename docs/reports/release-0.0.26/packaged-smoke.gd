extends SceneTree
var assertions: int=0
var failures: int=0
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run_scene")
func check(value: bool,message: String) -> void:
 assertions+=1
 if value:print("PASS: "+message)
 else:failures+=1;push_error(message)
func frames(count: int) -> void:
 for tick: int in range(count):await physics_frame
func key(code: int,pressed: bool) -> void:
 var event: InputEventKey=InputEventKey.new()
 event.physical_keycode=code;event.keycode=code;event.pressed=pressed
 Input.parse_input_event(event);Input.flush_buffered_events()

## Real scene audio ownership; native mode also verifies actual playing voices.
const Menu: PackedScene=preload("res://scenes/start_menu.tscn")
const Prologue: Script=preload("res://presentation/campaign_prologue.gd")
var _settings_path: String=""

func _open_menu(muted: bool) -> Control:
 remove_meta("campaign_prologue_seen")
 _settings_path="user://test_prologue_audio_%d.cfg"%Time.get_ticks_usec()
 var settings: FileAccess=FileAccess.open(_settings_path,FileAccess.WRITE)
 settings.store_string("[audio]\nmusic=0.35\neffects=0.4\nambience=0.3\nmuted=%s\n"%str(muted));settings.close()
 var menu: Control=Menu.instantiate()
 menu.campaigns_directory="user://test_audio_no_records";menu.legacy_path=""
 menu.audio_preferences_path=_settings_path
 root.add_child(menu)
 return menu

func _movie(menu: Control) -> Control:
 for child: Node in menu.get_children():
  if child.get_script()==Prologue:return child
 return null

func _music_voices(node: Node) -> int:
 var count: int=0
 if node is AudioStreamPlayer and node.bus==&"Music" and node.playing:count+=1
 for child: Node in node.get_children():count+=_music_voices(child)
 return count

func _dispose(menu: Control) -> void:
 menu.queue_free();await frames(4)
 await create_timer(0.12).timeout
 DirAccess.remove_absolute(_settings_path)

func run_scene() -> void:
 check(not ResourceLoader.exists("res://tests/test_prologue_audio_scene.gd"),"running exported game content in isolation")
 var menu: Control=_open_menu(false)
 await create_timer(2.0).timeout
 var movie: Control=_movie(menu)
 check(is_instance_valid(movie) and not menu.view.visible,"opening movie owns the screen before the title")
 check(menu.audio.music.current.is_empty(),"title score stays silent while the prologue has its own score")
 check(is_equal_approx(movie.stage.game.audio.music_volume,0.35*0.55),"opening score follows saved music level with its cinematic mix")
 check(is_equal_approx(movie.stage.game.audio.effects_volume,0.4*0.5),"opening effects follow saved effects level")
 check(is_equal_approx(movie.stage.game.audio.ambience_volume,0.3),"opening ambience follows saved ambience level")
 if DisplayServer.get_name()!="headless":
  check(_music_voices(movie)>0,"native prologue still plays its scene score")
  check(_music_voices(menu.audio)==0,"native title score does not overlap the opening scene")
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(6)
 check(menu.view.visible and not is_instance_valid(movie),"real Escape input finishes the opening")
 check(menu.audio.music.current=="title","skipping the opening starts the title score")
 check(is_equal_approx(menu.audio.music.volume,0.35),"audio handoff preserves the saved music volume")
 await _dispose(menu)
 menu=_open_menu(false);await create_timer(1.8).timeout
 movie=_movie(menu);movie.stage.elapsed=24.98
 await frames(6)
 check(menu.view.visible and menu.audio.music.current=="title","natural movie completion also starts the title score")
 await _dispose(menu)
 menu=_open_menu(true);await create_timer(1.8).timeout
 movie=_movie(menu)
 check(not movie.stage.game.audio.enabled,"saved mute also silences the opening performance")
 check(_music_voices(movie)==0,"muted prologue has no playing music voice")
 var saved_preferences: String=FileAccess.get_file_as_string(_settings_path)
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(6)
 check(menu.view.visible and not menu.audio.enabled,"skipping the movie preserves the saved mute preference")
 check(menu.audio.music.current.is_empty() and _music_voices(menu.audio)==0,"muted title stays silent after the handoff")
 check(FileAccess.get_file_as_string(_settings_path)==saved_preferences,"watching and skipping never rewrite audio preferences")
 await _dispose(menu)
 print("Prologue audio assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
