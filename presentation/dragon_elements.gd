extends RefCounted
## Each burst is constrained to the true damage footprint and existing effect TTL.
static func draw(view: Node2D, sim: RefCounted, effect: Dictionary) -> void:
	var progress: float=clampf(1-effect.life/0.85,0,1)
	var fade: float=1-smoothstep(0.35,1,progress)
	var strength: float=sin(clampf(progress/0.18,0,1)*PI*0.5)
	var radius: float=sim.planet.attack.radius
	var at: Vector2=Vector2(effect.x,428)
	var look: EnemyAppearance=view._raider_motion.appearance("dragon")
	var tint: Color=Color(look.tint,fade)
	match sim.planet.id:
		5:
			for branch: int in [-1,0,1]:
				var points: PackedVector2Array=PackedVector2Array()
				for index: int in range(9):
					points.append((at+Vector2(branch*radius*0.5+sin(index*2.4+branch)*14, -245+index*30)).round())
				view.draw_polyline(points,Color(tint,fade*0.18),11)
				view.draw_polyline(points,Color(tint,fade*0.9),4)
				view.draw_polyline(points,Color(1,1,0.9,fade),1)
		6:
			for index: int in range(3):
				var width: float=radius*(0.4+strength*0.6)
				view.draw_arc(at+Vector2(0,-12-index*12),width,PI+0.12,TAU-0.12,24,Color(tint,fade*(1-index*0.2)),4-index)
		3:
			for index: int in range(12):
				var p: Vector2=at+Vector2(cos(index*2.4)*radius*strength*0.85,-12-index%3*15-progress*42)
				view.draw_circle(p.round(),4+index%3*2,Color(tint,fade*0.4))
				view.draw_rect(Rect2(p.round(),Vector2(2,3)),Color(tint.lightened(0.5),fade))
		_:
			for index: int in range(11):
				var p: Vector2=at+Vector2(-radius+index*radius/5,0)
				var height: float=(28+(index*7)%31)*strength
				if height<1:continue
				var shard: PackedVector2Array=PackedVector2Array([p+Vector2(-6,0),p+Vector2(-3,-height*.7),p+Vector2(3,-height),p+Vector2(8,0)])
				view.draw_colored_polygon(shard,Color(tint.darkened(0.28),fade))
				view.draw_line((p+Vector2(3,-height)).round(),(p+Vector2(4,0)).round(),Color(tint.lightened(0.5),fade),2)
	view.draw_line(at-Vector2(radius,0),at+Vector2(radius,0),Color(tint.lightened(0.4),fade),3)
	for index: int in range(12):
		var p: Vector2=at+Vector2(sin(index*2.8)*radius*strength,-sin(progress*PI)*(16+index%4*13))
		view.draw_rect(Rect2(p.round(),Vector2(3,2)),Color(tint,fade))
