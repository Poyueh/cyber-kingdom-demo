extends RefCounted
## Crystal reserve, then sword, then life. No rendering or scene dependencies.
var enabled: bool=false
var hit_loss: int=0
var armed: bool=false
var sword_on_ground: bool=false
var sword_x: float=0.0
var sword_grace: float=0.0
var hits: int=0

func receive_hit(hero: RefCounted, pouch: RefCounted, damage: int, x: float, y: float) -> bool:
 if not enabled:return hero.take_damage(damage)
 if damage<=0 or not hero.is_alive() or hero.invulnerability_remaining>0:return false
 var protected: bool=pouch.amount>0 or armed
 # Reuse combat cancellation and hit immunity; HP only records alive/dead here.
 if not hero.take_damage(1):return false
 hits+=1
 if protected:hero.hp=hero.stats.max_hp
 else:hero.hp=0
 if pouch.amount>0:
  var lost: int=mini(pouch.amount,hit_loss)
  pouch.amount-=lost
  pouch.burst(lost,x,y)
 elif armed:
  armed=false;sword_on_ground=true;sword_grace=1.2
  sword_x=clampf(x-hero.facing*70,pouch.left_boundary+12,pouch.right_boundary-12)
 return true

func advance(seconds: float, hero: RefCounted, x: float, y: float) -> bool:
 sword_grace=maxf(0,sword_grace-seconds)
 if not enabled or not hero.is_alive() or not sword_on_ground or sword_grace>0:return false
 if absf(x-sword_x)>24 or absf(y-430)>32:return false
 armed=true;sword_on_ground=false
 return true
