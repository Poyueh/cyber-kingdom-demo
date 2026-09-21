extends "res://tests/test_mobile_scene.gd"
func run_scene() -> void:
 var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12
 root.add_child(scene)
 await frames(8)
 scene.knight.position.x=30
 await frames(2)
 scene.set_physics_process(false)
 scene.paused=false
 scene._physics_process(1.0/60)
 check(scene.has_node("CampaignAudio"),"campaign has a bounded audio player")
 var rack=scene.get_node("CampaignAudio")
 var heard: Array[String]=[]
 rack.cue_requested.connect(func(kind):heard.append(kind))
 check(rack.voices.size()==6,"at most six sound voices can overlap")
 for finger in range(2):
  preload("res://tests/touch_gesture.gd").start(root,finger)
  scene._physics_process(1.0/60)
  preload("res://tests/touch_gesture.gd").finish(root,finger)
  for i in range(6):scene._physics_process(1.0/60)
 check(heard.count("pay")==2 and heard.count("build")==1,"two real touch payments sound twice, camp completion once")
 var before=heard.size()
 for i in range(10):scene._physics_process(1.0/60)
 check(heard.size()==before,"lingering effects never retrigger audio")
 heard.clear()
 for i in range(100):
  await physics_frame
  if i%10==0:touch(3,center(scene.hud.get_node("attack")),true)
  scene._physics_process(1.0/60)
  if i%10==0:touch(3,center(scene.hud.get_node("attack")),false)
 check("slash1" in heard and "slash2" in heard and "slash3" in heard,"actual attack input produces all three distinct active-cut sounds")
 check(not scene.hud.audio_button.visible,"sound control adds no clutter during play")
 scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
 check(rack.voices.all(func(v):return not v.playing),"background notification immediately stops every voice")
 scene._physics_process(1.0/60)
 check(scene.hud.audio_button.visible and scene.hud.audio_button.text.is_empty(),"pause provides an icon-only sound control")
 touch(4,center(scene.hud.audio_button),true)
 touch(4,center(scene.hud.audio_button),false)
 check(not rack.enabled,"touching speaker mutes actual sound rack")
 scene.paused=false
 heard.clear()
 scene.sim.effects.append({"kind":"crystal_pickup","x":scene.knight.position.x,"life":0.25})
 scene._physics_process(1.0/60)
 check(heard.is_empty(),"muted gameplay produces no playback")
 rack.enabled=true
 scene._physics_process(1.0/60)
 check(heard.is_empty(),"unmuting never replays sounds that happened while muted")
 scene.restart()
 heard.clear()
 scene._physics_process(1.0/60)
 check(heard.is_empty(),"restart never sounds like historical build or currency gain")
 scene.queue_free()
 await frames(4)
 print("Audio scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
