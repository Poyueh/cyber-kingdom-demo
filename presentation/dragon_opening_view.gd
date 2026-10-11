extends RefCounted
## A world-space core and split halo; no extra HUD, nodes, or persistent particles.
const Fonts=preload("res://presentation/localized_font.gd")
const GOLD: Color=Color("ffe3a0")
const CYAN: Color=Color("9ffff1")
# Local core positions in the existing right-facing poses; mirrored with the body.
const CORES: Array[Vector2]=[Vector2(102,358),Vector2(40,398),Vector2(30,362),Vector2(36,365),Vector2(-22,377),Vector2(50,358),Vector2(36,373)]
static func draw(view: Node2D, enemy: Dictionary, time: float) -> void:
	if view.cinematic:return
	if not view._sim.planet.attack.opening.exposed(enemy) or not view._on_screen(enemy.x,350):return
	var pulse: float=0.65+sin(time*5.0)*0.2
	var core: Vector2=CORES[view._sim.planet.id]
	var at: Vector2=Vector2(roundf(enemy.x+core.x*enemy.direction),core.y)
	var points: PackedVector2Array=PackedVector2Array([at+Vector2(0,-11),at+Vector2(8,0),at+Vector2(0,11),at+Vector2(-8,0)])
	view.draw_circle(at,25,Color(CYAN,0.13*pulse))
	view.draw_colored_polygon(points,Color(GOLD,pulse))
	view.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color.WHITE,2)
	for side: int in [-1,1]:
		var x: float=at.x+side*(23+roundf(sin(time*3)))
		view.draw_polyline(PackedVector2Array([Vector2(x-side*5,at.y-13),Vector2(x,at.y-13),Vector2(x,at.y+13),Vector2(x-side*5,at.y+13)]),Color(CYAN,pulse),2)
	for i: int in range(6):
		var phase: float=fposmod(time*0.45+i/6.0,1.0)
		var spark: Vector2=at+Vector2(sin(i*2.4)*38,12-phase*65)
		view.draw_rect(Rect2(spark.round(),Vector2(2,3)),Color(GOLD,(1-phase)*0.65))
	# The opening lasts through recovery, but the sentence is only shown at its start.
	if not view._sim.effects.any(func(e: Dictionary)->bool:return e.kind=="dragon_opening"):return
	var font: Font=Fonts.current();var text: String=view.tr("dragon.opening")
	var size: int=13;var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	var origin: Vector2=Vector2(roundf(enemy.x),176)
	view.draw_rect(Rect2(origin-Vector2(width/2+7,16),Vector2(width+14,24)),Color(0.025,0.07,0.09,0.9))
	view.draw_string(font,origin-Vector2(width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,GOLD)
