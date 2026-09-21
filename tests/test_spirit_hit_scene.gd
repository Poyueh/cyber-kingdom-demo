extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false
 root.add_child(scene)
 await frames(8)
 scene.set_physics_process(false);scene.paused=false
 scene._physics_process(0.02)
 var guide=scene.hud.guide_view
 check(guide.visible and guide.spirit_pose.visible,"new campaign displays companion")
 scene.knight.position.x=-450
 scene.knight.get_node("Camera2D").force_update_scroll()
 scene._physics_process(0.1)
 check(guide.spirit_pose.direction>0,"ignoring camp instruction keeps pointing back toward camp")
 var screen: Vector2=scene.get_viewport().get_canvas_transform()*scene.knight.position
 check(guide.spirit_pose.position.distance_to(screen)<180,"companion stays beside the actual knight")
 check(scene.sim.frontier.city_level==0 and scene.sim.pouch.amount==12,"guidance cannot force payment or progress")
 var sim=scene.sim
 scene.knight.position=Vector2(30,430)
 sim.world.people.clear()
 var enemy=sim._spawn_raider();enemy.x=50.0
 enemy.windup=0.01;enemy.target={"kind":"hero","x":30.0};enemy.cooldown=9.0
 sim.raiders.append(enemy)
 scene.view.present(sim,30)
 scene._physics_process(0.02)
 check(sim.hero.hp<100 and scene.knight.visual.hurt_active,"actual enemy hit recoils the knight")
 var lean: float=scene.knight.visual.rotation
 scene.paused=true;scene._physics_process(0.2)
 check(scene.knight.visual.rotation==lean and not guide.visible,"pause freezes injury and hides companion")
 scene.paused=false;scene._physics_process(0.4)
 check(not scene.knight.visual.hurt_active,"knight returns to normal animation")
 sim.hero.shield=20;scene.knight.refresh_visual(0)
 enemy.windup=0.01;enemy.target={"kind":"hero","x":30.0};enemy.x=scene.knight.position.x+20
 var hp: int=sim.hero.hp
 scene._physics_process(0.02)
 check(sim.hero.hp==hp and sim.hero.shield<20 and scene.knight.visual.hurt_active,"shield blocks health loss while playing brace animation")
 sim.world.people.append({"role":"guard","x":60.0,"y":430.0,"hurt":0.0,"cooldown":9.0})
 scene.view.present(sim,30)
 enemy.windup=0.01;enemy.target={"kind":"person","index":0,"x":60.0};enemy.x=70.0
 scene._physics_process(0.02)
 check(sim.world.people[0].role=="wanderer" and scene.view.hit_feedback.resident_pose(0).active,"actual resident hit plays recoil before losing job silhouette")
 sim.world.people[0].role="hunter";sim.world.people[0].cooldown=0
 enemy.fighter.invulnerability_remaining=0
 sim._shoot_nearest_raider(sim.world.people[0],200,5,1)
 scene.view.present(sim,30)
 check(scene.view.hit_feedback.enemy_pose(enemy).active,"resident shot triggers enemy recoil")
 scene.restart();scene._physics_process(0.02)
 check(not scene.knight.visual.hurt_active and scene.view.hit_feedback.fallen.is_empty(),"restart clears all transient hit states")
 scene.queue_free();await process_frame
 print("Spirit and hit scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
