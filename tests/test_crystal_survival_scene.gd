extends "res://tests/test_scene.gd"
func run_scene() -> void:
 var game=load("res://scenes/frontier.tscn").instantiate()
 root.add_child(game);await frames(10)
 game.knight.position=Vector2(800,430);game.sim.world.people.clear();await frames(4)
 var purse=game.hud.immersive_feedback.purse
 await frames(230)
 check(purse.modulate.a<0.01,"idle crystal purse fades completely out")
 key(KEY_Q,true);await frames(2);key(KEY_Q,false);await frames(2)
 check(purse.modulate.a>0.9 and not purse._flights.is_empty(),"throwing crystal reveals purse and animates removal")
 game.sim.pouch.drops.clear()
 game.sim.pouch.drop(1,game.knight.position.x);await frames(4)
 check(purse._flights.any(func(f):return f.incoming),"actual ground pickup animates crystal entering bag")
 game.sim.interact(30,"hall");game.sim.pouch.amount=0
 var enemy: Dictionary=game.sim._spawn_raider()
 enemy.x=game.knight.position.x+20;enemy.side=1;enemy.windup=0.001;enemy.target={"kind":"hero","x":game.knight.position.x}
 game.sim.raiders.append(enemy);await frames(4)
 check(game.sim.survival.sword_on_ground and not game.sim.can_wield_sword(),"real scene attack drops sword")
 check(game.knight.visual.unarmed and game.knight.visual.hurt_active,"disarmed knight retains visible hit reaction")
 check(game.knight.visual.self_modulate.a==0,"disarm does not reintroduce overlapping armed body")
 game.sim.raiders.clear()
 game.knight.position.x=game.sim.survival.sword_x;await frames(85)
 check(game.sim.can_wield_sword() and not game.knight.visual.unarmed,"walking back to sword restores armed appearance")
 game.queue_free();await process_frame
 print("Crystal survival scene assertions: %d; failures: %d"%[assertions,failures])
 quit(0 if failures==0 else 1)
