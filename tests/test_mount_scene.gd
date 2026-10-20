extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12;root.add_child(scene)
 await frames(8);scene.set_physics_process(false)
 check(not scene.knight.mounted,"new knight begins on foot")
 check(scene.knight.get_node("Camera2D").limit_left<=scene.sim.frontier.left_boundary-80 and scene.knight.get_node("Camera2D").limit_right>=scene.sim.frontier.right_boundary+80,"camera keeps whole mounted silhouette inside both map ends")
 scene.sim.frontier.drill_level=scene.sim.frontier.training_limit
 scene._physics_process(1.0/60)
 check(not scene.knight.mounted,"maximum sword without armor stays on foot")
 scene.sim.growth.capacitor_level=scene.sim.growth.capacitor_limit
 scene._physics_process(1.0/60)
 check(scene.knight.mounted and scene.knight.visual.mounted,"both top equipment tiers mount knight")
 scene.knight.advance_motion(1,false,1.0/60)
 check(is_equal_approx(scene.knight.velocity.x,scene.knight.tuning.move_speed*1.25),"mount increases actual travel speed")
 scene.sim.hero.start_attack();scene.knight.advance_motion(1,false,1.0/60)
 check(scene.knight.velocity.x==0,"mounted first slash still roots movement")
 scene.knight.refresh_visual(0.05)
 check(scene.knight.visual.get_node("MountedKnight").visible,"mounted attack retains horse and rider")
 var visual: Node=scene.knight.visual
 visual.breathing=true
 var rest_pose: Dictionary={"alive":true,"hp":100,"shield":0,"facing":1,"moving":false,"grounded":true,"invulnerable":false,"attack_progress":1.0}
 visual.present(rest_pose,1.0)
 check(visual.fatigue.texture.atlas==visual.get_node("MountedKnight").texture.atlas,"resting on horseback retains the same rider and horse artwork")
 check(visual.fatigue.material==visual.get_node("MountedKnight").material,"mounted rest preserves the rider and horse palette")
 visual.breathing=false
 var gallop: Dictionary={"alive":true,"hp":100,"shield":0,"facing":1,"moving":true,"grounded":true,"invulnerable":false,"attack_progress":1.0,"horizontal_speed":402.0}
 visual.reset_pose();visual.set_mounted(true)
 var previous_frame: int=-1
 var skipped: int=0
 for sample: int in range(90):
  visual.present(gallop,1.0/30)
  var index: int=roundi(visual.get_node("MountedKnight").texture.region.position.x/160)
  if previous_frame>=0 and posmod(index-previous_frame,8)>1:skipped+=1
  previous_frame=index
 check(skipped==0,"sprinting horse displays every gait pose even at phone 30 fps")
 var held_region: Rect2=visual.get_node("MountedKnight").texture.region
 visual.present(gallop,0.0)
 check(visual.get_node("MountedKnight").texture.region==held_region,"paused presentation cannot advance a horse stride")
 var config: Dictionary=scene._campaign_config
 var packet=load("res://application/campaign_snapshot.gd").new().capture(scene.sim,config,{"x":scene.knight.position.x,"y":scene.knight.position.y,"vx":scene.knight.velocity.x,"vy":scene.knight.velocity.y})
 var restored=load("res://application/campaign_snapshot.gd").new().restore(packet)
 check(not restored.is_empty(),"upgraded run still round-trips through existing checkpoint schema")
 if not restored.is_empty():
  scene._apply_restored(restored)
  check(scene.knight.mounted,"loading upgraded run restores riding from equipment")
 scene.restart()
 check(not scene.knight.mounted,"new journey clears prior mount")
 scene.queue_free();await process_frame
 print("Mount scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
