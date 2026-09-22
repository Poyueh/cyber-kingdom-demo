extends RefCounted
## The permanent hoe sign is distinct from the three real, claimable tools.
static func draw_on(view: Node2D, at: Vector2, stock: int, selected: bool, flash: float) -> void:
	if not view._on_screen(at.x, 150): return
	view._prop("workshop", at)
	var light: float = 1.65 if selected else 1.0
	view.draw_set_transform(at.round())
	# Cover the smith's crossed-hammer banner with an agricultural maker's sign.
	view.draw_rect(Rect2(-16,-89,32,34), Color("9b8256") * light)
	view.draw_rect(Rect2(-13,-86,26,29), Color("244b46") * light)
	view.draw_rect(Rect2(-11,-84,22,2), Color("85c4a1") * light)
	view.draw_rect(Rect2(-13,-58,26,3), Color("9b8256") * light)
	view._tool(Vector2(0,-72), "hoe")
	# A grounded display rack: empty hooks stay empty until the player pays.
	for x: int in [21,67]:
		view.draw_rect(Rect2(x,-34,4,34), Color("473b30") * light)
		view.draw_rect(Rect2(x-2,-3,8,3), Color("2c383b") * light)
	view.draw_rect(Rect2(19,-32,54,5), Color("9b8256") * light)
	view.draw_rect(Rect2(19,-8,54,4), Color("5a5543") * light)
	for i: int in range(3):
		view.draw_rect(Rect2(28+i*16,-28,2,3), Color("c1ba91") * light)
		if i < stock: view._tool(Vector2(27+i*16,-19), "hoe")
	if flash > 0:
		view.draw_rect(Rect2(-13,-86,26,29), Color(0.45,1.0,0.8,flash*0.4))
	view.draw_set_transform(Vector2.ZERO)
