extends Node2D
## One screen copy; no extra world viewport, readbacks or per-actor reflection nodes.
var style: Resource
var _surface: Polygon2D
var _shader: ShaderMaterial
func _ready() -> void:
 z_index=80
 _surface=Polygon2D.new()
 _shader=ShaderMaterial.new();_shader.shader=preload("res://presentation/water_reflection.gdshader")
 _surface.material=_shader
 add_child(_surface)
func present(sim: RefCounted) -> void:
 if _surface==null:return
 var canvas: Transform2D=get_viewport().get_canvas_transform()
 var size: Vector2=get_viewport_rect().size
 var inverse: Transform2D=canvas.affine_inverse()
 var left: Vector2=inverse*Vector2.ZERO
 var right: Vector2=inverse*size
 var y: float=style.water_line
 visible=right.y>y
 if not visible:return
 _surface.polygon=PackedVector2Array([Vector2(left.x-4,y),Vector2(right.x+4,y),right+Vector2(4,4),Vector2(left.x-4,right.y+4)])
 _shader.set_shader_parameter("bank_uv",(canvas*Vector2(0,y)).y/size.y)
 _shader.set_shader_parameter("ground_uv",(canvas*Vector2(0,430)).y/size.y)
 _shader.set_shader_parameter("elapsed",sim.workforce.elapsed)
 _shader.set_shader_parameter("strength",style.reflection_strength)
 _shader.set_shader_parameter("water_color",Color("0c192b") if sim.clock.is_night else Color("163b4d"))
