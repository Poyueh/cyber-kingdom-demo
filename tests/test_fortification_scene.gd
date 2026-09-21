extends "res://tests/test_scene.gd"
func pay(scene) -> void:
 scene.hud.interact_button.button_down.emit()
 scene._physics_process(1.0/60)
 scene.hud.interact_button.button_up.emit()
 scene._physics_process(1.0/60)
func run_scene() -> void:
 var scene=load("res://scenes/frontier.tscn").instantiate();scene.tuning=scene.tuning.duplicate();scene.tuning.immersive_loop=false;scene.tuning.initial_crystals=12;root.add_child(scene)
 await frames(8)
 scene.set_physics_process(false);scene.paused=false
 var sim=scene.sim
 sim.frontier.city_level=3;sim.clock.is_night=true;sim.clock.remaining=100
 for id in ["wall","wall_left"]:sim.world.walls[id].merge({"level":1,"hp":40},true)
 sim.world.people.clear();sim.world.people.append({"role":"engineer","x":890.0,"y":430.0,"hurt":0.0,"cooldown":0.0,"region":-1})
 scene.knight.position=Vector2(890,430);scene._physics_process(0.01)
 check(scene.view._context.id=="tower","actual scene selects tower investment")
 for tier in range(1,4):
  sim.pouch.amount=12
  var cost: int=scene.view._context.cost
  for i in range(cost):pay(scene)
  check(sim.buildings.beacon.pending,"touch submits tower construction")
  scene.paused=true;scene._physics_process(4)
  check(sim.buildings.beacon.level==tier-1,"pause blocks construction")
  scene.paused=false
  for i in range(600):
   scene._physics_process(1.0/60)
   if sim.buildings.beacon.level==tier:break
  check(sim.buildings.beacon.level==tier,"resident builds tower tier at night through scene")
  await frames(2)
 var enemy=sim._spawn_raider();enemy.x=1200;sim.raiders.append(enemy);sim.buildings.beacon.cooldown=0
 var hp=enemy.fighter.hp;scene._physics_process(0.01);await frames(2)
 check(enemy.fighter.hp<hp and sim.effects.any(func(e):return e.kind=="tower_laser"),"scene renders a damaging laser")
 check(not scene.view._context.enabled,"max tier cannot buy another upgrade")
 scene.queue_free();await process_frame
 print("Fortification scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
