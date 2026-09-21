extends RefCounted
## New campaign rules; legacy runs keep their saved rules until a new journey.
var enabled: bool = false
const CARRY_LIMIT: int = 12
const COLLECT_RADIUS: float = 28.0
const SEEK_RADIUS: float = 110.0
const OFFER_RADIUS: float = 70.0
const THREAT_RADIUS: float = 240.0

func threatened(person: Dictionary, enemies: Array) -> bool:
 for enemy in enemies:
  if enemy.fighter.is_alive() and absf(enemy.x-person.x)<THREAT_RADIUS:return true
 return false

func collect(world, pouch, enemies: Array, hero_x: float, hero_y: float) -> void:
 for person in world.people:
  var held: int=int(person.get("crystals",0))
  if person.role=="wanderer" and person.hurt>0:
   if held>0:pouch.burst(held,person.x);person["crystals"]=0
   continue
  if threatened(person,enemies):continue
  if person.role!="wanderer" and held>0 and absf(person.x-hero_x)<OFFER_RADIUS and absf(hero_y-430)<40:
   pouch.burst(held,person.x)
   person["crystals"]=0
   continue
  if person.role!="wanderer" and absf(person.x-hero_x)<OFFER_RADIUS:continue
  for gem in pouch.drops:
   if gem.amount<=0 or gem.grace>0 or absf(gem.x-person.x)>COLLECT_RADIUS or absf(gem.y-430)>20:continue
   if person.role=="wanderer":
    gem.amount-=1;person.role="citizen"
    break
   var count: int=mini(gem.amount,CARRY_LIMIT-held)
   gem.amount-=count;held+=count;person["crystals"]=held
   if held>=CARRY_LIMIT:break
 pouch.drops=pouch.drops.filter(func(gem):return gem.amount>0)

func crystal_target(person: Dictionary, pouch, hero_x: float) -> float:
 if person.hurt>0 or int(person.get("crystals",0))>=CARRY_LIMIT:return NAN
 if person.role!="wanderer" and absf(person.x-hero_x)<OFFER_RADIUS:return NAN
 var target: float=NAN
 var distance: float=SEEK_RADIUS
 for gem in pouch.drops:
  if gem.amount>0 and gem.grace<=0 and absf(gem.y-430)<20 and absf(gem.x-person.x)<distance:
   target=gem.x;distance=absf(gem.x-person.x)
 return target
