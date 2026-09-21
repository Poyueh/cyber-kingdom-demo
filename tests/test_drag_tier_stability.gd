extends RefCounted
const Drag=preload("res://presentation/drag_state.gd")
func test_second_tier_does_not_chatter_at_boundary(t) -> void:
 var drag=Drag.new();drag.begin(0,Vector2(200,300))
 drag.drag(0,Vector2(285,300));t.equal(drag.axis,1.0,"long drag engages fast tier")
 drag.drag(0,Vector2(282,300));t.equal(drag.axis,1.0,"small finger jitter keeps fast tier")
 drag.drag(0,Vector2(270,300));t.equal(drag.axis,0.65,"deliberate retreat returns to first tier")
 drag.finish(0);drag.begin(1,Vector2(400,300));drag.drag(1,Vector2(320,300))
 t.equal(drag.axis,-0.65,"new left gesture does not inherit fast tier")
 drag.drag(1,Vector2(315,300));drag.drag(1,Vector2(318,300))
 t.equal(drag.axis,-1.0,"left fast tier also resists small jitter")
 drag.cancel();t.equal(drag.axis,0.0,"cancel clears tier")
