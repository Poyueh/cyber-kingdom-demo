extends Node2D
## Small armour-mounted hardware. The atlas supplies a shoulder socket per pose.
const Style=preload("res://presentation/module_style.gd")
var module_id: String=""
var _pulse: float=0.0
func present(knight: AnimatedSprite2D, id: String, seconds: float) -> void:
	module_id=id
	visible=not id.is_empty() and knight.appearance!=null
	if not visible:return
	_pulse+=maxf(0,seconds)
	var body: Node2D=knight
	for candidate: Sprite2D in [knight._unarmed,knight._mount,knight._combo_attack,knight._moving_attack,knight.fatigue,knight._ceremony]:
		if candidate.visible and candidate.modulate.a>0.5:body=candidate
	var drawing: Texture2D=body.sprite_frames.get_frame_texture(body.animation,body.frame) if body is AnimatedSprite2D else body.texture
	if not drawing is AtlasTexture:visible=false;return
	var name: String=drawing.atlas.resource_path.get_file()
	var points: Array=knight.appearance.module_sockets.get(name,[])
	var columns: int=roundi(drawing.atlas.get_width()/drawing.region.size.x)
	var index: int=roundi(drawing.region.position.y/drawing.region.size.y)*columns+roundi(drawing.region.position.x/drawing.region.size.x)
	if index>=points.size():visible=false;return
	var point: Vector2=points[index]-drawing.region.size*0.5
	point.x*=(-1 if body.flip_h else 1)
	position=(point+body.offset+(Vector2.ZERO if body==knight else body.position)).round()
	scale=Vector2(-1 if body.flip_h else 1,1)
	rotation=PI*0.5*scale.x if name.begins_with("death") and index==1 else 0.0
	queue_redraw()
func _draw() -> void:
	# A backplate, two rivets and inset machinery use the same native pixel grid as the armour.
	draw_polygon(PackedVector2Array([Vector2(-7,-7),Vector2(0,-7),Vector2(3,-3),Vector2(2,7),Vector2(-6,7),Vector2(-8,3)]),PackedColorArray([Color("111d29")]))
	draw_rect(Rect2(-6,-5,5,10),Color("465a67"))
	draw_rect(Rect2(-5,-4,3,8),Color("1c2c36"))
	var energy: Color=Style.tint(module_id)
	energy=energy.lerp(Color.WHITE,(sin(_pulse*2)+1)*0.12)
	match module_id:
		"arc":
			for y: int in [-3,0,3]:draw_rect(Rect2(-6,y,6,2),energy)
		"lance","frost":
			draw_rect(Rect2(-4,-10,4,15),Color("657784"))
			draw_rect(Rect2(-3,-9,2,12),energy)
			draw_rect(Rect2(-5,-11,6,2),Color("263641"))
			if module_id=="frost":draw_line(Vector2(-2,-11),Vector2(-2,-15),energy,1)
		"magnet":
			draw_polyline(PackedVector2Array([Vector2(-7,-4),Vector2(-7,3),Vector2(-2,5),Vector2(2,3),Vector2(2,-4)]),energy,2)
		"gravity":
			draw_arc(Vector2(-2,0),5,0,TAU,8,energy,2)
			draw_rect(Rect2(-3,-1,2,2),Color.WHITE)
		"workshop":
			draw_rect(Rect2(-6,-3,6,3),energy);draw_rect(Rect2(-4,0,2,7),Color("a8bec3"))
		"command":
			draw_polygon(PackedVector2Array([Vector2(-6,4),Vector2(-2,-6),Vector2(2,4),Vector2(-2,1)]),PackedColorArray([energy]))
		"capacitor":
			for x: int in [-6,-1]:
				draw_rect(Rect2(x,-5,3,11),Color("91a1b7"));draw_rect(Rect2(x,-3,3,6),energy)
	for y: int in [-5,5]:draw_rect(Rect2(0,y,2,1),Color("c1c8c7"))
