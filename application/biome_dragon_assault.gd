extends RefCounted
## Sand rupture and a two-beat ice breath. Both lock their aim before damage;
## the existing wall query protects residents behind a completed wall.
static func advance(sim: RefCounted, dragon: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
 dragon.fighter.advance(seconds)
 if not dragon.fighter.is_alive():sim.mission.dragon_defeated=true;return
 dragon.cooldown=maxf(0,dragon.cooldown-seconds)
 if dragon.windup>0:
  dragon.windup=maxf(0,dragon.windup-seconds)
  if dragon.windup==0:
   impact(sim,dragon,hero_x,hero_y)
   if sim.planet.id==2 and sim.planet.volley==0:
    sim.planet.volley=1;dragon.windup=1.7
    dragon.target={"kind":"hero","x":clampf(dragon.target.x+dragon.direction*190,sim.frontier.left_boundary+40,sim.frontier.right_boundary-40)}
  return
 var target: Dictionary=sim._target(dragon,hero_x,hero_y)
 if absf(target.x-dragon.x)>1:dragon.direction=signf(target.x-dragon.x)
 var reach: float=300.0 if sim.planet.id==1 else 240.0
 if absf(target.x-dragon.x)>reach:
  sim.move_raider(dragon,move_toward(dragon.x,target.x,(100 if sim.planet.id==1 else 85)*seconds))
 elif dragon.cooldown<=0:
  sim.planet.volley=0;dragon.target=target.duplicate();dragon.windup=2.1 if sim.planet.id==1 else 1.9;dragon.cooldown=7.0 if sim.planet.id==1 else 8.5
static func impact(sim: RefCounted, dragon: Dictionary, hero_x: float, hero_y: float) -> void:
 var aim: float=dragon.target.x
 var radius: float=105.0 if sim.planet.id==1 else 85.0
 var obstacle: Dictionary=sim._blocking_wall(dragon.x,aim)
 if not obstacle.is_empty():sim._hit_structure(obstacle,dragon.wall_damage)
 else:
  if absf(hero_x-aim)<radius and absf(hero_y-430)<48:sim.hit_hero(dragon.fighter.stats.damage,hero_x,hero_y)
  for i: int in range(sim.world.people.size()):
   var person: Dictionary=sim.world.people[i]
   if person.role!="wanderer" and absf(person.x-aim)<radius:sim.world.hit_person(i)
  if absf(sim.world.sites.hall-aim)<radius:sim.mission.damage_core(dragon.wall_damage)
 sim.effects.append({"kind":"planet_strike","x":aim,"life":0.85})
