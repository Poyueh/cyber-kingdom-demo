extends Node2D
signal offering_started
signal offering_ended
signal special_requested
var state=preload("res://presentation/drag_state.gd").new()
var enabled:=false
var fast_available: bool=true
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
 for finger: Dictionary in state.fingers.values():
  if finger.movement and state.axis!=0:
   var direction: float=signf(state.axis)
   var at: Vector2=finger.point+Vector2(direction*26,-40)
   at.x=clampf(at.x,safe.position.x+45,safe.end.x-45)
   at.y=clampf(at.y,safe.position.y+24,safe.end.y-24)
   var fast: bool=absf(state.axis)>=0.9 and fast_available
   # Two discrete chevrons, kept above the thumb. No joystick base.
   _arrow(at-Vector2(direction*12,0),direction,Color(0.65,0.96,0.85,0.9))
   _arrow(at+Vector2(direction*12,0),direction,Color(1.0,0.79,0.39,0.95) if fast else Color(0.55,0.7,0.69,0.25))
  elif finger.offered:
   var at: Vector2=finger.point
   draw_polyline(PackedVector2Array([at+Vector2(-6,17),at+Vector2(0,23),at+Vector2(6,17)]),Color(0.65,0.94,0.82,0.65),2)
func _arrow(at: Vector2, direction: float, color: Color) -> void:
 var points: PackedVector2Array=PackedVector2Array([at+Vector2(-direction*6,-9),at+Vector2(direction*3,0),at+Vector2(-direction*6,9)])
 draw_polyline(points,Color(0.02,0.06,0.08,color.a*0.8),6)
 draw_polyline(points,color,3)
