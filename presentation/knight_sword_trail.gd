extends Node2D
## One crisp, pixel-snapped blade ribbon. Never duplicates the knight's body.
const Fighter = preload("res://domain/combatant.gd")
const Style = preload("res://data/sword_feedback_tuning.gd")
const SEGMENTS: int = 20
var style: Style
var _phase: float = 0.0
var _step: int = 1
var _facing: int = 1
var _mounted: bool = false

func present(hero: Fighter, armed: bool, mounted: bool) -> void:
	visible = armed and hero.is_alive() and hero.is_attack_active()
	if not visible: return
	_phase = clampf((hero.attack_progress() - hero.attack_active_start()) / (hero.attack_active_end() - hero.attack_active_start()),0,1)
	_step = hero.combo_step
	_facing = hero.attack_facing
	_mounted = mounted
	queue_redraw()

func _point(angle: float, radius: float, flatten: float) -> Vector2:
	var grip: Vector2 = Vector2(8,-30 if _step != 1 else -24) if not _mounted else Vector2(12,-40)
	return Vector2((grip.x + cos(angle)*radius)*_facing,grip.y + sin(angle)*radius*flatten).round()

func _ribbon(head: float, tail: float, radius: float, width: float, flatten: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(SEGMENTS+1):
		points.append(_point(lerpf(tail,head,float(index)/SEGMENTS),radius,flatten))
	for index: int in range(SEGMENTS,-1,-1):
		var along: float = float(index)/SEGMENTS
		points.append(_point(lerpf(tail,head,along),radius - 1 - sin(along*PI)*width,flatten))
	draw_colored_polygon(points,color)

func _draw() -> void:
	if not visible or style == null: return
	var screen: Vector2 = get_global_transform_with_canvas().origin
	if not get_viewport_rect().grow(150).has_point(screen): return
	var heavy: bool = _step == 3
	var rising: bool = _step == 2
	var sweep: float = ease(clampf(_phase / 0.6,0,1),0.5)
	var head: float = lerpf(-0.85,-1.40,sweep) if rising else lerpf(0.70 if heavy else 0.62,0.40 if heavy else 0.32,sweep)
	var length: float = lerpf(2.25 if heavy else 1.85,0.8,_phase)
	var tail: float = head + length if rising else head - length
	var radius: float = style.trail_radius + (8 if heavy else 0)
	var width: float = style.heavy_width if heavy else style.light_width
	var flatten: float = 0.82 if rising else (0.77 if heavy else 0.65)
	var fade: float = 1.0 - smoothstep(0.45,1.0,_phase)
	_ribbon(head,tail,radius+2,width+3,flatten,Color(style.edge_color,0.85*fade))
	_ribbon(head,tail,radius,width,flatten,Color(style.trail_color,0.92*fade))
	_ribbon(head,lerpf(tail,head,0.12),radius-1,maxf(2,width*0.27),flatten,Color(style.core_color,fade))
	# A thin warm outer edge distinguishes the final cleave without a screen flash.
	if heavy:
		_ribbon(head,lerpf(tail,head,0.40),radius+2,2,flatten,Color(style.heavy_color,0.9*fade))
	for index: int in range(3):
		var angle: float = lerpf(tail,head,(index+1.0)/4.0)
		var at: Vector2 = _point(angle,radius+5+_phase*7,flatten)
		draw_rect(Rect2(at,Vector2(2,1)),Color(style.core_color,fade*0.7))
