extends RefCounted
## Tiny pixel accents attached to an actual work stroke, never pickups or UI badges.
const State=preload("res://presentation/attendant_state.gd")
static func draw_on(view: Node2D, state: State, profile: AttendantProfile) -> void:
 if state.mode in [State.Mode.ALERT,State.Mode.GREET,State.Mode.ACKNOWLEDGE]:return
 if state.frame!=2:return
 var t: float=minf(1.0,state.frame_age/0.45)
 var at: Vector2=profile.hand
 var ink: Color=profile.accent
 ink.a*=1.0-t
 match profile.detail:
  &"lantern":
   view.draw_rect(Rect2((at+Vector2(-2,-2)).round(),Vector2(4,4)),Color(ink,ink.a*0.5))
  &"sparks":
   for i: int in range(3):
    var point: Vector2=at+Vector2(3+i*3,-5+i*3)*t
    view.draw_rect(Rect2(point.round(),Vector2(2,1)),ink)
  &"seeds":
   for i: int in range(3):
    var point: Vector2=at+Vector2(-i*2,2+i*2+7*t)
    view.draw_rect(Rect2(point.round(),Vector2.ONE),ink)
  &"feather":
   view.draw_line((at+Vector2(-2,3*t)).round(),(at+Vector2(2,3*t-4)).round(),ink,1)
  &"crystal":
   view.draw_rect(Rect2((at+Vector2(-3,0)).round(),Vector2(7,1)),ink)
   view.draw_rect(Rect2((at+Vector2(0,-3)).round(),Vector2(1,7)),ink)
  &"metal":
   view.draw_line((at+Vector2(-2,-2)).round(),(at+Vector2(2,2)).round(),ink,1)
