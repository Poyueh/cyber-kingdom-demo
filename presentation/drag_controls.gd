extends Node2D
signal offering_started
signal offering_ended
signal special_requested
var state=preload("res://presentation/drag_state.gd").new()
var enabled:=false
var safe:=Rect2()
var exclusions: Array[Rect2]=[]
func cancel() -> void:
 state.cancel();offering_ended.emit();queue_redraw()
func _unhandled_input(event: InputEvent) -> void:
 if not enabled:return
 if event is InputEventScreenTouch:
  if event.pressed:
   if not safe.has_point(event.position) or exclusions.any(func(r):return r.has_point(event.position)):return
   # Reserve the upper HUD; world gestures begin below it.
   if event.position.y<safe.position.y+110:return
   state.begin(event.index,event.position)
  else:
   if event.index==state.offer_finger:offering_ended.emit()
   state.finish(event.index)
 elif event is InputEventScreenDrag:
  if state.drag(event.index,event.position):offering_started.emit()
  if state.consume_special():
   offering_ended.emit();special_requested.emit()
 queue_redraw()
func _draw() -> void:
 if not enabled:return
 # Tiny translucent chevron at the fingertip; no joystick base or thumb disc.
 for finger in state.fingers.values():
  var at: Vector2=finger.point
  var color:=Color(0.65,0.94,0.82,0.22)
  if finger.movement and state.axis!=0:
   var direction:=signf(state.axis)
   draw_line(at+Vector2(direction*10,-4),at+Vector2(direction*14,0),color,1)
   draw_line(at+Vector2(direction*14,0),at+Vector2(direction*10,4),color,1)
  elif finger.offered:
   draw_line(at+Vector2(-4,10),at+Vector2(0,14),color,1)
   draw_line(at+Vector2(0,14),at+Vector2(4,10),color,1)
