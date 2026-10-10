extends SceneTree
const MENU: PackedScene=preload("res://scenes/start_menu.tscn")
const GAME: PackedScene=preload("res://scenes/frontier.tscn")
var samples: Array[Dictionary]=[]
func _initialize() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",false)
 call_deferred("run")
func frames(count: int) -> void:
 for tick: int in range(count):await physics_frame
func music_voices(node: Node) -> int:
 var total: int=0
 if node is AudioStreamPlayer and node.bus==&"Music" and node.playing:total+=1
 for child: Node in node.get_children():total+=music_voices(child)
 return total
func intro() -> void:
 var menu: Node=MENU.instantiate()
 menu.campaigns_directory="/tmp/cyber-audio-audit/no-saves";menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu);current_scene=menu
 await create_timer(2.0).timeout
 print("INTRO MUSIC VOICES: ",music_voices(menu),"; TITLE: ",music_voices(menu.get_node("TitleAudio")))
 menu.queue_free();await frames(4);await create_timer(0.15).timeout
func cycle() -> void:
 var menu: Node=MENU.instantiate()
 menu.campaigns_directory="/tmp/cyber-audio-audit/no-saves";menu.legacy_path="";menu.audio_preferences_path=""
 root.add_child(menu);current_scene=menu
 await create_timer(0.3).timeout
 menu.queue_free();await frames(4)
 var game: Node=GAME.instantiate()
 game.campaign_save_path="";game.audio_preferences_path=""
 root.add_child(game);current_scene=game
 await frames(4);game.set_physics_process(false)
 game.sim.interact(30,"hall")
 for tick: int in range(60):
  game.paused=false;game.audio.suspended=false
  game._physics_process(1.0/30)
  await physics_frame
 game.queue_free();await frames(4);await create_timer(0.15).timeout
func run() -> void:
 await intro()
 for i: int in range(9):
  await cycle()
  var entry: Dictionary={"cycle":i,"static_bytes":OS.get_static_memory_usage(),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)}
  samples.append(entry);print("SAMPLE ",JSON.stringify(entry))
 var output: String="/tmp/cyber-audio-cycle-before.json"
 if "--after" in OS.get_cmdline_user_args():output="/tmp/cyber-audio-cycle-after.json"
 var file: FileAccess=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(samples,"  "));file.close()
 print("CYCLE AUDIT COMPLETE");quit()
