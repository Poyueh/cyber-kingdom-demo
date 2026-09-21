extends RefCounted
## One telegraphed breath with a locked aim; walls shield people behind them.
static func advance(sim, dragon: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
 dragon.fighter.advance(seconds)
 if not dragon.fighter.is_alive():
  sim.mission.dragon_defeated=true
  return
 dragon.cooldown=maxf(0,dragon.cooldown-seconds)
 if dragon.windup>0:
  dragon.windup=maxf(0,dragon.windup-seconds)
  if dragon.windup==0:
   var aim: float=dragon.target.x
   var obstacle: Dictionary=sim._blocking_wall(dragon.x,aim)
   if not obstacle.is_empty():
    sim._hit_structure(obstacle,dragon.wall_damage)
   else:
    if absf(hero_x-aim)<100 and absf(hero_y-430)<48:sim.hit_hero(dragon.fighter.stats.damage,hero_x,hero_y)
    for i in range(sim.world.people.size()):
     var p: Dictionary=sim.world.people[i]
     if p.role!="wanderer" and absf(p.x-aim)<100 and absf(p.get("y",430)-430)<48:sim.world.hit_person(i)
    if absf(sim.world.sites.hall-aim)<100:sim.mission.damage_core(dragon.wall_damage)
   sim.effects.append({"kind":"dragon_fire","x":dragon.x,"to":aim,"life":0.7})
  return
 var target: Dictionary=sim._target(dragon,hero_x,hero_y)
 dragon.direction=signf(target.x-dragon.x) if absf(target.x-dragon.x)>1 else dragon.direction
 if absf(target.x-dragon.x)>110:
  dragon.x=move_toward(dragon.x,target.x,135*seconds)
 elif dragon.cooldown<=0:
  dragon.target=target.duplicate();dragon.windup=1.6;dragon.cooldown=4.4
