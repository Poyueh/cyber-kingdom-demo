extends "res://tests/test_scene.gd"
func run_scene() -> void:
 ProjectSettings.set_setting("campaign/persistence_enabled",true)
 var path: String="/tmp/cyber45-muted.cfg"
 var settings: FileAccess=FileAccess.open(path,FileAccess.WRITE)
 settings.store_string("[audio]\nmusic=0.4\neffects=0.8\nambience=0.6\nmuted=true\n");settings.close()
 var game: Node=load("res://scenes/frontier.tscn").instantiate()
 game.campaign_save_path="";game.audio_preferences_path=path
 root.add_child(game);await frames(8);game.set_physics_process(false)
 check(not game.audio.enabled,"historical muted preference stays silent")
 check(game.hud.options_menu.music.value==0 and game.hud.options_menu.effects.value==0 and game.hud.options_menu.ambience.value==0,"sliders describe the actual muted state")
 game.hud.options_menu.effects.value=50
 check(game.audio.enabled and is_equal_approx(game.audio.effects_volume,0.5),"a real slider restores a historically muted journey")
 check(not game.preferences.read().muted,"restored sound is persisted for the next launch")
 game.queue_free();await frames(2);DirAccess.remove_absolute(path)
 print("Muted migration proof: %d checks, %d failures"%[assertions,failures]);quit(1 if failures else 0)
