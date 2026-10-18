extends RefCounted
## The ghost says what to do: each new task is spoken at once, far targets name the task,
## and a stalled player is reminded soon. Times are game seconds at 30 frames per second.
const FRAME: float=1.0/30.0
const SAFE: Rect2=Rect2(0,0,960,540)
const HERO: Vector2=Vector2(480,420)

func task(kind: String, x: float) -> Dictionary:
 return {"kind":kind,"x":x,"y":430.0,"key":"","action":"invest","stage":0,"core":true,"mood":"lead","lesson":"core."+kind,"goal":"spirit.core."+kind}

func guide() -> Node2D:
 var view: Node2D=load("res://presentation/campaign_guide_view.gd").new()
 view._ready()
 return view

## Runs frames from start until end, moving step px each frame; returns when the caption first showed.
func spoken_at(view: Node2D, hint: Dictionary, start: float, end: float, x: float, step: float) -> float:
 var time: float=start
 while time<end:
  view.present(hint,SAFE,x,Rect2(),false)
  view.track(HERO,time)
  if view._guide_label.visible:return time-start
  time+=FRAME;x+=step
 return -1.0

func test_new_task_is_spoken_at_once_while_walking(t):
 var view: Node2D=guide()
 var hint: Dictionary=task("recruit",2000.0)
 var heard: float=spoken_at(view,hint,0.0,3.0,100.0,4.0)
 t.truth(heard>=0 and heard<=0.5,"a new task is spoken within half a second even while walking (heard at %s)"%heard)
 var named: String=view.tr("spirit.core.recruit")
 t.truth(view._guide_label.text.contains(named) and view._guide_label.text!=named,"far from the target the ghost leads and names the task")
 var next: Dictionary=task("hammer",2400.0)
 heard=spoken_at(view,next,3.0,6.0,400.0,4.0)
 t.truth(heard>=0 and heard<=0.5,"the next task replaces the old one within half a second (heard at %s)"%heard)
 t.truth(view._guide_label.text.contains(view.tr("spirit.core.hammer")),"the caption updates to the new task")
 view.free()

func test_arrival_and_stalls_are_answered_quickly(t):
 var view: Node2D=guide()
 var hint: Dictionary=task("recruit",900.0)
 spoken_at(view,hint,0.0,0.1,100.0,0.0)
 # Let the first announcement end, then arrive at the target.
 var time: float=0.0
 while time<8.0:
  view.present(hint,SAFE,100.0,Rect2(),false);view.track(HERO,time);time+=FRAME
 var heard: float=spoken_at(view,hint,time,time+3.0,900.0,0.0)
 t.truth(heard>=0 and heard<=0.5,"arriving at the target is answered within half a second (heard at %s)"%heard)
 t.equal(view._guide_label.text,view.tr("spirit.core.recruit"),"at the target the ghost says the plain instruction")
 # A player who stands still away from the target is reminded within eight seconds.
 var quiet: float=time+0.5
 while quiet<time+12.0:
  view.present(hint,SAFE,300.0,Rect2(),false);view.track(HERO,quiet)
  if not view._guide_label.visible:break
  quiet+=FRAME
 heard=spoken_at(view,hint,quiet,quiet+10.0,300.0,0.0)
 t.truth(heard>=0 and heard<=8.0,"a stalled player hears the task again within eight seconds (heard at %s)"%heard)
 view.free()
