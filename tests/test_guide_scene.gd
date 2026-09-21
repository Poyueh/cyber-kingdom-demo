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
 var hud=scene.hud
 check(hud.guide_view.hint.kind=="camp" and hud.guide_view.can_invest,"opening guide highlights the actual enabled camp control")
 preload("res://tests/touch_gesture.gd").start(root,0)
 scene._physics_process(1.0/60)
 check(scene.sim.pouch.amount==11 and hud.guide_view.hint.kind=="camp","one paid slot does not falsely complete camp guidance")
 preload("res://tests/touch_gesture.gd").finish(root,0)
 scene._physics_process(1.0/60)
 preload("res://tests/touch_gesture.gd").start(root,1)
 scene._physics_process(1.0/60)
 preload("res://tests/touch_gesture.gd").finish(root,1)
 scene._physics_process(1.0/60)
 check(scene.sim.frontier.city_level==1 and hud.guide_view.hint.kind=="recruit","touch payment advances guidance after real construction")
 check(not hud.guide_view.can_invest,"guide does not highlight payment for a different nearby target")
 scene.paused=true
 scene._physics_process(1.0/60)
 check(not hud.guide_view.visible,"pause hides first-day overlay")
 scene.paused=false
 hud.first_day_guidance=false
 scene._physics_process(1.0/60)
 check(not hud.guide_view.visible,"Inspector can disable guidance without changing the run")
 hud.first_day_guidance=true
 scene.sim.mission.damage_core(scene.sim.mission.core_max_hp)
 scene._physics_process(1.0/60)
 check(not hud.guide_view.visible,"defeat removes advice and leaves retry controls")
 scene.queue_free()
 await process_frame
 print("Guide scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
