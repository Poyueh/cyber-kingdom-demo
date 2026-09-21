extends RefCounted
const Drag=preload("res://presentation/drag_state.gd")
func test_two_upward_fingers_trigger_once_and_never_offer(t) -> void:
 var s=Drag.new()
 if not s.has_method("consume_special"):
  t.truth(false,"touch state recognizes a special gesture");return
 s.begin(0,Vector2(200,350));s.begin(1,Vector2(400,350))
 t.truth(not s.drag(0,Vector2(202,290)),"first upward finger never pays")
 t.truth(not s.consume_special(),"one finger is insufficient")
 t.truth(not s.drag(1,Vector2(402,290)),"second upward finger never pays")
 t.truth(s.consume_special(),"two upward fingers activate once")
 s.drag(0,Vector2(202,260));s.drag(1,Vector2(402,260))
 t.truth(not s.consume_special(),"continued drag cannot retrigger")
 t.equal(s.axis,0.0,"special gesture stops movement")
 s.cancel();s.begin(0,Vector2(200,350));s.drag(0,Vector2(200,400))
 t.truth(s.offer_finger==0 and not s.consume_special(),"normal downward offering remains independent")

func test_release_and_focus_loss_cancel_partial_special(t) -> void:
 var s=Drag.new()
 if not s.has_method("consume_special"):t.truth(false,"special gesture can be reset");return
 s.begin(0,Vector2(200,350));s.drag(0,Vector2(200,280));s.finish(0)
 s.begin(1,Vector2(400,350));s.drag(1,Vector2(400,280))
 t.truth(not s.consume_special(),"non-overlapping swipes never combine")
 s.cancel();s.begin(0,Vector2(200,350));s.begin(1,Vector2(400,350))
 s.drag(0,Vector2(200,280));s.drag(1,Vector2(400,280));s.cancel()
 t.truth(not s.consume_special(),"focus loss clears pending activation")
