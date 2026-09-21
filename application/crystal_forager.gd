extends RefCounted
## Small raiders prefer an exposed nearby crystal, then carry it to their origin.
const SEEK_RADIUS: float=150.0
const PICKUP_RADIUS: float=24.0
const RETREAT_SPEED: float=105.0

static func advance(sim: RefCounted, enemy: Dictionary, seconds: float) -> bool:
 var held: int=int(enemy.get("carried_crystals",0))
 if not enemy.fighter.is_alive():
  if held>0:sim.pouch.burst(held,enemy.x);enemy.carried_crystals=0
  return false
 if enemy.get("kind","") in ["dragon","warden"]:return false
 if held==0:
  var gem: Dictionary={}
  var distance: float=SEEK_RADIUS
  for drop in sim.pouch.drops:
   if drop.amount<=0 or drop.age<0.15 or absf(drop.y-430)>22:continue
   if absf(drop.x-enemy.x)>=distance or not sim._blocking_wall(enemy.x,drop.x).is_empty():continue
   distance=absf(drop.x-enemy.x);gem=drop
  if gem.is_empty():return false
  enemy.fighter.advance(seconds)
  enemy.windup=0.0;enemy.target={};enemy.cooldown=maxf(0,enemy.cooldown-seconds)
  if float(enemy.get("stagger",0))>0:
   enemy.stagger=maxf(0,enemy.stagger-seconds);return true
  enemy.direction=signf(gem.x-enemy.x) if distance>1 else enemy.get("direction",-1.0)
  enemy.x=move_toward(enemy.x,gem.x,70*seconds)
  if absf(gem.x-enemy.x)<=PICKUP_RADIUS:
   gem.amount-=1;enemy["carried_crystals"]=1
   enemy["retreat_x"]=sim.mission.entry_x(int(enemy.get("side",1)))
   sim.pouch.drops=sim.pouch.drops.filter(func(item):return item.amount>0)
  return true
 enemy.fighter.advance(seconds)
 enemy.windup=0.0;enemy.target={}
 if float(enemy.get("stagger",0))>0:
  enemy.stagger=maxf(0,enemy.stagger-seconds);return true
 var destination: float=enemy.retreat_x
 enemy.direction=signf(destination-enemy.x)
 enemy.x=move_toward(enemy.x,destination,RETREAT_SPEED*seconds)
 if absf(enemy.x-destination)<10:
  enemy.fighter.hp=0;enemy["escaped"]=true;enemy.carried_crystals=0
  sim.effects.append({"kind":"portal_spawn","x":destination,"y":430.0,"life":0.6})
 return true
