extends RefCounted
## Each dragon locks an attack footprint; subsequent beats cannot track new input.
static func advance(sim: RefCounted, dragon: Dictionary, seconds: float, hero_x: float, hero_y: float) -> void:
 dragon.fighter.advance(seconds)
 if not dragon.fighter.is_alive():sim.mission.dragon_defeated=true;return
 var profile: RefCounted=sim.planet.attack
 dragon.cooldown=maxf(0,dragon.cooldown-seconds)
 if dragon.windup>0:
  dragon.windup=maxf(0,dragon.windup-seconds)
  if dragon.windup==0:
   impact(sim,dragon,hero_x,hero_y)
   if sim.planet.volley+1<profile.beats:
    sim.planet.volley+=1
    var next_x: float=profile.next_aim(dragon.target.x,dragon.x,dragon.direction,sim.planet.volley)
    if profile.pattern==3:
     # The echo leaves its original mark while the real dragon slips away.
     sim.move_raider(dragon,dragon.target.x+dragon.direction*profile.spacing)
    dragon.target={"kind":"hero","x":clampf(next_x,sim.frontier.left_boundary+40,sim.frontier.right_boundary-40)}
    dragon.windup=profile.followup
   else:dragon.cooldown=profile.recovery
  return
 if dragon.cooldown>0:return
 var target: Dictionary=sim._target(dragon,hero_x,hero_y)
 if absf(target.x-dragon.x)>1:dragon.direction=signf(target.x-dragon.x)
 if absf(target.x-dragon.x)>profile.reach:
  sim.move_raider(dragon,move_toward(dragon.x,target.x,sim.raider_speed(dragon,profile.speed)*seconds))
 else:
  sim.planet.volley=0;dragon.target=target.duplicate();dragon.windup=profile.warning
static func impact(sim: RefCounted, dragon: Dictionary, hero_x: float, hero_y: float) -> void:
 var aim: float=dragon.target.x
 var radius: float=sim.planet.attack.radius
 var obstacle: Dictionary=sim._blocking_wall(dragon.x,aim)
 if not obstacle.is_empty():sim._hit_structure(obstacle,dragon.wall_damage)
 else:
  if absf(hero_x-aim)<radius and absf(hero_y-430)<48:sim.hit_hero(dragon.fighter.stats.damage,hero_x,hero_y)
  for i: int in range(sim.world.people.size()):
   var person: Dictionary=sim.world.people[i]
   if person.role!="wanderer" and absf(person.x-aim)<radius:sim.world.hit_person(i)
  if absf(sim.world.sites.hall-aim)<radius:sim.mission.damage_core(dragon.wall_damage)
 sim.effects.append({"kind":"planet_strike","x":aim,"life":0.85})
