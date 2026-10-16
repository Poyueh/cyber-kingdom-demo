extends Node2D
## A small inset on the authored pauldron, never a second object beside the helmet.
const Style=preload("res://presentation/module_style.gd")
var module_id: String=""
var _pulse: float=0.0

func socket_for(knight: AnimatedSprite2D) -> Vector2:
	if knight.appearance==null:return Vector2(0,-12)
	var body: Node2D=knight
	for candidate: Sprite2D in [knight._unarmed,knight._mount,knight._combo_attack,knight._moving_attack,knight.fatigue,knight._ceremony,knight.locomotion_transition]:
		if candidate.visible and candidate.modulate.a>0.5:body=candidate
	var drawing: Texture2D=body.sprite_frames.get_frame_texture(body.animation,body.frame) if body is AnimatedSprite2D else body.texture
	if not drawing is AtlasTexture:return Vector2(0,-12)
	var name: String=drawing.atlas.resource_path.get_file()
	var points: Array=knight.appearance.module_sockets.get(name,[])
	var columns: int=roundi(drawing.atlas.get_width()/drawing.region.size.x)
	var index: int=roundi(drawing.region.position.y/drawing.region.size.y)*columns+roundi(drawing.region.position.x/drawing.region.size.x)
	if index>=points.size():return Vector2(0,-12)
	var point: Vector2=points[index]-drawing.region.size*0.5
	point.x*=(-1 if body.flip_h else 1)
	return (point+body.offset+(Vector2.ZERO if body==knight else body.position)).round()

func present(knight: AnimatedSprite2D, id: String, seconds: float) -> void:
	module_id=id
	visible=not id.is_empty() and knight.appearance!=null and knight.visible
	if not visible:return
	_pulse+=maxf(0,seconds)
	position=socket_for(knight)
	scale=Vector2(-1 if knight.flip_h else 1,1)
	queue_redraw()

func _draw() -> void:
	if not get_viewport_rect().grow(12).has_point(get_global_transform_with_canvas().origin):return
	# A three-pixel engraving follows the brass pauldron edge, without a box or backing plate.
	var energy: Color=Style.tint(module_id).lerp(Color("ad8c51"),0.6)
	energy=energy.darkened(0.24+0.05*sin(_pulse*2))
	draw_rect(Rect2(-1,0,3,1),Color("85764e"))
	draw_rect(Rect2(0,-1,1,1),Color("bea46b"))
	draw_rect(Rect2(0,0,1,1),energy)
