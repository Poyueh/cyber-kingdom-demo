extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12;root.add_child(scene)
 await frames(8);scene.set_physics_process(false);scene.paused=false
 scene._physics_process(0.02)
 var enemy=scene.sim._spawn_raider();enemy.x=scene.knight.position.x+30
 scene.sim.raiders.append(enemy);scene.view.present(scene.sim,scene.knight.position.x)
 enemy.fighter.take_damage(99999);scene.sim.raiders.clear()
 scene.sim.hero.invulnerability_remaining=0;scene.sim.hero.take_damage(99999)
 scene._physics_process(0.05)
 check(scene.hud.dashboard.dead and not scene.hud.dashboard.victory,"hero death selects the failure overlay")
 check(scene.knight.visual.visible,"fatal hit keeps the knight visible")
 var world_clock=scene.sim.workforce.elapsed
 var drawing: int=scene.knight.visual.frame
 scene._physics_process(0.4)
 check(scene.knight.visual.animation==&"death" and scene.knight.visual.frame>drawing,"authored death keeps animating after campaign stops")
 check(scene.sim.workforce.elapsed==world_clock,"no time or economy advances during death animation")
 check(scene.view.hit_feedback.fallen.size()==1,"enemy death remains visible after terminal hit")
 scene.paused=true;drawing=scene.knight.visual.frame
 var body_age=scene.view.hit_feedback.fallen[0].age
 scene._physics_process(0.5)
 check(scene.knight.visual.frame==drawing and scene.view.hit_feedback.fallen[0].age==body_age,"manual pause freezes all terminal animation")
 scene.paused=false;scene._physics_process(1.3)
 check(scene.view.hit_feedback.fallen.is_empty() and scene.knight.visual.visible,"enemy dissolves while hero corpse remains")
 scene.restart();scene._physics_process(0.01)
 check(not scene.hud.dashboard.dead and is_zero_approx(scene.knight.visual.rotation),"new journey resets outcome and corpse")
 scene.sim.mission.core_hp=0;scene._physics_process(0.01)
 check(scene.hud.dashboard.dead and scene.hud.dashboard.values.defeat_reason=="core","core defeat retains a distinct failure reason")
 scene.restart();scene._physics_process(0.01)
 scene.sim.mission.outcome="victory";scene._physics_process(0.01)
 check(scene.hud.dashboard.victory and not scene.hud.dashboard.dead,"victory chooses crown instead of skull")
 check(not scene.view.interactions_visible and not scene.hud.guide_view.visible,"outcome dismisses interactive hints")
 scene.queue_free();await process_frame
 print("Clear feedback scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
