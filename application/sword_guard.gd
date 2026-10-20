extends RefCounted
static func advance(sim: RefCounted, person: Dictionary, seconds: float) -> void:
 var rules: Resource=sim.world.defense_rules
 var nearest: Dictionary={};var distance: float=rules.sword_reach
 for enemy: Dictionary in sim.raiders:
  if not enemy.fighter.is_alive():continue
  var reach: float=maxf(0,absf(enemy.x-person.x)-(70 if enemy.get("kind","")=="dragon" else 0))
  if reach<distance:nearest=enemy;distance=reach
 if nearest.is_empty():return
 if person.cooldown<=0:
  person.direction=signf(nearest.x-person.x)
  if person.hurt>0 or nearest.get("windup",0.0)>0:return
  person.cooldown=rules.sword_cycle
 elif person.cooldown<=rules.strike_remaining and person.cooldown+seconds>rules.strike_remaining:
  if (nearest.x-person.x)*person.get("direction",1.0)<0:return
  if nearest.fighter.take_damage(sim.attack_damage_against(nearest,rules.sword_damage)):
   sim.effects.append({"kind":"guard_slash","x":person.x,"y":person.get("y",430.0)-34,"to":nearest.x,"life":0.18})
static func bracing(sim: RefCounted, person: Dictionary) -> bool:
 return sim.raiders.any(func(e: Dictionary)->bool:return e.fighter.is_alive() and absf(e.x-person.x)<120 and (e.x-person.x)*person.get("direction",1.0)>=0 and e.get("windup",0.0)>0)
