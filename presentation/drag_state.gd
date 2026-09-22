extends RefCounted
## Intent is chosen by the drag direction, not which half of the screen was touched.
var fingers: Dictionary={}
var axis:=0.0
var move_finger:=-1
var offer_finger:=-1
var _special_pending: bool=false
var _special_latched: bool=false
func begin(id: int, at: Vector2) -> void:
 if fingers.has(id):return
 fingers[id]={"origin":at,"point":at,"movement":false,"offered":false}
func drag(id: int, at: Vector2) -> bool:
 if not fingers.has(id):return false
 var finger: Dictionary=fingers[id];finger.point=at
 if _special_latched or finger.offered:return false
 var delta: Vector2=at-finger.origin
 if fingers.size()==2:
  var upward: bool=true
  for item in fingers.values():
   var offset: Vector2=item.point-item.origin
   if item.offered or offset.y> -42 or -offset.y<absf(offset.x)*1.25:upward=false
  if upward:
   _special_pending=true;_special_latched=true;axis=0.0;move_finger=-1
   for item in fingers.values():item.movement=false
   return false
 if delta.y>=28 and delta.y>absf(delta.x)*1.25 and offer_finger<0:
  if move_finger==id:move_finger=-1;axis=0
  finger.movement=false;finger.offered=true;offer_finger=id
  return true
 if move_finger==id:
  axis=0.0 if absf(delta.x)<14 else _tier(delta.x)
 elif move_finger<0 and absf(delta.x)>=14 and absf(delta.x)>absf(delta.y)*1.25:
  move_finger=id;finger.movement=true;axis=_tier(delta.x)
 return false
func _tier(distance: float) -> float:
 # Separate enter/leave thresholds keep tiny finger jitter from flipping speed every frame.
 var threshold: float=72.0 if absf(axis)>=0.9 else 84.0
 return signf(distance)*(1.0 if absf(distance)>=threshold else 0.65)
func finish(id: int) -> void:
 fingers.erase(id)
 if fingers.is_empty():_special_latched=false
 if move_finger==id:move_finger=-1;axis=0
 if offer_finger==id:offer_finger=-1
func cancel() -> void:
 fingers.clear();axis=0;move_finger=-1;offer_finger=-1
 _special_pending=false;_special_latched=false
func consume_special() -> bool:
 var value: bool=_special_pending;_special_pending=false
 return value
