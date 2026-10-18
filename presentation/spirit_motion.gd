extends RefCounted
## A companion moves and looks independently. Advice is still the actual world target.
var style: SpiritCompanionStyle=preload("res://data/spirit_companion.tres")
var _position: Vector2=Vector2.ZERO
var _last_time: float=-1.0
var _last_world_x: float=0.0
var _idle_time: float=0.0
var _speed: float=0.0
var _direction: float=1.0
var _look: float=1.0
var _lean: float=0.0
var _arrived_at: float=-1.0
var _identity: String=""
var _started_at: float=0.0

func sample(hint: Dictionary, hero: Vector2, world_x: float, safe: Rect2, time: float, obstacles: Array[Rect2]=[]) -> Dictionary:
 if hint.is_empty():
  _last_time=-1
  return {"visible":false}
 # Two nearby wanderers may swap nearest-target identity; that must not restart the greeting.
 var identity: String=str(hint.get("lesson",hint.get("kind","")))+":"+str(hint.get("kind",""))+":"+str(hint.get("action",""))+":"+str(hint.get("goal",""))
 var reset: bool=_last_time<0 or time<_last_time
 var changed: bool=identity!=_identity or reset
 var dt: float=clampf(time-_last_time,0,0.1) if not reset else 0.0
 if changed:
  _identity=identity;_started_at=time;_arrived_at=-1;_idle_time=0
 if reset:_last_world_x=world_x;_speed=0
 var travelled: float=world_x-_last_world_x
 if dt>0:
  _speed=lerpf(_speed,clampf(travelled/dt,-500,500),1-exp(-8*dt))
  _idle_time=_idle_time+dt if absf(travelled)<0.2 else 0.0
 var distance: float=float(hint.x)-world_x
 if absf(distance)>24:_direction=signf(distance)
 var near: bool=absf(distance)<=style.arrive_distance
 if near and _arrived_at<0:_arrived_at=time
 var mood: String=hint.get("mood","lead")
 var state: String=_state(mood,near,time)
 var offset: float=clampf(distance,-style.lead_distance,style.lead_distance)
 if absf(distance)<200:offset=distance-_direction*style.companion_distance
 if state=="wait":offset=_direction*(style.lead_distance-22)
 if mood=="rest":offset=-style.companion_distance
 if mood=="guard":offset=clampf(distance,-82,82)
 var goal: Vector2=hero+Vector2(offset,-style.follow_height)
 # Keep the entire pixel silhouette out of controls, captions and the knight's face.
 var blocked: Array[Rect2]=obstacles.duplicate()
 blocked.append(Rect2(hero+Vector2(-34,-82),Vector2(68,96)))
 goal=_clear_position(goal,safe,blocked)
 if reset:_position=goal
 elif dt>0:
  _position=_position.lerp(goal,1-exp(-style.follow_response*dt))
  if _position.distance_to(hero)>190:_position=goal
 var looking_back: bool=state in ["wait","greet","rest"] or (not near and fposmod(time-_started_at,style.look_back_interval)>style.look_back_interval-style.look_back_seconds)
 var gaze: float=signf(hero.x-_position.x) if looking_back else _direction
 if gaze==0:gaze=_direction
 if reset:_look=gaze;_lean=0
 elif dt>0:
  _look=lerpf(_look,gaze,1-exp(-style.turn_response*dt))
  _lean=lerpf(_lean,clampf(_speed/180,-1,1)*3,1-exp(-style.follow_response*dt))
 var bob: Vector2=Vector2(0,sin(time*2.6)*3+sin(time*1.3)*1.5)
 var rendered: Vector2=_clear_position(_position+bob,safe,blocked).round()
 _last_world_x=world_x;_last_time=time
 return {"visible":true,"position":rendered,"direction":_direction,"near":near,"phase":time,
  "mood":mood,"state":state,"look":_look,"lean":_lean,"speed":_speed,"idle":_idle_time,
  "age":time-_started_at,"near_age":time-_arrived_at if _arrived_at>=0 else -1.0,"looking_back":looking_back}

func _state(mood: String, near: bool, time: float) -> String:
 if mood=="rest":return "rest"
 if mood=="guard":return "guard"
 if near and mood=="work":return "observe"
 if near and mood=="receive":return "receive"
 if near:return "point"
 if time-_started_at<1.1 and absf(_speed)<30:return "greet"
 if _idle_time>=style.wait_seconds:return "wait"
 if _speed*_direction< -30:return "return"
 return "lead"

func _clear_position(wanted: Vector2, safe: Rect2, blocked: Array[Rect2]) -> Vector2:
 var limit: Rect2=safe.grow(-12)
 var center: Vector2=Vector2(clampf(wanted.x,limit.position.x+42,limit.end.x-42),clampf(wanted.y,limit.position.y+48,limit.end.y-42))
 var candidates: Array[Vector2]=[center]
 for offset: Vector2 in [Vector2(0,-64),Vector2(-80,0),Vector2(80,0),Vector2(-80,-64),Vector2(80,-64),Vector2(0,64)]:
  candidates.append(Vector2(clampf(center.x+offset.x,limit.position.x+42,limit.end.x-42),clampf(center.y+offset.y,limit.position.y+48,limit.end.y-42)))
 for candidate: Vector2 in candidates:
  var bounds: Rect2=Rect2(candidate-Vector2(40,46),Vector2(80,86))
  var clear: bool=true
  for region: Rect2 in blocked:
   if region.has_area() and bounds.intersects(region.grow(8)):clear=false;break
  if clear:return candidate
 # Dense/modal layout: the view suppresses the decoration instead of covering input.
 return center
