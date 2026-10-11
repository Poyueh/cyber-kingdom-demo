extends RefCounted
## Short, deterministic pixel debris. No timers, allocation history or gameplay RNG.
static func burst(view: Node2D, at: Vector2, progress: float, direction: float, heavy: bool, tint: Color, weight: float=1.0) -> void:
	var fade: float=1-clampf(progress,0,1)
	if fade<0.01:return
	var force: float=(1.35 if heavy else 1.0)*weight
	var center: Vector2=at.round()
	if progress<0.17:
		var radius: float=(12 if heavy else 8)*(1-progress/0.22)
		var star: PackedVector2Array=PackedVector2Array()
		for point: int in range(12):
			var angle: float=point*TAU/12+0.18
			star.append((center+Vector2.from_angle(angle)*radius*(1 if point%2==0 else 0.35)).round())
		view.draw_colored_polygon(star,Color("f1ffe7"))
	for index: int in range(10 if heavy else 7):
		var angle: float=-1.5+index*0.39
		var ray: Vector2=Vector2(cos(angle)*direction,sin(angle))
		var travel: float=(14+index%3*9)*sqrt(progress)*force
		var point: Vector2=(center+ray*travel+Vector2(0,progress*progress*22)).round()
		var size: float=maxf(1.0,(3 if index%3==0 else 2)*fade)
		var shard: PackedVector2Array=PackedVector2Array([point+Vector2(-size,0),point+Vector2(0,-size*1.8),point+Vector2(size,0),point+Vector2(0,size)])
		view.draw_colored_polygon(shard,Color(tint.lightened(0.35) if index%2==0 else Color("718491"),fade))
		view.draw_line(point,(point-ray*5*fade).round(),Color(tint,fade*0.6),1)
	if heavy:
		var points: PackedVector2Array=PackedVector2Array()
		for index: int in range(9):
			var angle: float=-PI*0.6+index*PI*1.2/8
			points.append((center+Vector2(cos(angle)*direction,sin(angle))*(9+progress*35)*force).round())
		view.draw_polyline(points,Color(tint,fade*0.65),2)

static func claw_warning(view: Node2D, at: Vector2, direction: float, progress: float, tint: Color) -> void:
	# Three natural claw tips brighten; never a floating sword/weapon marker.
	for index: int in range(3):
		var p: Vector2=(at+Vector2(direction*index*4,index*5)).round()
		view.draw_line(p,p+Vector2(-direction*(4+progress*6),-3),Color(tint.lightened(0.6),0.3+progress*0.7),2)

static func claw_release(view: Node2D, at: Vector2, direction: float, progress: float, tint: Color) -> void:
	for index: int in range(3):
		var start: Vector2=at+Vector2(direction*(-8+index*5),-15+index*3)
		var end: Vector2=start+Vector2(direction*(14+progress*14),20)
		view.draw_line(start.round(),end.round(),Color(tint.lightened(0.5),1-progress),2)

static func dissolve(view: Node2D, at: Vector2, progress: float, tint: Color, boss: bool) -> void:
	var count: int=16 if boss else 8
	var spread: float=90 if boss else 30
	var fade: float=1-smoothstep(0.4,1,progress)
	for index: int in range(count):
		var p: Vector2=at+Vector2(sin(index*2.4)*spread*progress,-8-sin(progress*PI)*(14+index%4*12))
		view.draw_rect(Rect2(p.round(),Vector2(3,2)),Color(tint,fade*0.8))
	if progress<0.5:
		var wide: float=(100 if boss else 22)*sin(progress*PI)
		view.draw_set_transform(at+Vector2(0,-2),0,Vector2(1,0.16))
		view.draw_arc(Vector2.ZERO,wide,0,TAU,24,Color(Color("88988c"),fade*0.45),3)
		view.draw_set_transform(Vector2.ZERO)
