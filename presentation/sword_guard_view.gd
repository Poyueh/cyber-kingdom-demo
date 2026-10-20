extends RefCounted
const SHEET: Texture2D=preload("res://art/characters/sword-guard-v001/guard.png")
static func draw_on(view: Node2D, sim: RefCounted, person: Dictionary) -> void:
 var rules: Resource=sim.world.defense_rules
 var frame: int=8+int(sim.workforce.elapsed*2)%2
 if person.get("moving",false):frame=int(person.get("walk_distance",0.0)/9.0)%8
 if person.cooldown>0:
  var elapsed: float=rules.sword_cycle-person.cooldown
  var windup: float=rules.sword_cycle-rules.strike_remaining
  frame=10 if elapsed<windup else 11 if elapsed<windup+0.13 else 12 if elapsed<windup+0.3 else 13
 elif preload("res://application/sword_guard.gd").bracing(sim,person):frame=14
 if person.hurt>0:frame=15
 view.draw_set_transform(Vector2(roundf(person.x),roundf(person.get("y",430.0))),0,Vector2(person.get("direction",1),1))
 view.draw_texture_rect_region(SHEET,Rect2(-32,-62,64,64),Rect2(frame%8*64,frame/8*64,64,64))
 if person.hurt>0:
  var reach: float=1.0-person.hurt/rules.shield_reaction
  for i: int in range(3):
   var at: Vector2=Vector2(18+reach*13,-34+i*5-reach*8).round()
   view.draw_rect(Rect2(at,Vector2(3,2)),Color("f3dca0"))
 view.draw_set_transform(Vector2.ZERO)
