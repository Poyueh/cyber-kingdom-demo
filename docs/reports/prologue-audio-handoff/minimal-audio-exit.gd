extends SceneTree
var voice: AudioStreamPlayer
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 voice=AudioStreamPlayer.new()
 voice.stream=load("res://art/audio/music-v002/title.ogg").duplicate()
 voice.stream.loop=true
 voice.volume_db=-50
 root.add_child(voice)
 voice.play()
 await create_timer(0.5).timeout
 print("MINIMAL AUDIO PLAYING: ",voice.playing)
 if "--drain-audio" in OS.get_cmdline_user_args():
  voice.stop();voice.queue_free()
  await create_timer(0.1).timeout
 print("MINIMAL EXIT")
 quit()
