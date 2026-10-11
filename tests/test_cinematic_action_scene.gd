extends "res://tests/test_scene.gd"
## Run the real isolated performance continuously, observing actual simulation results.
func run_scene() -> void:
 var screen: SubViewport=SubViewport.new();screen.size=Vector2i(960,540);screen.world_2d=World2D.new();root.add_child(screen)
 var stage: Node=load("res://bootstrap/prologue_stage.gd").new();screen.add_child(stage)
 await frames(2);stage.set_physics_process(false)
 var construction: bool=false
 var sword_hit: bool=false
 var breath: bool=false
 var broken_wall: bool=false
 for tick: int in range(30*27):
  stage._physics_process(1.0/30)
  var sim: RefCounted=stage.game.sim
  construction=construction or sim.world.walls.wall.level>0
  for effect: Dictionary in sim.effects:
   sword_hit=sword_hit or (effect.kind=="hit" and effect.has("heavy"))
   breath=breath or effect.kind=="dragon_fire"
  broken_wall=broken_wall or (breath and sim.world.walls.wall.hp<=0)
 check(construction,"opening shows an engineer completing a real wall")
 check(sword_hit,"opening knight lands a real sword hit")
 check(breath,"opening dragon releases an actual breath attack")
 check(broken_wall,"dragon breath has a visible consequence on the constructed defense")
 check(stage.game.progress==null and stage.game.preferences==null,"directed actions cannot create saves or write preferences")
 screen.queue_free();await frames(3)
 print("Cinematic action assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
