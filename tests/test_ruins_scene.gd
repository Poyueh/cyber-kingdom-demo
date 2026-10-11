extends "res://tests/test_mobile_scene.gd"
func run_scene() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 game.tuning=game.tuning.duplicate();game.tuning.larger_desktop_window=false
 root.add_child(game);await frames(8)
 game.set_physics_process(false)
 var site=game.sim.trials.sites[0]
 game.knight.position=Vector2(site.x,430)
 game._physics_process(1.0/30)
 check(not game.sim.modules.found.has(site.id),"real scene cannot pick up a sealed module")
 var amount: int=game.sim.pouch.amount
 for index: int in range(3):
  var station: int=site.order[index]
  game.knight.position=Vector2(site.positions[station],430)
  game._physics_process(1.0/30)
  if index==1:
   touch(12,Vector2(200,220),true);drag(12,Vector2(200,275));touch(12,Vector2(200,275),false)
  else:key(KEY_E,true);key(KEY_E,false)
  game._physics_process(1.0/30)
  check(site.progress==index+1,"keyboard or down-swipe activates the nearby rune once")
 check(game.sim.pouch.amount==amount,"rune gestures do not throw or charge a crystal")
 check(game.sim.effects.any(func(e):return e.kind=="ruin_open"),"finishing the circuit triggers the seal opening feedback")
 game.knight.position=Vector2(site.x,430);game._physics_process(1.0/30)
 check(game.sim.modules.equipped==site.id,"returning to the opened vault grants and equips the module")
 check(game.sim.trials.sites.size()==1,"forest now has one primary shrine")
 for relic: RefCounted in game.sim.modules.relics:
  if relic.id!="lance":continue
  game.knight.position=Vector2(relic.x,430);game._physics_process(1.0/30)
  check(game.sim.modules.found.has("lance"),"the second forest module rewards exploration without another relay")
 game.queue_free();await frames(2)
 print("Ruin scene assertions: %d; failures: %d"%[assertions,failures]);quit(0 if failures==0 else 1)
