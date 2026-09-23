extends SceneTree
## Proves the v002 music, ambience and effects reach a real mixer. Headless skips
## playback by design, so this must run with native audio.
var scene
var recorder: AudioEffectRecord
var heard: Array[String]=[]
var _playing:=false

func _initialize() -> void:
	ProjectSettings.set_setting("campaign/persistence_enabled",false)
	call_deferred("capture")
	call_deferred("watchdog")

func watchdog() -> void:
	await create_timer(90.0).timeout
	printerr("capture did not finish in time")
	quit(1)

func step(count: int) -> void:
	for i in range(count):
		await physics_frame
		# An automated window has no focus, which both pauses and suspends the game.
		# Neither is what this capture is testing.
		if scene != null and is_instance_valid(scene) and scene.audio != null:
			scene.audio.suspended=false
			if _playing: scene.paused=false

func capture() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Use native audio for capture")
		quit(1);return
	scene=load("res://scenes/frontier.tscn").instantiate()
	root.add_child(scene)
	await step(12)
	_playing=true
	scene.paused=false
	scene.audio.cue_requested.connect(func(kind):heard.append(kind))
	recorder=AudioEffectRecord.new()
	var slot:=AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	await step(200)
	scene.sim.clock.is_night=true
	await step(120)
	recorder.set_recording_active(false)
	var sound=recorder.get_recording()
	AudioServer.remove_bus_effect(0,slot)
	print("MUSIC %s LAYER %s" % [scene.audio.music.current,scene.audio.music.layer])
	print("AMBIENCE %s" % [scene.audio.ambience.levels])
	print("EFFECTS %s" % [heard])
	if sound==null or sound.data.size()<1000:
		printerr("no audio was recorded")
		quit(1);return
	print("SAVED %s" % [sound.save_to_wav("/tmp/campaign-audio-v002.wav")==OK])
	scene.queue_free()
	await step(3)
	quit(0)
