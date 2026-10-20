extends Node2D
## Two wheel hubs and a bounded drive glow. The authored chassis never bounces.
const WHEEL_RADIUS: float=16.0
const HUBS: Array[Vector2]=[Vector2(-51,15),Vector2(51,15)]
var _phase: float=0.0
var _power: float=0.0
var _facing: int=1

func reset() -> void:
	_phase=0.0
	_power=0.0
	visible=false

func present(pose: Dictionary, seconds: float) -> void:
	_facing=int(pose.facing)
	var velocity: float=float(pose.get("horizontal_speed",0.0))
	var speed: float=absf(velocity)
	if not pose.get("moving",false) and not pose.get("attack_advancing",false):
		speed=0.0
		velocity=0.0
	if seconds>0:
		_phase=fposmod(_phase+velocity*seconds/WHEEL_RADIUS,TAU)
		_power=move_toward(_power,clampf(speed/402.0,0,1),seconds*4.0)
	visible=bool(pose.alive)
	queue_redraw()

func _draw() -> void:
	if not visible or not get_viewport_rect().grow(100).has_point(get_global_transform_with_canvas().origin):return
	for hub: Vector2 in HUBS:
		var center: Vector2=Vector2(hub.x*_facing,hub.y)
		# Fixed outer tyre carries weight; only the inset hub/spokes rotate.
		for y: int in range(-9,10):
			var span: int=floori(sqrt(maxf(0,81-y*y)))
			draw_rect(Rect2(center+Vector2(-span,y),Vector2(span*2+1,1)),Color("192027"))
		for spoke: int in range(5):
			var ray: Vector2=Vector2.from_angle(_phase+spoke*TAU/5)*8
			draw_line(center,center+ray.round(),Color("b79858"),2,false)
		draw_rect(Rect2(center-Vector2(2,2),Vector2(5,5)),Color("574733"))
		draw_rect(Rect2(center-Vector2.ONE,Vector2(2,2)),Color("d6c28b"))
	if _power>0.05:
		var core: Vector2=Vector2(12*_facing,6)
		draw_rect(Rect2(core,Vector2(2,4)),Color(0.25,0.95,1.0,_power*0.75))
		# Small electric exhaust, no particle allocation or lingering trail.
		draw_rect(Rect2(Vector2(-60*_facing,18),Vector2(3+roundi(_power*4),2)),Color(0.2,0.8,0.9,_power*0.5))
